#!/bin/bash

help=`echo $@ | grep "\(--help\|-h\)"`
gaussian=`echo $@ | grep "\(--nogaussian\|-g\)"`
if [ ! -z "$help" ]
then
	echo "alt_tbss_3.sh <thresh>"
	echo "This script will estimate a white matter skeleton from FA and then:"
	echo "Project the FA, RD, AD, and MD results onto it; the projection vectors"
	echo "are determined by the unblurred images and the values are determined by"
	echo "the Gaussian-filtered image"
	echo "Usage:"
	echo "-h, --help: Display this message"
	echo "--nogaussian: Do not use the Gaussian-blurred image sets. If this is not set,"
	echo "              the Gaussians will be used if they are present. Otherwise, they won't be."
	exit
fi


thresh=0.2

echo "creating skeleton mask using threshold $thresh"
#echo $thresh > thresh.txt
if [ ! -e "stats/mean_FA_skeleton_mask.nii.gz" ]; then ${FSLDIR}/bin/fslmaths stats/mean_FA_skeleton -thr $thresh -bin stats/mean_FA_skeleton_mask; fi

echo "creating skeleton distancemap (for use in projection search)"
if [ ! -e "stats/mean_FA_skeleton_mask_dst.nii.gz" ];
then
	${FSLDIR}/bin/fslmaths stats/mean_FA_mask -mul -1 -add 1 -add stats/mean_FA_skeleton_mask stats/mean_FA_skeleton_mask_dst
	${FSLDIR}/bin/distancemap -i stats/mean_FA_skeleton_mask_dst -o stats/mean_FA_skeleton_mask_dst
fi

echo "projecting all FA data onto skeleton"
if [ ! -e "stats/all_FA_skeletonised.nii.gz" ]
then
	echo "A"
	if [ ! -z "$nogaussian" ] || [ -e "stats/all_FA_gaussian.nii.gz" ]
		${FSLDIR}/bin/tbss_skeleton -i stats/mean_FA -p $thresh stats/mean_FA_skeleton_mask_dst ${FSLDIR}/data/standard/LowerCingulum_1mm stats/all_FA stats/all_FA_skeletonised
	then	
		${FSLDIR}/bin/tbss_skeleton -i stats/mean_FA -p $thresh stats/mean_FA_skeleton_mask_dst ${FSLDIR}/data/standard/LowerCingulum_1mm stats/all_FA stats/all_FA_skeletonised -a stats/all_FA_gaussian
	fi
fi

echo "projecting all AD data onto skeleton"
if [ ! -e "stats/all_AD_skeletonised.nii.gz" ]
then
	echo "B"
	if [ ! -z "$nogaussian" ] || [ -e "stats/all_AD_gaussian.nii.gz" ]
	then
		${FSLDIR}/bin/tbss_skeleton -i stats/mean_AD -p $thresh stats/mean_FA_skeleton_mask_dst ${FSLDIR}/data/standard/LowerCingulum_1mm stats/all_FA stats/all_AD_skeletonised -a stats/all_AD
	else
		${FSLDIR}/bin/tbss_skeleton -i stats/mean_AD -p $thresh stats/mean_FA_skeleton_mask_dst ${FSLDIR}/data/standard/LowerCingulum_1mm stats/all_FA stats/all_AD_skeletonised -a stats/all_AD_gaussian
	fi
fi

echo "projecting all MD data onto skeleton"
if [ ! -e "stats/all_MD_skeletonised.nii.gz" ]
then
		echo "C"
	if [ ! -z "$nogaussian" ] || [ -e "stats/all_MD_gaussian.nii.gz" ]
	then
		${FSLDIR}/bin/tbss_skeleton -i stats/mean_MD -p $thresh stats/mean_FA_skeleton_mask_dst ${FSLDIR}/data/standard/LowerCingulum_1mm stats/all_FA stats/all_MD_skeletonised -a stats/all_MD
	else
		${FSLDIR}/bin/tbss_skeleton -i stats/mean_MD -p $thresh stats/mean_FA_skeleton_mask_dst ${FSLDIR}/data/standard/LowerCingulum_1mm stats/all_FA stats/all_MD_skeletonised -a stats/all_MD_gaussian
	fi
fi

echo "projecting all RD data onto skeleton"
if [ ! -e "stats/all_RD_skeletonised.nii.gz" ]
then
	if [ ! -z "$nogaussian" ] || [ -e "stats/all_RD_gaussian.nii.gz" ]
	then
		${FSLDIR}/bin/tbss_skeleton -i stats/mean_RD -p $thresh stats/mean_FA_skeleton_mask_dst ${FSLDIR}/data/standard/LowerCingulum_1mm stats/all_FA stats/all_RD_skeletonised -a stats/all_RD
	else
		${FSLDIR}/bin/tbss_skeleton -i stats/mean_RD -p $thresh stats/mean_FA_skeleton_mask_dst ${FSLDIR}/data/standard/LowerCingulum_1mm stats/all_FA stats/all_RD_skeletonised -a stats/all_RD_gaussian
	fi
fi

