from pathlib import Path
import pandas as pd
import plotly.express as px

class DVCORRECTION:
    def __init__(self, anm_folder: str, obsc_folder: str, output_dir: str = None):
        self.anm_folder = Path(anm_folder)
        self.obsc_file = Path(obsc_folder) / "output.obsc"
        self.output_dir = Path(output_dir) if output_dir else self.anm_folder
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def load_anm_cc_igrf(self, filepath):
        df = pd.read_csv(filepath, sep=r'\s+', header=None, names=[
            "year", "month", "day", "hour", "minute", "second",
            "lat", "lon", "F_obs", "F_anm"
        ])
        df["second"] = 0  # clear secound!!!!
        df["datetime"] = pd.to_datetime(df[["year", "month", "day", "hour", "minute", "second"]])
        return df


    def load_obsc(self):
        df = pd.read_csv(
            self.obsc_file, sep=r"\s+", header=None,
            names=["year", "month", "day", "hour", "minute", "dv"]
        )
        df["second"]  = 0
        df["datetime"] = pd.to_datetime(df[["year", "month", "day",
                                            "hour", "minute", "second"]])
        df = df.drop_duplicates("datetime")                # reset duplication
        return df[["datetime", "dv"]]


    def process_single_file(self, anm_path, df_dv):
        df_anm = self.load_anm_cc_igrf(anm_path)
        df_anm      = df_anm.drop_duplicates("datetime") 
        df_joined   = pd.merge(df_anm, df_dv,
                        on="datetime", how="inner",
                        validate="one_to_one") 
        df_joined["F_last"] = df_joined["F_anm"] - df_joined["dv"]
        df_joined["unixtime"] = df_joined["datetime"].astype("int64") // 10**9

        output_path = self.output_dir / f"{anm_path.stem}.anm_cc_igrf_dv"
        with open(output_path, "w") as f:
            for _, row in df_joined.iterrows():
                f.write(
                    f"{int(row.year):04d} {int(row.month):02d} {int(row.day):02d} "
                    f"{int(row.hour):02d} {int(row.minute):02d} {int(row.second):02d} "
                    f"{row.lat:.8f} {row.lon:.8f} {row.F_obs:.3f} {row.F_anm:.3f} "
                    f"{row.dv:.6f} {row.F_last:.3f}\n"
                )

        output_trk = output_path.with_suffix(".trk")
        with open(output_trk, "w") as f:
            for _, row in df_joined.iterrows():
                f.write(f"{int(row.unixtime)} {row.lon:.7f} {row.lat:.7f} {row.F_last:.1f}\n")

        fig = px.line(
            df_joined,
            x="datetime",
            y=["F_obs", "F_last"],
            title=f"{anm_path.name}: Observed vs. Diurnal Corrected Magnetic Field",
            labels={"value": "nT", "variable": "Data Type"}
        )
        fig.write_html(str(output_path.with_suffix(".html")))

    def run(self):
        df_dv = self.load_obsc()
        anm_files = sorted(self.anm_folder.glob("*.anm_cc_igrf"))

        if not anm_files:
            print("No .anm_cc_igrf files found.")
            return

        for anm_file in anm_files:
            self.process_single_file(anm_file, df_dv)
            print(f"Processed: {anm_file.name}")
