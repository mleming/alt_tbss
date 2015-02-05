#!/bin/bash

help=`echo $@ | grep "\(--help\|-h\)"`
nogui=`echo $@ | grep "\(--nogui\)"`
if [ ! -z "$help" ]
then
	echo "alt_tbss_1.sh [options]"
	echo "Run this script in a folder with a bunch of .nrrd DTI images."
	echo "It will register them to the same space using the ANTS-SyN algorithm, then convert them to FSL format."
	echo ""
	echo "In order to use this, you need to have DTIAtlasBuilder and its relevant software installed. This software"
	echo "Can only work on scientific Linux"
	echo "Usage:"
	echo " -h --help : Display this message"
	exit
fi


# Locations of parameter programs and files
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DTIAtlasBuilderSoftwareConfig=$DIR/DTIAtlasBuilderSoftConfiguration.txt
DTIAtlasBuilderParameters=DTIAtlasBuilderParameters.txt
CSV_DATA=$PWD/dti_ants.csv

# Edits the DTIAtlasBuilder Parameter file to use the proper output and input files
cat $DIR/$DTIAtlasBuilderParameters | sed "s@Output Folder=[^\n]*@Output Folder=$PWD@g" | sed "s@CSV Dataset File=[^\n]*@CSV Dataset File=$CSV_DATA@g" > $DTIAtlasBuilderParameters

# Put the names of files into the proper .csv
rm -f $CSV_DATA
mkdir -p origdata
for i in `ls -d1 $PWD/*.nrrd`
  do
    mv $i origdata
done
c=0
for i in `ls -d1 $PWD/origdata/*.nrrd`
  do
    let "c++"
    echo $c,$i, >> $CSV_DATA
done

# Run DTIAtlasBuilder on these settings
DTIAtlasBuilder --nogui -d $CSV_DATA -c $DTIAtlasBuilderSoftwareConfig -p $DTIAtlasBuilderParameters

# This is used to take the result of DTIAtlasBuilder and convert those to .nii format.
mkdir -p DTI
mkdir -p FA
ResampleDTI DTIAtlas/4_Final_Resampling/FinalAtlasDTI_float.nrrd DTI/target.nii.gz
dtiprocess --dti_image DTI/target.nii.gz -f FA/target.nii.gz --scalar_float -v
$FSLDIR/bin/fslmaths FA/target.nii.gz -bin FA/target_mask.nii.gz

echo "Converting formats from .nrrd to .nii.gz"
for i in `ls -d1 $PWD/DTIAtlas/4_Final_Resampling/Second_Resampling/*FinalDeformedDTI_float.nrrd | sed 's/^.*FinalAtlasDTI_FA\.nrrd$//g' | grep '\.'`
  do
     basename=`echo $i | sed 's/\.[^\/]*$//g' | sed 's/^.*\///g'`
     out_DTI=DTI/${basename}.nii.gz
     echo "Converting ${i} to ${out_DTI}"
     ResampleDTI $i $out_DTI
done
