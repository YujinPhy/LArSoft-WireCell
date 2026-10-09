#!/bin/sh

# If you want to run the script without sourcing the dune environment, uncomment the following lines.
#source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh
#setup  dunesw v10_10_02d00 -q e26:prof     # choos e the appropriate version of DUNE software

# If needed, add your wire-cell-cfg and wire-cell-toolkit install paths to the environment variables below. Uncomment and modify the following lines as necessary. 
# export WIRECELL_PATH=/nfs/data/1/yujin/wire-cell-cfg_xning:$WIRECELL_PATH
# export LD_LIBRARY_PATH=/exp/dune/data/users/xning/img_test/wire-cell/wire-cell-toolkit/install/lib/:$LD_LIBRARY_PATH
# export LD_LIBRARY_PATH=/exp/dune/app/users/hnam/opt/lib:$LD_LIBRARY_PATH
# export LD_LIBRARY_PATH=/exp/dune/data/users/xning/proto-dune-vd/wire-cell-toolkit/install/lib/:$LD_LIBRARY_PATH


RAW_DATA=/nfs/data/1/yujin/pdhd_data/raw/np04hd_raw_run026763_0008_dataflow0_datawriter_0_20240607T071013.hdf5

STAGE1_PROCESSED=/nfs/data/1/yujin/LArSoft-WireCell/results/pdhd_img/np04hd_raw_run026763_0008_dataflow0_datawriter_0_20240607T071013_reco_stage1.root

# ==== fcl files ====
# Stage 1 reco fcl files
STAGE1_FCL=/nfs/data/1/yujin/LArSoft-WireCell/fcl_data/standard_reco_stage1_protodunehd_keepup.fcl

# Stage 2 reco fcl files
STAGE2_FCL=/nfs/data/1/yujin/LArSoft-WireCell/fcl_data/standard_reco_stage2_calibration_protodunehd_keepup_img.fcl      # NF + Traditional SP + Img


# Run LArSoft
# lar -n1 --nskip 0 -c $STAGE1_FCL -s $RAW_DATA 
# lar -n1 --nskip 0 -c $STAGE2_FCL -s $STAGE1_PROCESSED


# Convert larsoft result to bee display and upload to bee

export PYTHONPATH="/nfs/data/1/yujin/wire-cell-python/venv/lib/python3.11/site-packages:/nfs/data/1/yujin/wire-cell-python"
source /nfs/data/1/yujin/wire-cell-python/venv/bin/activate

IMG_2_BEE=/nfs/data/1/yujin/LArSoft-WireCell/utils/wct-img-2-bee-hd.py
UPLOAD_SCRIPT=/nfs/data/1/yujin/LArSoft-WireCell/utils/upload-to-bee.sh

# python $IMG_2_BEE clusters-apa-apa0-ms-active.tar.gz clusters-apa-apa1-ms-active.tar.gz clusters-apa-apa2-ms-active.tar.gz clusters-apa-apa3-ms-active.tar.gz

deactivate

zip -r upload data
$UPLOAD_SCRIPT upload.zip




