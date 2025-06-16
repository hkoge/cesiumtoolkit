from pathlib import Path
import pandas as pd
import numpy as np

class CESIUMRAW2ANMORG:
    def __init__(self, input_dir: str, output_dir: str = None, output_ext: str = ".txt.anmorg", file_ext: str = ".txt"):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir) if output_dir else self.input_dir
        self.output_ext = output_ext
        self.file_ext = file_ext

    def convert_all(self, start_number: int = 1):
        files = sorted(self.input_dir.glob(f"*{self.file_ext}"))
        if not files:
            print("!! No input files found.")
            return

        for idx, old_file in enumerate(files, start=start_number):
            new_name = f"{old_file.stem}_{idx:02d}{self.output_ext}"
            new_path = self.output_dir / new_name
            print(f"> Converting {old_file.name} to {new_name}")

            self.convert_file(old_file, new_path)
            if new_path.exists():
                print(f"> Preview of {new_name}")
                print(new_path.read_text().splitlines()[:5])
            else:
                print(f"!! File {new_name} was not created.")

    def convert_file(self, input_path: Path, output_path: Path):
        try:
            df = pd.read_csv(input_path, sep=r"\s+", engine="python")
        except Exception as e:
            print(f"XXX Failed to read {input_path.name}: {e}")
            return

        if df.empty:
            print(f"!! Skipped {input_path.name} (empty after read)")
            return

        try:
            dt = pd.to_datetime(df["DATE"] + " " + df["TIME"], format="%m/%d/%y %H:%M:%S.%f")

            out_df = pd.DataFrame({
                "year": dt.dt.year.astype(str).str.zfill(4),
                "month": dt.dt.month.astype(str).str.zfill(2),
                "day": dt.dt.day.astype(str).str.zfill(2),
                "hour": dt.dt.hour.astype(str).str.zfill(2),
                "minute": dt.dt.minute.astype(str).str.zfill(2),
                "second": dt.dt.second + dt.dt.microsecond / 1e6,
                "lat": df["POS_1_Y"],
                "lon": df["POS_1_X"],
                "mag": df["G-880_1"],
            })

            # numpy vectorize
            lines = np.char.add.reduce([
                out_df["year"] + " ",
                out_df["month"] + " ",
                out_df["day"] + " ",
                out_df["hour"] + " ",
                out_df["minute"] + " ",
                out_df["second"].map(lambda x: f"{x:.3f}") + " ",
                out_df["lat"].map(lambda x: f"{x:.7f}") + " ",
                out_df["lon"].map(lambda x: f"{x:.7f}") + " ",
                out_df["mag"].map(lambda x: f"{x:.6f}")
            ], axis=0)

            output_path.write_text("\n".join(lines) + "\n")

        except Exception as e:
            print(f"XXX Error while processing {input_path.name}: {e}")
