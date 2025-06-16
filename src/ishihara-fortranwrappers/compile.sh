#!/bin/bash
FileExt=*.f

Number=1
for OldFile in $FileExt;    do
    na=`basename ${OldFile} .f`
    gfortran  ${OldFile} -o ${na}
    chmod +x ${na}
    echo ${na} compiled
    #mv $OldFile $NewFile
done;