from pathlib import Path
import os
import re
from glob import glob

import numpy as np
import pandas as pd
from scipy.signal import medfilt
from ppigrf import igrf
import plotly.express as px


class DVFileReader:
    def __init__(self, folder_path):
        self.folder_path = folder_path

    def extract_metadata(self, lines):
        lat = lon = elev = None
        for line in lines:
            if "Geodetic Latitude" in line:
                lat = float(re.findall(r"[-+]?\d*\.\d+|\d+", line)[0])
            elif "Geodetic Longitude" in line:
                lon = float(re.findall(r"[-+]?\d*\.\d+|\d+", line)[0])
            elif "Elevation" in line:
                elev = float(re.findall(r"[-+]?\d*\.\d+|\d+", line)[0])
            elif line.startswith("DATE"):
                break
        return lat, lon, elev

    def read_single_min_file(self, filepath):
        with open(filepath, 'r') as f:
            lines = f.readlines()

        lat, lon, elev = self.extract_metadata(lines)

        for i, line in enumerate(lines):
            if line.startswith("DATE"):
                header_line = i
                break
        else:
            raise ValueError(f"'DATE' line not found in file: {filepath}")

        df = pd.read_csv(
            filepath,
            sep=r'\s+',
            skiprows=header_line + 1,
            names=lines[header_line].strip().split()
        )
        df["datetime"] = pd.to_datetime(df["DATE"] + " " + df["TIME"])
        df = df[["datetime", "KNYF"]]
        return df, lat, lon, elev

    def load_all(self):
        files = glob(os.path.join(self.folder_path, "*.min"))
        if not files:
            raise FileNotFoundError(f"No .min files found in '{self.folder_path}'")

        all_data = []
        meta_info = None

        for f in files:
            df, lat, lon, elev = self.read_single_min_file(f)
            all_data.append(df)
            if meta_info is None:
                meta_info = {"latitude": lat, "longitude": lon, "elevation": elev}

        df_all = pd.concat(all_data, ignore_index=True)
        df_all.sort_values("datetime", inplace=True)
        df_all["KNYF_filtered"] = medfilt(df_all["KNYF"], kernel_size=7)

        dt = df_all["datetime"].min()
        lat = meta_info["latitude"]
        lon = meta_info["longitude"]
        h_km = meta_info["elevation"] / 1000.0
        Be, Bn, Bu = igrf(lon, lat, h_km, dt)
        Btotal = np.sqrt(Be**2 + Bn**2 + Bu**2)

        df_all["dv"] = df_all["KNYF_filtered"] - Btotal
        return df_all, pd.DataFrame([meta_info])


class  DVCONVERT:
    def __init__(self, input_dir, output_dir=None, start_number=1):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir) if output_dir else self.input_dir
        self.start_number = start_number

    def convert(self):
        # === Load DV data ===
        reader = DVFileReader(folder_path=self.input_dir)
        try:
            df_all, _ = reader.load_all()
        except FileNotFoundError:
            print("!! No .min files found in input folder.")
            print("!! Please provide 'output.obsc' in input_dv_dir manually")
            print("!! if you need Step 6: Apply diurnal variation correction")
            return  # or: raise if you want to force stop
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # === Export individual .obsc files by date ===
        grouped = df_all.groupby(df_all["datetime"].dt.date)
        number = self.start_number
        for date, group in grouped:
            outfile = self.output_dir / f"{number:02d}.obsc"
            YY, MM, DD = date.year % 100, date.month, date.day
            with open(outfile, 'w') as f:
                for _, row in group.iterrows():
                    HH, MI, DV = row["datetime"].hour, row["datetime"].minute, row["dv"]
                    f.write(f"{2000+YY:04d} {MM:02d} {DD:02d} {HH:02d} {MI:02d} {DV:7.1f}\n")
            print(f"Saved: {outfile}")
            number += 1

        # === Combine .obsc files ===
        all_obsc_files = sorted(self.output_dir.glob("*.obsc"))
        combined_lines = []
        for file in all_obsc_files:
            with open(file, "r") as f:
                combined_lines.extend(f.readlines())

        # Sort by datetime
        def extract_dt(line):
            try:
                return pd.to_datetime(" ".join(line.strip().split()[:5]))
            except Exception:
                return pd.NaT

        combined_lines.sort(key=extract_dt)

        combined_path = self.output_dir / "output.obsc"
        if combined_path.exists():
            print(f"⚠️ Warning: Overwriting existing {combined_path.name}")

        with open(combined_path, "w") as f:
            f.writelines(combined_lines)
        print(f"Combined output saved: {combined_path}")

        # === Remove intermediate .obsc files ===
        for file in all_obsc_files:
            if file != combined_path:
                file.unlink()
        print("Intermediate .obsc files deleted.")

        # === Plot DV time series ===
        valid_lines = [line for line in combined_lines if len(line.strip().split()) == 6]
        df_plot = pd.DataFrame(
            [line.strip().split() for line in valid_lines],
            columns=["year", "month", "day", "hour", "minute", "dv"]
        )
        df_plot[["year", "month", "day", "hour", "minute"]] = df_plot[["year", "month", "day", "hour", "minute"]].astype(int)
        df_plot["dv"] = df_plot["dv"].astype(float)
        df_plot["datetime"] = pd.to_datetime(df_plot[["year", "month", "day", "hour", "minute"]])

        fig = px.line(df_plot, x="datetime", y="dv",
                      title="Combined Diurnal Variation (DV)",
                      labels={"datetime": "Time", "dv": "DV (nT)"})
        fig.update_layout(template="plotly_white")

        output_html_path = self.output_dir / "output_plot.html"
        fig.write_html(str(output_html_path))
        print(f"Interactive plot saved: {output_html_path}")
