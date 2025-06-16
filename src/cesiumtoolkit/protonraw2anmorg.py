#!/usr/bin/env python3
"""protonraw2anmorg.py — Convert proton‑magnetometer ``*.dat`` files to ``*.dat.anmorg``.
Keeps original file name plus extra suffix; no numeric index is added.
"""

from pathlib import Path
import re
import numpy as np
import pandas as pd

class PROTONRAW2ANMORG:
    """
    Converter: ``file.dat`` → ``file.dat.anmorg`` .
    """

    def __init__(
        self,
        input_dir: str | Path,
        output_dir: str | Path | None = None,
        output_ext: str = ".anmorg",
        file_ext: str = ".dat",
    ) -> None:
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir) if output_dir else self.input_dir
        self.output_ext = output_ext   # text appended after ".dat"
        self.file_ext = file_ext       # expected raw extension (usually ".dat")

    def convert_all(self, start_number: int = 1, preview: bool = False) -> None:  # noqa: D401
        """Convert every ``*.dat`` file found in *input_dir*.

        *Signature kept identical to previous version for drop‑in compatibility.*
        ``start_number`` is ignored now because no numeric suffix is added, but
        the argument remains so that existing calls do not break.
        """
        files = sorted(self.input_dir.glob(f"*{self.file_ext}"))
        if not files:
            print("!! No input files found.")
            return

        for old_file in files:
            new_name = old_file.name + self.output_ext  # e.g. foo.dat.anmorg
            new_path = self.output_dir / new_name
            print(f"> Converting {old_file.name} → {new_name}")

            self.convert_file(old_file, new_path)

            if preview and new_path.exists():
                print("  Preview (first 5 lines):")
                print("\n".join(new_path.read_text().splitlines()[:5]))

    def convert_file(self, input_path: Path, output_path: Path) -> None:  # noqa: D401
        """Convert a single raw file to anmorg format."""
        try:
            # 1) normalise delimiters and strip leading '$'
            cleaned_lines: list[str] = [
                re.sub(r"\s+", " ", re.sub(r"[,:/]", " ", ln.lstrip("$"))).strip()
                for ln in input_path.read_text(encoding="utf-8").splitlines()
            ]

            # 2) split into columns
            split_df = (
                pd.DataFrame(cleaned_lines, columns=["raw"])["raw"].str.split(" ", expand=True)
            )

            # 3) construct datetime
            dt = pd.to_datetime(
                split_df[0] + " " + split_df[1] + " " + split_df[2] + " " +
                split_df[3] + " " + split_df[4] + " " + split_df[5],
                format="%Y %m %d %H %M %S",
            )

            # 4) latitude / longitude and magnetic intensity
            lat = _parse_coord(split_df[26], split_df[27])
            lon = _parse_coord(split_df[29], split_df[30])
            mag = pd.to_numeric(split_df[6], errors="coerce")

            # 5) assemble DataFrame and write text file
            out_df = pd.DataFrame({
                "year"  : dt.dt.year.astype(str).str.zfill(4),
                "month" : dt.dt.month.astype(str).str.zfill(2),
                "day"   : dt.dt.day.astype(str).str.zfill(2),
                "hour"  : dt.dt.hour.astype(str).str.zfill(2),
                "minute": dt.dt.minute.astype(str).str.zfill(2),
                "second": (dt.dt.second + dt.dt.microsecond/1e6).map(
                    lambda x: f"{int(x):02d}.{int(round((x-int(x))*1000)):03d}"
                ),
                "lat"   : lat.map("{:.7f}".format),
                "lon"   : lon.map("{:.7f}".format),
                "mag"   : mag.map("{:.6f}".format),
            })

            output_path.write_text("\n".join(out_df.agg(" ".join, axis=1)) + "\n")

        except Exception as exc:  # noqa: BLE001
            print(f"XXX Error while processing {input_path.name}: {exc}")


def _parse_coord(deg_col: pd.Series, min_col: pd.Series) -> pd.Series:
    """Return decimal degrees from degree/minute + hemisphere columns."""
    hemi = deg_col.str.extract(r"([NSEWnsew])", expand=False).str.upper()
    deg_abs = pd.to_numeric(deg_col.str.extract(r"([0-9]+)", expand=False), errors="coerce")
    minutes = pd.to_numeric(min_col, errors="coerce")
    sign = np.where(hemi.isin(["S", "W"]), -1.0, 1.0)
    sign = np.where(deg_col.str.contains(r"-"), -1.0, sign)
    return sign * (deg_abs + minutes/60)