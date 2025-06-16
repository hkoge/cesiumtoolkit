#!/bin/bash
# =====================================================
# Create a masked surface grid and plot a surface map
# =====================================================

# -------- Parameters --------
region=129/130.5/29/30    # Region: lon_min/lon_max/lat_min/lat_max
interval=0.2m                      # Grid spacing (e.g., 0.2m)
tension=0.65                       # Tension factor for surface interpolation
radius=2k                          # Search radius for masking
xyzfile=tmp.xyz                    # Input XYZ data file
blkfile=area.blk                  # Intermediate blockmedian output
grdfile=area.grd                  # Raw interpolated grid
maskfile=area.mask.grd            # Mask grid
maskedfile=area_masked.grd        # Final masked grid file

# -------- Prepare Grid --------
cat 020_result_x2sys.txt | awk '{print $2, $3, $4}' > $xyzfile
gmt blockmedian $xyzfile -R$region -I$interval -V > $blkfile
gmt surface $blkfile -R$region -I$interval -T$tension -G$grdfile -fg -V
gmt grdmask $blkfile -R$region -I$interval -NNaN/1/1 -S$radius -G$maskfile -V
gmt grdmath $grdfile $maskfile OR = $maskedfile

# -------- Plot Surface Map --------
REGI=$region
GRD=$maskedfile
PS=surface_map_no_dv.ps           # Output PostScript file
PROJ=M16                          # Projection size (16 cm map width)
BOUNDARY=f2ma20m                  # Map frame ticks and annotations
CPTO=EMAG2_nise.cpt               # Original CPT
CPT=temp.cpt                      # Temporary CPT
CONT=20                           # Contour interval (no label)
ANOT=100                          # Labeled contour interval
LIMIT=-500/500                    # Range of data for contour and color scale

# Set GMT defaults
gmt gmtset MAP_FRAME_TYPE=plain 

# Create CPT
gmt makecpt -C$CPTO -T${LIMIT}/10 -Z > $CPT

# Plot grid image
gmt grdimage $GRD -R$REGI -J$PROJ -C$CPT -P -K -V -U$0> $PS

# Add contour lines (unlabeled)
gmt grdcontour $GRD -R$REGI -J$PROJ -C$CONT -L$LIMIT -W0.1,gray -K -O -V >> $PS

# Add labeled contour lines
gmt grdcontour $GRD -R$REGI -J$PROJ -C$ANOT -A$ANOT -L$LIMIT -W0.5,gray -K -O -V >> $PS

# Add caost lines and filled land
gmt pscoast -R$REGION -J$PROJ -D$RESO -W0.1 -G120 -K -O -V   >>$PS

# Add color scale bar
gmt psscale -DjCT+w2i+o5/0.5c+h -C$CPT -Ba200g20+l"Magnetic anomaly (nT)" -R -J -K -O -V >> $PS

# Add map frame and optional map scale
gmt psbasemap -R$REGI -J$PROJ -B$BOUNDARY -Lf129.5/31.6/33.5/100k+u -O -V >> $PS

# Convert to JPEG
gmt psconvert $PS -Tj -A -V
