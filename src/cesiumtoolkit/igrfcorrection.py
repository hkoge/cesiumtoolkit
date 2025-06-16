import pandas as pd
import numpy as np
import datetime
from pathlib import Path
from tqdm import tqdm
from ppigrf import igrf
from concurrent.futures import ProcessPoolExecutor


def calc_single_igrf(row_dict, wire_height):
    dt = datetime.datetime(int(row_dict["Year"]), int(row_dict["Month"]), int(row_dict["Day"]),
                            int(row_dict["Hour"]), int(row_dict["Minute"]), int(row_dict["Second"]))
    Be, Bn, Bu = igrf(float(row_dict["Longitude"]), float(row_dict["Latitude"]), wire_height, dt)
    Bt = float(np.sqrt(Bn**2 + Be**2 + Bu**2))
    return float(row_dict["Tmag"]) - Bt


class IGRFCORRECTION:
    def __init__(self, input_dir: str, wire_height: float = 0.0):
        self.input_dir = Path(input_dir)
        self.wire_height = wire_height  # in km

    def process_directory(self):
        files = list(self.input_dir.rglob("*.anm_cc"))
        if not files:
            print("No .anm_cc files found.")
            return

        for file in sorted(files):
            self.correct_file(file)

    def calculate_anomaly(self):
        with ProcessPoolExecutor() as executor:
            row_dicts = self.df.to_dict(orient="records")
            anms = list(tqdm(executor.map(calc_single_igrf, row_dicts, [self.wire_height] * len(row_dicts)),
                             total=len(row_dicts), desc="Calculating magnetic anomaly"))
        self.df["anm"] = anms

    def correct_file(self, file_path):
        file_path = Path(file_path)
        self.df = pd.read_csv(file_path, sep="\s+", header=None)
        self.df.columns = ['Year', 'Month', 'Day', 'Hour', 'Minute', 'Second', 'Latitude', 'Longitude', 'Tmag']

        self.df["Latitude"] = pd.to_numeric(self.df["Latitude"], errors="coerce")
        self.df["Longitude"] = pd.to_numeric(self.df["Longitude"], errors="coerce")
        self.df["Tmag"] = pd.to_numeric(self.df["Tmag"], errors="coerce")

        # Drop rows with NaN before calculation
        self.df = self.df.dropna(subset=["Latitude", "Longitude", "Tmag"])

        self.calculate_anomaly()

        # format
        self.df['Latitude'] = self.df['Latitude'].map('{:2.8f}'.format)
        self.df['Longitude'] = self.df['Longitude'].map('{:3.8f}'.format)
        self.df['Tmag'] = self.df['Tmag'].map('{:5.3f}'.format)
        self.df['anm'] = self.df['anm'].map('{:5.3f}'.format)

        self.df['Year'] = self.df['Year'].map('{:4d}'.format)
        self.df['Month'] = self.df['Month'].map('{:02d}'.format)
        self.df['Day'] = self.df['Day'].map('{:02d}'.format)
        self.df['Hour'] = self.df['Hour'].map('{:02d}'.format)
        self.df['Minute'] = self.df['Minute'].map('{:02d}'.format)
        self.df['Second'] = self.df['Second'].map('{:02d}'.format)

        output_path = file_path.with_name(file_path.stem + ".anm_cc_igrf")
        with open(output_path, 'w') as f:
            for row in self.df.itertuples(index=False):
                f.write(" ".join(row) + "\n")

        print(f"Saved: {output_path}")
        return output_path