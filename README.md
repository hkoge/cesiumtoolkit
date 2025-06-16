# CesiumToolkit

**CesiumToolkit** is a Python core package for **converting, correcting** shipborne cesium/proton magnetometer data.  It reproduces the full workflow from raw logs to publication‑ready figures while staying compatible with GMT/x2sys utilities.



###  Key modules

| Module                | Purpose                                                                                                  |
| --------------------- | -------------------------------------------------------------------------------------------------------- |
| `protonraw2anmorg.py` | Convert proton logs `*.dat` → `*.dat.anmorg`                                                             |
| `cesiumraw2anmorg.py` | Convert G‑880/Cesium logs `*.txt` → `*.txt.anmorg`                                                       |
| `trksplitter.py`      | Ramer–Douglas–Peucker track segmentation                                                                 |
| `igrfcorrection.py`   | IGRF‑14 reference‑field subtraction (based on [ppigrf](https://github.com/IAGA-VMOD/ppigrf.git) by IAGA) |
| `dvcorrection.py`     | Diurnal‑variation removal with shore OBS                                                                 |
| `dv_min2obsc.py`      | Convert Kakioka-style `.min` files to `.obsc` format                                                     |
| `anmorg1min.py`       | 1‑minute averaged anmorg output                                                                          |
| `cablecorr.py`        | Sensor position correction to account for GPS–sensor offset                                              |

### Fortran wrappers
(`src/ishihara‑fortranwrappers/`, `src/ishihara‑utils/`) implement crossover correction. `src/ishihara‑fortranwrappers/` can be compiled with the included `compile.sh` script.

### Pipeline scripts 
`run-cesium.py` runs the full processing pipeline from raw logs to cleaned tracks.  
`run-crossover.py` applies Ishihara crossover correction on track segments.

## Directory Structure

```
project-root/
├── src/
│   ├── cesiumtoolkit/             # core Python modules
│   │   ├── protonraw2anmorg.py
│   │   ├── cesiumraw2anmorg.py
│   │   ├── trksplitter.py
│   │   └── ...
│   ├── ishihara-fortranwrappers/  # original Ishihara Fortran code
│   └── ishiharautils/             # Python helpers for Ishihara workflow
├── scripts                        # Processing pipelines and example scripts (not actual entry points)
├── gmt_scripts/                   # GMT 6-based Bash scripts for x2sys setup, gridding, and map plotting
├── paper/                         # Paper draft & figures
├── examples/                      # Sample raw and intermediate data for GS24 / KH-22-10
└── pyproject.toml                 # Build metadata
```

## Installation

Requires: Python >= 3.10
Optional but recommended: [uv](https://github.com/astral-sh/uv) for fast dependency syncing


1. **Download the package**
   Either clone from [[GitHub](https://github.com/hkoge/cesiumtoolkit.git) or download the ZIP archive from our [Zenodo release](https://doi.org/xxxxxxx):

```bash
# Option 1: GitHub
git clone https://github.com/hkoge/cesiumtoolkit.git
cd cesiumtoolkit

# Option 2: Zenodo ZIP
unzip cesiumtoolkit‑vX.Y.Z.zip
cd cesiumtoolkit
```

2. **Install dependencies and the package**
   You can install using either `pip` or [uv](https://github.com/astral-sh/uv) (recommended).
   We strongly recommend using a **virtual environment** to avoid permission issues (especially on Linux/Mac).

```bash
# Option 1: Using pip
python3 -m venv .venv # Set up virtual environment
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -e .[full]

# Option 2: Or using uv (recommended)
uv sync
source .venv/bin/activate 
uv pip install -e .[full] # Install in editable mode (allows local source edits to take effect immediately)
```


3. **Build the Fortran codes**

```bash
cd src/ishihara-fortranwrappers
./compile.sh              # Requires gfortran or compatible Fortran compiler
```

**MISSION COMPLETE!!**

## (Optional) Errors on PyGMT and GMT on Ubuntu/WSL2 

run-crossover.py uses PyGMT, which sometimes requires the native GMT library (libgmt.so).
Usually things just work, but if you see errors related to libgmt.so, try the setup steps below—especially on WSL2.


#### 1. Install GMT

```bash
sudo apt update
sudo apt install gmt
```

#### 2. Check for installed GMT libraries

```bash
find /usr -name "libgmt.so*"
```

You should see something like:

```
/usr/lib/x86_64-linux-gnu/libgmt.so.6
/usr/lib/x86_64-linux-gnu/libgmt.so.6.5.0
```

#### 3. Create symbolic link to `libgmt.so`

If `libgmt.so` (without version suffix) is missing, create a symbolic link:

```bash
sudo ln -s /usr/lib/x86_64-linux-gnu/libgmt.so.6 /usr/lib/x86_64-linux-gnu/libgmt.so
```

#### 4. Add to `LD_LIBRARY_PATH`

Ensure the directory containing `libgmt.so` is in your dynamic library path:

```bash
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
```

To make this permanent:

```bash
echo 'export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

#### 5. Verify PyGMT works

```bash
python3 -c "import pygmt; print(pygmt.__version__)"
```

---

### Diurnal Variation Correction (.obsc file)

To correct for diurnal variations in magnetic data, this toolkit uses `.obsc` ASCII format (used in Step 5).   
An `.obsc` file contains 1-minute interval records of magnetic field variation  at a fixed reference station. If you already have diurnal variation data from another source (not a .min file),you can simply reformat it to match the .obsc structure below. In that case, you can skip Step 5 and proceed directly to Step 6.

**File format (plain text):**
year  month  day  hour  minute  ΔF  (space-delimited, no header row should be included in the file)
```
2024 10 13 00 00 -10.3
2024 10 13 00 01 -10.1
...
```
---
# Example data: GS24 Cruise (G-880 Cesium Magnetometer)

This example demonstrates the full processing pipeline using actual cruise data from the GS24 expedition aboard the training vessel *Shinyo-maru*.

## Directory Structure in ./examples/GS24/

```
GS24/
├── Export.G-880.gs24-day1.txt               # Raw magnetometer log
├── dv/                                      # Diurnal variation data (.min and .obsc)
├── splittedTRK_*/                           # Track-based outputs
│   ├── main_tracks/                         # Segments longer than threshold
│   ├── skipped_tracks/                      # Short segments, saved for reference
│   ├── crossoverpreprocess/                 # Intermediate files for Ishihara crossover adjustment
```

## Diurnal Variation Correction (`dv/` folder)
This example uses shore-based 1-minute data from **Kakioka Magnetic Observatory** in `.min` format.
This example does **not** include `.min` data due to licensing restrictions

To prepare this:

1. Download `.min` files for the cruise dates from
   
   [Kakioka Magnetic Observatory, 2013, Kanoya geomagnetic field 1-minute digital data in IAGA-2002 format [dataset], Kakioka Magnetic Observatory Digital Data Service, doi:10.48682/186fd.3f000](https://www.kakioka-jma.go.jp/obsdata/metadata/en/orders/new/kny_geomag_1-min)
   
   
   Required files for this example:
   ```
   kny20240929dmin.min  
   kny20240930dmin.min  
   kny20241001dmin.min  
   kny20241002dmin.min
   ```
2. Place them in `dv/`


## Outputs
### Core Processing
| File                      | Description                                                 |
| ------------------------- | ----------------------------------------------------------- |
| `*.anmorg`                | Intermediate ASCII format (timestamp, lat/lon, total-field) |
| `*.anmorg.anm_cc`         | After cable-layback correction                              |
| `*.anmorg.anm_cc_igrf`    | After IGRF subtraction                                      |
| `*.anmorg.anm_cc_igrf_dv` | After diurnal variation removal                             |
|  `*.trk` | Final x2sys-compatible track segments (split from `*.anmorg.anm_cc_igrf_dv`) |
| `*.html`                  | Interactive data preview (Plotly)                                |
| `*.cablecorr.png`         | Diagnostic plot for GPS-sensor offset                       |

### Diurnal Correction
| File               | Description                                                |
| ------------------ | ---------------------------------------------------------- |
| `output.obsc`      | Reformatted 1-min observatory data (converted from `.min`)|
| `output_plot.html` | Interactive plot of DV data                                |

### Crossover Correction via Ishihara Method

| File                          | Description                                                                 |
|-------------------------------|-----------------------------------------------------------------------------|
| `trackXX.lla`                 | Intermediate ASCII file from `.trk` segments. Columns: cruise, datetime, lon, lat, anomaly |
| `*.lsd`                       | Derived from `.lla` via `lla2lsd`. Line ID in 2nd column; last column: cumulative distance (km) |
| `*.lfind`, `*.lfind2`         | Output from `lstatfind`. Stores shortest distances between line combinations |
| `*.lwt`                       | Weights for shortest-path pairings between lines; input for `lflc` leveling |
| `*.lncor`                     | Final correction table. Columns: cruise, datetime, lon, lat, raw/corrected anomaly, correction, weight |
| `mag_before.nc/.tif`          | Gridded anomaly before correction                                           |
| `mag_after.nc/.tif`           | Gridded anomaly after correction                                            |
| `mag_comparison_gridded.html` | Interactive Plotly figure comparing pre-/post-correction results            |
| `temp_before.csv`             | Line-wise average before correction                                         |
| `temp_after.csv`              | Line-wise average after correction                                          |
| `pipeline_log_*.json`         | Log files containing reproducibility metadata and process tracing          |

## License

This project is released under the MIT License.  
Please cite the appropriate references if used for publication.
