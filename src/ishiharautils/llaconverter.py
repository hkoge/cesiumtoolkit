import pandas as pd
import os
from datetime import datetime
import math
from pathlib import Path
#
import plotly.express as px

class LLAConverter:
    def __init__(self, epsilon=0.001, min_distance_km=2):
        self.epsilon = epsilon
        self.min_distance_km = min_distance_km

    def haversine(self, lon1, lat1, lon2, lat2):
        R = 6371000  # Earth radius in meters
        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        dphi = math.radians(lat2 - lat1)
        dlambda = math.radians(lon2 - lon1)
        a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
        return 2 * R * math.asin(math.sqrt(a))

    def calculate_total_distance(self, coords):
        return sum(self.haversine(lon1, lat1, lon2, lat2)
                   for (lon1, lat1), (lon2, lat2) in zip(coords[:-1], coords[1:]))

    def convert_unix_to_lla_format(self, unix_time):
        dt = datetime.utcfromtimestamp(unix_time)
        yymmdd = dt.strftime('%Y%m%d')
        time_str = dt.strftime('%H%M%S')
        return yymmdd, time_str

    def convert_trk_to_lla(self, filepath, output_dir=None, track_number=1):
        df = pd.read_csv(filepath, sep='\s+', header=None,
                        names=["unixtime", "lon", "lat", "anomaly"])
        df.sort_values("unixtime", inplace=True)

        coords = df[["lon", "lat"]].values
        total_distance = self.calculate_total_distance(coords)

        if total_distance < self.min_distance_km * 1000:
            print(f"Skipped: {Path(filepath).name} (distance < {self.min_distance_km} km)")
            return None

        output_lines = []
        for _, row in df.iterrows():
            yymmdd, timestr = self.convert_unix_to_lla_format(row["unixtime"])
            lon360 = row["lon"] if row["lon"] >= 0 else row["lon"] + 360
            line = f"{track_number:4d} {yymmdd} {timestr}  {lon360:9.5f} {row['lat']:9.5f} {row['anomaly']:8.2f}"
            output_lines.append(line)

        output_dir = Path(output_dir) if output_dir else Path(filepath).parent / "llaconverted"
        output_dir.mkdir(parents=True, exist_ok=True)
        outpath = output_dir / (Path(filepath).stem + '.lla')

        with open(outpath, 'w') as f:
            for line in output_lines:
                f.write(line + '\n')

        print(f" - Saved: {Path(filepath).stem + '.lla'}")

        return str(outpath)

    def convert_directory(self, folder_path, track_number=1, output_dir=None, extension="*.detrended.trk"):
        folder = Path(folder_path)
        trk_files = list(folder.glob(extension))
        if not trk_files:
            print(f"{extension} not found in", folder)
            return

        output_dir = Path(output_dir) if output_dir else folder / "llaconverted"
        output_dir.mkdir(parents=True, exist_ok=True)

        for trk_file in trk_files:
            print(f"- Processing: {trk_file.name}")
            self.convert_trk_to_lla(trk_file, output_dir=output_dir, track_number=track_number)



    def plot_lla(self, filepath):
        df = pd.read_csv(filepath, sep='\s+', header=None,
                         names=["track", "date", "time", "lon", "lat", "anomaly"])
        df["datetime"] = pd.to_datetime(df["date"].astype(str) + df["time"].astype(str),
                                         format="%Y%m%d%H%M%S")
        df["track"] = df["track"].astype(str)

        fig = px.scatter(
            df, x="lon", y="lat",
            color="track",
            hover_name="track",
            hover_data={"datetime": True, "lon": True, "lat": True, "anomaly": True},
            title="LLA Track Viewer",
            labels={"lon": "Longitude", "lat": "Latitude", "track": "Track No."},
            width=1000,
            height=700
        )
        fig.update_traces(marker=dict(size=6, opacity=0.8))

        output_html = os.path.splitext(filepath)[0] + '.html'
        fig.write_html(output_html)
        print(f"Save track: {output_html}")
        return output_html