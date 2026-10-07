export FCL_PATH=/nfs/data/1/yujin/LArSoft-WireCell/fcl_data/standard_reco_stage2_calibration_protodunehd_keepup.fcl
export INPUT_DATA=/nfs/data/1/yujin/pdhd_data/Run026763/event_225/np04hd_raw_run026763_0008_dataflow0_datawriter_0_20240607T071013_reco_stage1.root

lar -n1 -c $FCL_PATH -s $INPUT_DATA 

