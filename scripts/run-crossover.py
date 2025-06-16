#!/usr/bin/env python3

# ==================================================
#  Ishihara Method Workflow - 5-step processing
#
# -- Step 1: .trk → .lla
# -- Step 2: .lla → .lsd + line index mapping
# -- Step 3: .lsd → .stat/.lfind2/.lwt via Fortran
# -- Step 4: Python-based leveling correction
# -- Step 5: Plotting and exporting results
# ==================================================

from pathlib import Path
from ishiharautils import LLAConverter, LSDConverter, IshiharaPipeline, LWTCorrector

# ========== Setting ==========
input_path = Path("../examples/GS24/splittedTRK_20250610_181208/main_tracks")
cruise_name = 211


# ========== Paths ==========
output_dir = input_path.parent / "crossoverpreprocess"
lla_dir = output_dir / "llaconverted"
merged_lsd = output_dir / "merged.lsd"
mapping_csv = output_dir / "line_index_map.csv"
lncor_file = output_dir / "merged.lncor"

# ========== 1) .trk → .lla ==========
if lla_dir.exists() and any(lla_dir.glob("*.lla")):
    print(" - Step 1 skipped: .lla files already exist.")
else:
    print(" - Step 1: Converting .trk → .lla")
    converter = LLAConverter()
    converter.convert_directory(
        folder_path=str(input_path),
        track_number=cruise_name,
        output_dir=lla_dir,
        extension="*.trk"
    )

# ========== 2) .lla → .lsd ==========
if merged_lsd.exists() and mapping_csv.exists():
    print(" - Step 2 skipped: merged .lsd and line_index_map.csv already exist.")
else:
    print(" - Step 2: Converting .lla → .lsd")
    lsd_converter = LSDConverter()
    lsd_converter.convert_all_lla_to_lsd_and_merge(
        lla_dir=lla_dir,
        output_lsd_path=merged_lsd,
        mapping_csv_path=mapping_csv
    )

# ========== 3) .lsd → .stat, .lfind2, .lwt ==========
print(" - Step 3: Running Fortran-based crossover detection")
pipeline = IshiharaPipeline(input_file=merged_lsd)
pipeline.run_from_lsd()


# ========== 4) Python-based correction ==========
print(" - Step 4: Applying leveling correction (Python)")
corrector = LWTCorrector(output_dir=output_dir)

if not lncor_file.exists():
    print(" - .lncor not found → running iterative correction")
    corrector.run_iterative(
        output_path=lncor_file,
        max_iter=10,
        tol=1e-4
    )
else:
    print(f" - Use existing .lncor: {lncor_file.name}")
    corrector.run(output_path=lncor_file)

# ========== 5) Plotting & exporting ==========
print(" - Step 5: Generating gridded heatmap & exporting")
corrector.plot(
    output_path=lncor_file,
    spacing=0.002,
    tension=0.65,
    maxradius='2k',
    csvexport=True,
    netcdfexport=True
)

print(" - All steps completed successfully!")
