from pathlib import Path
import pandas as pd
import plotly.io as pio
from plotly.subplots import make_subplots
import plotly.graph_objects as go
import numpy as np
# import xarray as xr
import pygmt
# import rioxarray
# import rasterio

class LWTCorrector:
    '''
    Applies leveling corrections to magnetic anomaly data based on line crossing analysis.
    This class uses `.lsd`, `.stat`, `.lfind2`, and `.lwt` files to compute and apply
    offset corrections, optionally using an iterative approach to improve convergence.
    It also provides plotting and export utilities.
    '''
    def __init__(
        self,
        lsd_path: Path = None,
        stat_path: Path = None,
        lfind2_path: Path = None,
        lwt_path: Path = None,
        output_dir: Path = None,
        basename: str = "merged"
    ):
        if output_dir:
            self.lsd_path = output_dir / f"{basename}.lsd"
            self.stat_path = output_dir / f"{basename}lsd.stat"
            self.lfind2_path = output_dir / f"{basename}.lfind2"
            self.lwt_path = output_dir / f"{basename}.lwt"
            self.output_path_default = output_dir / f"{basename}.lncor"
            self.output_dir = output_dir
        else:
            self.lsd_path = lsd_path
            self.stat_path = stat_path
            self.lfind2_path = lfind2_path
            self.lwt_path = lwt_path
            self.output_path_default = None
            self.output_dir = None

    def run(self, output_path: Path = None):
        # Applies leveling correction using offsets from the .lwt file and writes the result to a .lncor file.
        output_path = output_path or self.output_path_default
        if output_path is None:
            raise ValueError("Please specify 'output_path', or provide 'output_dir' in __init__.")

        lsd_cols = ["cruise", "line", "year", "doy_time", "lon", "lat", "mag", "dist"]
        lsd = pd.read_csv(self.lsd_path, sep=r'\s+', names=lsd_cols)

        lwt_cols = ["id", "cruise", "line", "offset", "doy1", "line2", "no2", "doy2", "mag2", "weight"]
        lwt = pd.read_csv(self.lwt_path, sep=r'\s+', names=lwt_cols)

        offset_map = lwt.groupby(["cruise", "line"])["mag2"].mean().to_dict()
        weight_map = lwt.groupby(["cruise", "line"])["weight"].mean().to_dict()

        results = []
        for _, row in lsd.iterrows():
            key = (row["cruise"], row["line"])
            offset = offset_map.get(key, 0.0)
            weight = weight_map.get(key, 0.0)
            corrected_mag = row["mag"] + offset

            result_line = f"{int(row['cruise'])} {int(row['year'])}{int(row['doy_time']):06.0f} 000000" \
                          f" {row['lon']:.5f} {row['lat']:.5f} {row['mag']:8.2f}" \
                          f" {corrected_mag:8.2f} {offset:8.4f} {weight:10.5f}"
            results.append(result_line)

        with open(output_path, "w") as f:
            f.write("\n".join(results) + "\n")
        print(f" - {output_path.name} written.")

    def run_iterative(self, output_path: Path = None, max_iter: int = 10, tol: float = 1e-4):
        # Applies leveling correction iteratively to improve offset convergence.
        output_path = output_path or self.output_path_default
        if output_path is None:
            raise ValueError("'output_dir' must be provided when initializing the class.")

        lsd_cols = ["cruise", "line", "year", "doy_time", "lon", "lat", "mag", "dist"]
        lsd = pd.read_csv(self.lsd_path, sep=r'\s+', names=lsd_cols)
        lwt_cols = ["id", "cruise", "line", "offset", "doy1", "line2", "no2", "doy2", "mag2", "weight"]
        lwt = pd.read_csv(self.lwt_path, sep=r'\s+', names=lwt_cols)

        offset_map = lwt.groupby(["cruise", "line"])["mag2"].mean().to_dict()
        weight_map = lwt.groupby(["cruise", "line"])["weight"].mean().to_dict()

        for i in range(max_iter):
            updates = lwt.groupby(["cruise", "line"])["mag2"].mean()
            total_change = sum(abs(updates.get(key, 0.0) - offset_map.get(key, 0.0)) for key in offset_map)
            print(f" - Iteration {i+1}: total offset change = {total_change:.6f}")
            if total_change < tol:
                print(" - Converged.")
                offset_map.update(updates.to_dict())
                break
            offset_map.update(updates.to_dict())

        results = []
        for _, row in lsd.iterrows():
            key = (row["cruise"], row["line"])
            offset = offset_map.get(key, 0.0)
            weight = weight_map.get(key, 0.0)
            corrected_mag = row["mag"] + offset
            result_line = f"{int(row['cruise'])} {int(row['year'])}{int(row['doy_time']):06.0f} 000000" \
                          f" {row['lon']:.5f} {row['lat']:.5f} {row['mag']:8.2f}" \
                          f" {corrected_mag:8.2f} {offset:8.4f} {weight:10.5f}"
            results.append(result_line)

        with open(output_path, "w") as f:
            f.write("\n".join(results) + "\n")
        print(f"> {output_path.name} written after {i+1} iterations.")
        self.output_path_default = output_path

    def plot(self, output_path: Path = None, spacing="0.01", tension=0.2, maxradius='2k',csvexport: bool = False, netcdfexport: bool = False):
        if not self.output_dir:
            raise ValueError("'output_dir' must be provided when initializing the class.")

        lsd_cols = ["cruise", "line", "year", "doy_time", "lon", "lat", "mag", "dist"]
        lncor_cols = ["cruise", "datetime", "dummy", "lon", "lat", "mag", "corr_mag", "offset", "weight"]

        lsd = pd.read_csv(self.lsd_path, sep=r'\s+', names=lsd_cols)
        lncor_path = output_path or self.output_path_default
        lncor = pd.read_csv(lncor_path, sep=r'\s+', names=lncor_cols)

        fig = make_subplots(rows=1, cols=2, subplot_titles=("Before Correction", "After Correction"), shared_yaxes=True, horizontal_spacing=0.1)

        for df, label in zip([lsd, lncor], ["before", "after"]):
            if label == "before":
                data = df[["lon", "lat", "mag"]].copy()
            else:
                df = df.rename(columns={"corr_mag": "mag"})
                data = df[["lon", "lat", "mag"]].copy()

            data = data.dropna(subset=["lon", "lat", "mag"])
            data = data.loc[:, ~data.columns.duplicated()].copy()
            data = data[np.isfinite(data["mag"]) & np.isfinite(data["lon"]) & np.isfinite(data["lat"])]
            data = data.reset_index(drop=True)

            if data.empty:
                print(f"! No valid data found for {label}. Skipping.")
                continue

            if csvexport:
                csv_path = self.output_dir / f"temp_{label}.csv"
                data.to_csv(csv_path, index=False)
                print(f" -  Exported to {csv_path.name}")

            region = [
                float(np.floor(data["lon"].min() * 10) / 10 - 0.3),
                float(np.ceil(data["lon"].max() * 10) / 10 + 0.3),
                float(np.floor(data["lat"].min() * 10) / 10 - 0.3),
                float(np.ceil(data["lat"].max() * 10) / 10 + 0.3),
            ]

            try:
                blk = pygmt.blockmedian(data=data, region=region, spacing=f"{spacing}+e")
                grid = pygmt.surface(data=blk, region=region, spacing=f"{spacing}+e", tension=tension, maxradius=maxradius)

                xg, yg = np.meshgrid(grid.coords["x"].values, grid.coords["y"].values, indexing="xy")
                xy = np.vstack([data["lon"], data["lat"]]).T
                from scipy.spatial import cKDTree
                tree = cKDTree(xy)
                dist, _ = tree.query(np.c_[xg.ravel(), yg.ravel()], distance_upper_bound=0.1)
                mask = dist.reshape(xg.shape)
                grid.values[np.isinf(mask)] = np.nan

                if netcdfexport:
                    
                    nc_path = self.output_dir / f"mag_{label}.nc"
                    tif_path = self.output_dir / f"mag_{label}.tif"

                    grid.rio.set_spatial_dims(x_dim="x", y_dim="y", inplace=True)
                    grid.rio.write_crs("EPSG:4326", inplace=True)

                    grid.to_netcdf(nc_path)
                    print(f"> Exported as NetCDF: {nc_path.name}")

                    grid.rio.to_raster(tif_path)
                    print(f"> Exported as GeoTIFF: {tif_path.name}")

            except Exception as e:
                print(f"X. Error during PyGMT processing ({label}): {e}")
                continue

            fig.add_trace(
                go.Heatmap(
                    z=grid.values,
                    x=grid.coords["x"].values,
                    y=grid.coords["y"].values,
                    colorscale="RdBu",
                    colorbar=dict(title="nT", x=0.45) if label == "before" else dict(title="nT", x=1.0),
                ),
                row=1,
                col=1 if label == "before" else 2
            )

        fig.update_layout(
            width=1000,
            height=500,
            title_text="Comparison of Magnetic Anomaly (Before/After Correction, GMT-gridded)",
            showlegend=False,
        )

        html_path = self.output_dir / "mag_comparison_gridded.html"
        pio.write_html(fig, file=str(html_path), auto_open=False)
        print(f" - heatmap (.html) saved: {html_path}: {html_path}")

