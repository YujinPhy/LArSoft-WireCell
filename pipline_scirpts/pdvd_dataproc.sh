INPUT_DATA=/nfs/data/1/yujin/pdvd_data/np02vd_raw_run039350_6143_df-s04-d1_dw_0_20250914T174641.hdf5

# Fcl file path for the reconstruction
# FCL_PATH=/nfs/data/1/yujin/larfcl/data/standard_reco_pdvd_offline_nodnnroi.fcl # WC tradiantional SP

FCL_PATH=/nfs/data/1/yujin/larfcl/data/standard_reco_pdvd_offline.fcl # WC DNN SP
lar -n1 -c $FCL_PATH -s $INPUT_DATA 

/nfs/data/1/yujin/wire-cell-toolkit/cfg/pgrapher/experiment/protodunevd/wcls-nf-sp.jsonnet