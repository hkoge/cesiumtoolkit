"""
trk_splitter.py — Split *.trk files into straight-line segments using RDP.

Created: 2025-06-10
"""

from __future__ import annotations
import datetime as _dt
import math
from pathlib import Path

import numpy as np
import pandas as pd
import plotly.express as px
from rdp import rdp


__all__ = ["TRKSplitter", "splitter"]


class splitter:
    """
    Split `.trk` (unixtime lon lat mag) into straight segments.

    Parameters
    ----------
    epsilon : float, default 0.001
        Epsilon parameter (degrees) for the RDP algorithm.
    min_distance_km : float, default 2.0
        Threshold: segments shorter than this are tagged as ``skipped``.
    """

    def __init__(self, *, epsilon: float = 0.001, min_distance_km: float = 2.0) -> None:
        self.epsilon = float(epsilon)
        self.min_distance_km = float(min_distance_km)

    def split(self, filepath: str | Path) -> Path:
        """
        Execute the split and return the output directory.

        A timestamped folder is created next to the input file:
        `splittedTRK_YYYYMMDD_HHMMSS/{main,skipped}_tracks/`.

        Raises
        ------
        RuntimeError
            If the input cannot be read.
        """
        fp = Path(filepath).expanduser().resolve()
        print(f"\n >< Splitting {fp.name} ><")

        try:
            df = pd.read_csv(
                fp,
                delim_whitespace=True,
                names=["unixtime", "lon", "lat", "mag"],
                dtype=float,
                comment="#",
                engine="python",
            ).dropna()
        except Exception as exc:
            raise RuntimeError(f"Failed to read {fp}") from exc

        if df.empty:
            print("!!  input file is empty – nothing to do.")
            return fp.parent

        coords = df[["lon", "lat"]].to_numpy()

        # -- 2) RDP split --
        mask = rdp(coords, epsilon=self.epsilon, return_mask=True)
        idx = np.flatnonzero(mask)
        if idx[0] != 0:
            idx = np.insert(idx, 0, 0)
        if idx[-1] != len(df) - 1:
            idx = np.append(idx, len(df) - 1)
        boundaries = np.append(idx, len(df))

        # -- 3) Output dirs --
        tag       = _dt.datetime.now().strftime("%Y%m%d_%H%M%S")
        base_dir  = fp.parent / f"splittedTRK_{tag}"
        main_dir  = base_dir / "main_tracks"
        skip_dir  = base_dir / "skipped_tracks"
        main_dir.mkdir(parents=True, exist_ok=True)
        skip_dir.mkdir(exist_ok=True)

        # -- 4) Save --
        track_id      = 0
        track_vec     = np.full(len(df), -1, dtype=int)
        category_vec  = np.empty(len(df), dtype=object)

        for s, e in zip(boundaries[:-1], boundaries[1:]):
            seg = df.iloc[s:e]
            seg_len = _segment_length(seg[["lon", "lat"]].to_numpy())
            is_main = seg_len >= self.min_distance_km * 1_000.0
            outdir  = main_dir if is_main else skip_dir
            category = "main" if is_main else "skipped"

            (outdir / f"track{track_id:02d}.trk").write_text(
                "\n".join(
                    f"{int(t):d} {lon:.7f} {lat:.7f} {mag:.1f}"
                    for t, lon, lat, mag in seg.to_numpy()
                ),
                encoding="utf-8",
            )

            track_vec[s:e]    = track_id
            category_vec[s:e] = category
            print(f" > Saved {category}: track{track_id:02d}.trk ({seg_len/1000:.2f} km)")
            track_id += 1

        df_plot = df.assign(track=track_vec, category=category_vec)
        _save_plot(df_plot, base_dir / f"{fp.stem}.html")
        print(f"\n > HTML visualisation → {base_dir / (fp.stem + '.html')}\n")

        return base_dir


def TRKSplitter(
    input_dir: str | Path,
    *,
    epsilon: float = 0.001,
    min_distance_km: float = 2.0,
) -> Path:
    splitter_core = splitter(epsilon=epsilon, min_distance_km=min_distance_km)
    input_dir = Path(input_dir).expanduser()

    base_dir = None
    for trk in sorted(input_dir.glob("*.trk")):
        base_dir = splitter_core.split(trk)

    if base_dir is None:
        raise RuntimeError("No .trk files were found for splitting.")

    return base_dir / "main_tracks"


# -- helper functions outside class --
def _haversine(lon1: float, lat1: float, lon2: float, lat2: float) -> float:
    R = 6_371_000.0
    φ1, φ2 = math.radians(lat1), math.radians(lat2)
    Δφ = math.radians(lat2 - lat1)
    Δλ = math.radians(lon2 - lon1)
    a = math.sin(Δφ / 2) ** 2 + math.cos(φ1) * math.cos(φ2) * math.sin(Δλ / 2) ** 2
    return 2.0 * R * math.asin(math.sqrt(a))


def _segment_length(coords: np.ndarray) -> float:
    if len(coords) < 2:
        return 0.0
    return sum(
        _haversine(lon1, lat1, lon2, lat2)
        for (lon1, lat1), (lon2, lat2) in zip(coords[:-1], coords[1:])
    )


def _save_plot(df: pd.DataFrame, html_path: Path) -> None:
    fig = px.scatter_geo(
        df,
        lat="lat",
        lon="lon",
        color=df["track"].astype(str),
        symbol="category",
        title="RDP-split Tracks",
        projection="natural earth",
    )
    fig.update_traces(marker=dict(size=4, opacity=0.8))
    fig.write_html(html_path, include_plotlyjs="cdn")
