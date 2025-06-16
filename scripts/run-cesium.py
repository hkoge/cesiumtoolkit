from cesiumtoolkit import (
    CESIUMRAW2ANMORG, 
    ANMORG1MIN, CABLECORRECTION,
    IGRFCORRECTION, DVCONVERT, DVCORRECTION,
    TRKSplitter
)
# PROTONRAW2ANMORG

if __name__ == "__main__":

    # ============================================
    #  SETTINGS: Input directories and parameters
    # ============================================

    # Input directories
    input_dir     = "../examples/GS24"
    input_dv_dir  = "../examples/GS24/dv"

    # --- CABLE CORRECTION ---
    wire_len = 329.95  # [m] Cable length from ship's GPS to magnetometer
    steps    = 3       # Number of steps ahead used to compute heading (azimuth)

    # Notes on `steps`:
    #   steps = 1  → short-baseline direction (sensitive to noise/turns)
    #   steps = 3  → moderate smoothing (recommended for stable track direction)
    #   steps ≥ 5 → strong smoothing (for fast or sparse data)

    # --- RDP Track Simplification ---
    epsilon           = 0.01   # RDP simplification tolerance [degrees]
    min_distance_km   = 3      # Minimum segment length to keep [km]

    # ============================================
    #  PROCESSING PIPELINE
    # ============================================

    # Step 1: Convert raw .txt files → .anmorg (original ANM format)
    converter = CESIUMRAW2ANMORG(input_dir=input_dir)
    # in proton magnetometer data by Hakuho-maru use 'PROTONRAW2ANMORG'
    converter.convert_all(start_number=1)

    # Step 2: Interpolate .anmorg to 1-minute intervals and plot
    processor = ANMORG1MIN(input_dir=input_dir)
    processor.process_directory()

    # Step 3: Apply cable length correction (.anmorg → .anm_cc)
    corrector = CABLECORRECTION(input_dir=input_dir, wire_len=wire_len, steps=steps)
    corrector.process_directory()

    # Step 4: Subtract IGRF model (.anm_cc → .anm_cc_igrf)
    igrf_corrector = IGRFCORRECTION(input_dir=input_dir, wire_height=0.0)  # height in km
    igrf_corrector.process_directory()

    # Step 5: Convert daily variation data (.min → .obsc)
    dv_converter = DVCONVERT(input_dir=input_dv_dir) 
    dv_converter.convert()

    # Step 6: Apply diurnal variation correction
    dv_corrector = DVCORRECTION(anm_folder=input_dir, obsc_folder=input_dv_dir)
    dv_corrector.run()

    # Step 7: Split tracks using RDP algorithm (save to main/skipped folders)
    main_trk_dir = TRKSplitter(
        input_dir=input_dir,
        epsilon=epsilon,
        min_distance_km=min_distance_km,
    )