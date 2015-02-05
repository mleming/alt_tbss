AltTBSS
============

This script uses the FSL library, developed by the FMRIB at Oxford,
to create an alternate TBSS (Tract-Based Spatial Statistics) framework.
The goal of this framework is to greater use of directional DTI data in
the TBSS pipeline while making it as user-friendly as possible.

(Note: this explanation requires some familiarity with TBSS and DTI measurements)

This pipeline takes in a number of skull-stripped DTI datasets, then uses
the ANTS-SyN algorithm in DTIAtlasBuilder to register these subjects to the
same space. It then takes the resulting .nrrd DTI images, converts them to
FSL format, and estimates the FA, AD, MD, and RD of each of these images.
A Gaussian filter is then applied to each of these; when projecting onto
the white matter skeleton (see http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/TBSS/UserGuide),
this tool uses the projection vectors given by the unblurred FA images, but the values
given by the gaussian blurred images. There are, thus, three main changes in between
this pipeline and the classic TBSS: the registration method, the automatic
estimation and use of more measurements of FA, and the values projected onto
the final white matter skeleton.

This is still a work in progress. Please report any errors to matthew.j.leming at gmail dot com

Setup
-----------

This script runs on a scientific Linux machine and requires that the FSL
Library is installed and working, as well as DTIAtlasBuilder and its required
software.

 * FSL: http://fsl.fmrib.ox.ac.uk/fsldownloads/fsldownloadmain.html
 * DTIAtlasBuilder: http://www.nitrc.org/frs/?group_id=636

DTIAtlasBuilder requires the following to be installed:

 * ImageMath
 * ResampleDTIlogEuclidean
 * CropDTI
 * dtiprocess
 * BRAINSFit
 * GreedyAtlas
 * dtiaverage
 * DTI-Reg
 * MriWatcher
 * unu

Installation
-------------

This software is mostly bash scripts, so put the folder alt_tbss in your path or
execute each script sequentially:

    cd <data_folder>
    alt_tbss_1.sh
    alt_tbss_2.sh
    alt_tbss_3.sh


Running it
-------------

Once all of the above software is installed, do the following:

 1. Add, in the file DTIAtlasBuilderSoftConfig.txt, the paths of all of the executables for all installed programs
 2. Insert all of your skull-stripped DTI data, in .nrrd format, into a folder
 3. In a terminal, cd to that folder

    cd /path/to/data/folder

 4. Run the first script

    bash /path/to/alt_tbss_1.sh

 5. After this, run alt_tbss_2.sh and alt_tbss_3.sh sequentially, checking for errors in data in between runs.

 6. For display options and other information, see: http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/TBSS/UserGuide

 7. alt_tbss_2.sh gives information about greating the files that separate each group. It will automatically generate a blank CSV with each subject name, which you may edit to separate them.
