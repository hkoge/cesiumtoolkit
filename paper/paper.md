---
title: "ShipMagToolkit: Unified Python Core and Legacy Framework for shipborne total-field magnetometer Processing"
tags:
  - Python
  - Fortran
  - Geophysics
  - Magnetometry
  - Data Integration
  - Data Visualization
authors:
  - name: Hiroaki Koge
    orcid: 0000-0002-8720-4975
    corresponding: true
    affiliation: 1
  - name: Taichi Sato
    orcid: 0000-0002-2158-3730
    affiliation: 1
  - name: Takemi Ishihara
    orcid: 0000-0002-7852-2111
    affiliation: 1
  - name: Seshiro Furuyama
    orcid: 0000-0002-5723-2027
    affiliation: 1
  - name: Seitaro Ono
    orcid: 0009-0002-4555-7462
    equal-contrib: true
    affiliation: 1
  - name: Kyoko Okino
    orcid: 0009-0002-4555-7462
    equal-contrib: true
    affiliation: 2
affiliations:
  - name: "Geological Survey of Japan, National Institute of Advanced Industrial Science and Technology (AIST), 1-1-1 Higashi, Tsukuba, Ibaraki 305-8567, Japan"
    index: 1
    ror: 01703db54
  - name: "Atmosphere and Ocean Research Institute, The University of Tokyo, 5-1-5, Kashiwanoha, Kashiwa-shi, Chiba 277-8564, Japan"
    index: 2
    ror: 057zh3y96

date: 2025-06-12
bibliography: paper.bib
---

# Summary
'ShipMagToolkit' is a Python-centric package that consolidates every major stage of shipborne total-field magnetometer (TFM) processing into a single, scriptable workflow. The front-end driver 'scripts/run-cesium.py' converts raw sensor logs into intermediate ASCII files, applies moving-average smoothing, performs cable-layback correction to reconcile the spatial offset between the magnetometer and the vessel’s GPS antenna, executes International Geomagnetic Reference Field (IGRF) [@IAGA2024] subtraction via IAGA-VMOD/ppigrf [@Laundal2024], and prepares observatory records for diurnal-variation correction before applying the correction. After diurnal effects have been removed, the data are partitioned into straight-line survey legs and turning-motion intervals to facilitate line-based anomaly analysis. Crossover levelling is then performed by 'scripts/run-crossover.py', which wraps legacy Fortran routines in thin Python bindings to implement the Ishihara algorithm [@Ishihara2015]. The resulting outputs remain fully compatible with GMT’s 'x2sys' [@Wessel2010]; definition files and a Bash pipeline for batch processing reside in the 'gmt_scripts/' directory, alongside example scripts for gridding the final anomalies.


# Statement of Need
Traditional TFM processing relied on a scattered mix of Bash/Fortran/C/MATLAB scripts and executables, making execution order is opaque, reproducibility fragile, and modification cumbersome. 'ShipMagToolkit' replaces that sprawl with a single, readable codebase: top-level 'run-*.py' drivers lay out the entire sequence of steps, so users can follow the flow line-by-line and preserve intermediate outputs to guarantee reproducibility, while the numerical routines live in a modular API under 'src/', allowing algorithms to be swapped or extended without touching the rest of the pipeline. This arrangement lowers the entry barrier for newcomers and keeps the workflow transparent and maintainable.

## Documentation and Examples
A key feature of ShipMagToolkit is the first open-source packaging of the Ishihara crossover-adjustment algorithm [@Ishihara2015] for the Python ecosystem. Instead of re-implementing the routine from scratch, we wrap the original Fortran code in thin Python bindings, preserving its bit-level behaviour while making it directly callable from modern workflows. The method minimises line-to-line misfits not only at conventional crossover points but also in surveys where crossovers are sparse or unreliable. It explicitly models the combined effects of external-field disturbances, hull magnetisation, and navigation errors, iteratively solving for per-track level shifts that yield a self-consistent data set. This makes the algorithm especially valuable when observatory-based diurnal correction is impractical—e.g. in remote oceans far from fixed stations—or when CM4-based estimates of diurnal and secular variation carry large uncertainties [@Oda2021]. Its proven robustness led to adoption for integrating marine data into the second World Digital Magnetic Anomaly Map (WDMAM v2) [@Lesur2016].


### './examples/GS24/'
This project demonstrates an end-to-end workflow for the GS24 cruise (G-880 cesium magnetometers. Geometrics Inc.). It includes raw '.txt' logs, all intermediates produced by 'run-cesium.py' and 'run-crossover.py', and shell scripts for optional GMT gridding. Because licensing prevents redistribution of observatory data, users must download the one-minute Kakioka files [@Kakioka2013] themselves and place the '.min' files in 'examples/GS24/dv/' before running the pipeline.

### './examples/Hakuho/'
Provides a minimal sample of raw data recorded by a surface proton magnetometer (PR745, Kawasaki Geological Engineering Co., Ltd.) during the KH-22-10 cruise [@Koge2022], for use in quick file-conversion tests.


# Acknowledgements
We gratefully acknowledge the captains, crew, scientific parties, and participating students of the 'Shinyo-maru' (GS24 cruise) and 'R/V Hakuho-maru' (KH-22-10 cruise) for their invaluable support in magnetic data acquisition, instrument operation, and initial processing that made the development and validation of this toolkit possible.
