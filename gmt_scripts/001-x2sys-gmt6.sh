#!/bin/bash
#
# BEFORE YOU RUN:
# 0. (Only once per machine) Copy the required geomag format definition (geomag.def)
#    into GMT's format directory:
#    sudo cp geomag.def $(gmt --show-datadir)/x2sys
#    e.g., sudo cp ./gmt/geomag.def /usr/local/share/gmt/x2sys/geomag.def
#
# 1. Place '001-x2sys-gmt6.sh' inside the folder containing '.trk' files
# 2. Adjust the 'region' and 'Cruise_name' variables if needed
# 3. Run the script:
#    bash 001-x2sys-gmt6.sh

Cruise_name=coe_mag
region=129.5/129.9/29.5/29.67
echo '.......X2SYS........'

#put all folder in $X2SYS_HOME
export X2SYS_HOME=`pwd`
echo "please put all .trk files in "$X2SYS_HOME
#
rm -rf $Cruise_name 

#make lis file
ls -1 *.trk >tracks.lis

#X2SYS
gmt x2sys_init ${Cruise_name} -Dgeomag -G -Etrk -I1m/1m -R${region} -V -F
gmt x2sys_binlist =tracks.lis -T${Cruise_name} -V > 010_tracks.tbf
gmt x2sys_put 010_tracks.tbf -T${Cruise_name} -V
gmt x2sys_get -T${Cruise_name} -Fmag -V
gmt x2sys_cross =tracks.lis -T${Cruise_name} -V > 011_crossovers.d
gmt x2sys_report -Cmag -T${Cruise_name} 011_crossovers.d -V
gmt x2sys_list 011_crossovers.d -Cmag -T${Cruise_name} -Fnhc -V > 012_mag_coe.txt
#Nhc -> nhc no bug, but the value of mag is quite change


gmt x2sys_solve 012_mag_coe.txt -V -T${Cruise_name} -Cmag -Eh  >013_coe_table_mag.txt

gmt x2sys_datalist =tracks.lis -T${Cruise_name} -L013_coe_table_mag.txt -V > 020_result_x2sys.txt
