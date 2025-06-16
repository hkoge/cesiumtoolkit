#!/bin/sh
# plot bathymetry color fill map

gmt defaults -D > ./gmt.conf
gmt set MAP_FRAME_TYPE plain
gmt set PS_MEDIA a0
gmt set PS_PAGE_COLOR white
gmt set COLOR_BACKGROUND white
gmt set COLOR_NAN white
gmt set GMT_GRAPHICS_DPU 720i
gmt set GMT_GRAPHICS_FORMAT png

# parameter setting
region=128:30/130:16/31:42/33:08                   # map region east/west/south/north
proj=l129:23/32:25/31:45/31:45/1:200000                                # map projection and scale

#proh=M16
ticks=a10mf10mg10m                            # boundary tick info
frame=WSNE                     # boundary frame info
cint_1=10                                # contour interval
cint_2=100                                # contour interval
anot=20t
limit=-300/300                       # contour min/max
climit=${limit}/1                  # color table min/max/interval

grdfile=mag_after.nc                    # input bathymetry grid file
cptfile=rainbow                  # color table
psfile=MAG_aistmap.ps                  # output postscript file name
#
gmt makecpt -C$cptfile -T$climit -Z -M --COLOR_NAN=white --COLOR_BACKGROUND=white >temp.cpt

# plot
gmt grdimage $grdfile -R$region -J$proj -Ctemp.cpt -K -V > $psfile
gmt psconvert $psfile -Tf -A -V

gmt grdcut $Bathy -R$region -Gtemp.grd
gmt grdcontour temp.grd -R$region -J$proj -C100 -A100 -L-3200/320 -Wthinnest -K -O -V >>$psfile

gmt grdcontour $grdfile -R$region -J$proj -C${cint_1} -Wthinnest,50/50/50 -L$limit -S10  -K -O  -V >> $psfile
gmt grdcontour $grdfile -R$region -J$proj -C${cint_2} -A$anot -Wthinnest,black -L$limit -S10 -K -O -V -T+lLH >> $psfile

cat temp_after.csv |awk '{print $5,$4}' |sed -e '1d'  |gmt psxy -R$region -J$proj -Sc0.08 -Wthinnest,119/136/153 -K -O -V >> $psfile

gmt psscale -D5/-1/8/0.5h -Ba100f50g50 -Ctemp.cpt  -P -K -O -V >>$psfile

gmt pscoast -R$region -J$proj -Df -Wthin,black -Gwhite -K -V -O >> $psfile


gmt psxy -R -J -W3,black -K -O -V << EOF >> $psfile
129:45 30:45
129:45 31:55
130:40 31:55
130:40 30:45
129:45 30:45
EOF

gmt psbasemap -R$region -J$proj -B$ticks -B$frame -LjBR+c30+w20k+l+f -O -V >> $psfile

#
gmt psconvert $psfile -Tj -A -V
