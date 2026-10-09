#!/bin/sh



INPUT_DATA=/nfs/data/1/yujin/pdvd_data/np02vd_raw_run039350_6143_df-s04-d1_dw_0_20250914T174641.hdf5

# Fcl file path for the reconstruction
# FCL_PATH=/nfs/data/1/yujin/larfcl/data/standard_reco_pdvd_offline_nodnnroi.fcl # WC tradiantional SP

FCL_PATH=/nfs/data/1/yujin/larfcl/data/standard_reco_pdvd_offline.fcl # WC DNN SP
lar -n1 -c $FCL_PATH -s $INPUT_DATA 

/nfs/data/1/yujin/wire-cell-toolkit/cfg/pgrapher/experiment/protodunevd/wcls-nf-sp.jsonnet









listfile=filelist_jay.txt

#source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh

#setup  dunesw v10_10_02d00 -q e26:prof


export WIRECELL_PATH=/nfs/data/1/yujin/wire-cell-cfg_xning:$WIRECELL_PATH
# export LD_LIBRARY_PATH=/exp/dune/data/users/xning/img_test/wire-cell/wire-cell-toolkit/install/lib/:$LD_LIBRARY_PATH
# export LD_LIBRARY_PATH=/exp/dune/app/users/hnam/opt/lib:$LD_LIBRARY_PATH
# export LD_LIBRARY_PATH=/exp/dune/data/users/xning/proto-dune-vd/wire-cell-toolkit/install/lib/:$LD_LIBRARY_PATH



#cat $listfile | while read line
#do
#    filename=$line
#

# larsoft command
#lar -n 1 --nskip 0 -c standard_reco_pdvdimg_offline.fcl $filename
lar -n 1 --nskip 0 -c standard_reco_pdvdimg_offline.fcl -s np02vd_raw_run039324_0647_df-s04-d0_dw_0_20250906T042806_reco_stage1_20250909T102859_keepup.root


#convert larsoft result to bee display

export PYTHONPATH="/nfs/data/1/yujin/wire-cell-python/venv/lib/python3.11/site-packages:/nfs/data/1/yujin/wire-cell-python"
source /nfs/data/1/yujin/wire-cell-python/venv/bin/activate

python wct-img-2-bee.py clusters-apa-anode0.tar.gz clusters-apa-anode1.tar.gz clusters-apa-anode2.tar.gz clusters-apa-anode3.tar.gz clusters-apa-anode4.tar.gz clusters-apa-anode5.tar.gz clusters-apa-anode6.tar.gz clusters-apa-anode7.tar.gz

#python ./wct-img-2-bee.py clusters-apa-anode0-ms-active.tar.gz clusters-apa-anode1-ms-active.tar.gz clusters-apa-anode2-ms-active.tar.gz clusters-apa-anode3-ms-active.tar.gz clusters-apa-anode4-ms-active.tar.gz clusters-apa-anode5-ms-active.tar.gz clusters-apa-anode6-ms-active.tar.gz clusters-apa-anode7-ms-active.tar.gz
#python ../wct-img-2-bee_only.py clusters-apa-anode0-ms-active.tar.gz 

deactivate

zip -r upload data

./upload-to-bee.sh upload.zip



#break
#done

