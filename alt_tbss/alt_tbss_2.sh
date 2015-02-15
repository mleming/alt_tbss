#!/bin/bash

help=`echo $@ | grep "\(--help\|-h\)"`
nogui=`echo $@ | grep "\(--nogui\)"`
gaussian=`echo $@ | grep "\(--gaussian\|-g\)"`
sigma=`echo $@ | sed 's/.*[[:space:]]*-s[[:space:]]*\(\w*\).*/\1/g' | grep ^[0-9]*$`; if [ -z "$sigma" ]; then sigma=3; fi
all_measures=`echo $@ | grep '\(--\)\(RD\|AD\|MD\|FA\)'`
compute_FA=`echo $@ | grep "\(--FA\)"`
compute_AD=`echo $@ | grep "\(--AD\)"`
compute_MD=`echo $@ | grep "\(--MD\)"`
compute_RD=`echo $@ | grep "\(--RD\)"`
if [ -z "$all_measures" ]
then
	compute_FA="line"
	compute_AD="line"
	compute_MD="line"
	compute_RD="line"
fi

if [ ! -z "$help" ]
then
	echo "alt_tbss_2.sh"
	echo "Run this script in the same folder that you ran alt_tbss_1.sh in."
	echo "This will produce blurred and unblurred estimations of the DTI images."
	echo "provided by the previous step."
	echo "Usage:"
	echo "-h, --help: Display this message"
	echo "-g, --gaussian: Project Gaussian values onto the skeleton, still using the"
	echo "	              projection estimates given by the maximum value perpendicular"
	echo "	              to the skeleton"
	echo "-s <number>: Sigma value for Gaussian"
	echo "--nogui: Do not display and graphical interfaces while running this script"
	exit
fi


echo "Estimating FA, AD, MD from DTI Images"
mkdir -p FA
mkdir -p AD
mkdir -p MD
mkdir -p RD
ALL_FA=""
ALL_AD=""
ALL_MD=""
ALL_RD=""
ALL_FA_GAUSSIAN=""
ALL_AD_GAUSSIAN=""
ALL_MD_GAUSSIAN=""
ALL_RD_GAUSSIAN=""

#Need to incorporate Blur images into this --- GaussianBlurImageFilter
for i in `ls -d1 $PWD/DTI/*float.nii.gz`
  do
     basename=`echo $i | sed 's/\.[^\/]*$//g' | sed 's/^.*\///g'`

     echo "Estimating measurements of ${basename}"
     out_DTI=DTI/${basename}.nii.gz

     out_FA=FA/${basename}.nii.gz
     out_AD=AD/${basename}.nii.gz
     out_MD=MD/${basename}.nii.gz
     out_RD=RD/${basename}.nii.gz
     out_FA_gaussian=FA/${basename}_gaussian.nii.gz
     out_AD_gaussian=AD/${basename}_gaussian.nii.gz
     out_MD_gaussian=MD/${basename}_gaussian.nii.gz
     out_RD_gaussian=RD/${basename}_gaussian.nii.gz

     ALL_FA=$ALL_FA" "$PWD/$out_FA
     ALL_AD=$ALL_AD" "$PWD/$out_AD
     ALL_MD=$ALL_MD" "$PWD/$out_MD
     ALL_RD=$ALL_RD" "$PWD/$out_RD
     ALL_FA_GAUSSIAN=$ALL_FA" "$PWD/$out_FA_gaussian
     ALL_AD_GAUSSIAN=$ALL_AD" "$PWD/$out_AD_gaussian
     ALL_MD_GAUSSIAN=$ALL_MD" "$PWD/$out_MD_gaussian
     ALL_RD_GAUSSIAN=$ALL_RD" "$PWD/$out_RD_gaussian

     # Estimate FA, AD, MD, RD from DTI
     if [ ! -e "$out_DTI" ] || [ ! -e "$out_AD" ] || [ ! -e "$out_RD" ] || [ ! -e "$out_MD" ]
     then
	     dtiprocess --dti_image $out_DTI -f $out_FA --lambda1_output $out_AD --RD_output $out_RD -m $out_MD --scalar_float
     fi
     # Output Gaussian blurred FA, AD, MD, RD
     if [ ! -z "$gaussian" ]
     then
           echo "Gaussian blurring ${basename}"
           if [ ! -e "$out_FA_gaussian" ]; then $FSLDIR/bin/fslmaths $out_FA -s $sigma $out_FA_gaussian; fi
           if [ ! -e "$out_AD_gaussian" ]; then $FSLDIR/bin/fslmaths $out_AD -s $sigma $out_AD_gaussian; fi
           if [ ! -e "$out_MD_gaussian" ]; then $FSLDIR/bin/fslmaths $out_MD -s $sigma $out_MD_gaussian; fi
           if [ ! -e "$out_RD_gaussian" ]; then $FSLDIR/bin/fslmaths $out_RD -s $sigma $out_RD_gaussian; fi
     fi
     if [ ! -e "FA/${basename}_mask.nii.gz" ]; then $FSLDIR/bin/fslmaths $out_FA -bin FA/${basename}_mask.nii.gz; fi # Create mask from FA
done

mkdir -p stats

echo "Merging FA files"
if [ ! -e "stats/all_FA.nii.gz" ] && [ ! -z "$compute_FA" ]; then fslmerge -t stats/all_FA.nii.gz $ALL_FA; fi
if [ ! -e "stats/all_FA_gaussian.nii.gz" ] && [ ! -z "$gaussian" ] && [ ! -z "$compute_FA" ]; then fslmerge -t stats/all_FA_gaussian.nii.gz $ALL_FA_GAUSSIAN; fi

echo "Merging AD files"
if [ ! -e "stats/all_AD.nii.gz" ] && [ ! -z "$compute_AD" ]; then fslmerge -t stats/all_AD.nii.gz $ALL_AD; fi
if [ ! -e "stats/all_AD_gaussian.nii.gz" ] && [ ! -z "$gaussian" ] && [ ! -z "$compute_AD" ]; then fslmerge -t stats/all_AD_gaussian.nii.gz $ALL_AD_GAUSSIAN; fi

echo "Merging MD files"
if [ ! -e "stats/all_MD.nii.gz" ] && [ ! -z "$compute_AD" ]; then fslmerge -t stats/all_MD.nii.gz $ALL_MD; fi
if [ ! -e "stats/all_MD_gaussian.nii.gz" ] && [ ! -z "$gaussian" ] && [ ! -z "$compute_MD" ]; then fslmerge -t stats/all_MD_gaussian.nii.gz $ALL_MD_GAUSSIAN; fi

echo "Merging RD files"
if [ ! -e "stats/all_RD.nii.gz" ] && [ ! -z "$compute_RD" ]; then fslmerge -t stats/all_RD.nii.gz $ALL_RD; fi
if [ ! -e "stats/all_RD_gaussian.nii.gz" ] && [ ! -z "$gaussian" ] && [ ! -z "$compute_RD" ]; then fslmerge -t stats/all_RD_gaussian.nii.gz $ALL_RD_GAUSSIAN; fi

echo "Creating valid mask and mean FA"

if [ ! -e "stats/mean_FA.nii.gz" ]; then $FSLDIR/bin/fslmaths stats/all_FA -Tmean stats/mean_FA; fi

if [ ! -e "stats/mean_FA_mask.nii.gz" ]
then
##	$FSLDIR/bin/fslmaths stats/all_FA -max 0 -Tmin -bin stats/mean_FA_mask -odt char
	$FSLDIR/bin/fslmaths stats/mean_FA -thr 0.00005 -bin stats/mean_FA_mask -odt char
fi

#if [ -z "$nogui" ];
#then
#	fslview stats/mean_FA stats/mean_FA_mask;
#fi

$FSLDIR/bin/fslmaths stats/all_FA -mas stats/mean_FA_mask stats/all_FA
$FSLDIR/bin/fslmaths stats/all_AD -mas stats/mean_FA_mask stats/all_AD
$FSLDIR/bin/fslmaths stats/all_RD -mas stats/mean_FA_mask stats/all_RD
$FSLDIR/bin/fslmaths stats/all_MD -mas stats/mean_FA_mask stats/all_MD
if [ ! -e "stats/mean_FA.nii.gz" ]; then $FSLDIR/bin/fslmaths stats/all_FA -Tmean stats/mean_FA; fi

echo "Creating mean AD"
if [ ! -e "stats/mean_AD.nii.gz" ] && [ ! -z "$compute_AD" ]; then $FSLDIR/bin/fslmaths stats/all_AD -Tmean stats/mean_AD; fi

echo "Creating mean MD"
if [ ! -e "stats/mean_MD.nii.gz" ] && [ ! -z "$compute_MD" ]; then $FSLDIR/bin/fslmaths stats/all_MD -Tmean stats/mean_MD; fi

echo "Creating mean RD"
if [ ! -e "stats/mean_RD.nii.gz" ] && [ ! -z "$compute_RD" ]; then $FSLDIR/bin/fslmaths stats/all_RD -Tmean stats/mean_RD; fi

echo "Skeletonising mean FA"
if [ ! -e "stats/mean_FA_skeleton.nii.gz" ]; then $FSLDIR/bin/tbss_skeleton -i stats/mean_FA -o stats/mean_FA_skeleton; fi

