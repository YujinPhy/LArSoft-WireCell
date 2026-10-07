#!/bin/sh

# larsoft commands
# lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/gen/gen_protodunehd_muon_1GeV_dp5_apa2.fcl -o gen.root
lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/gen/prod_cosmics_protodunehd.fcl -o gen.root
lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/g4/standard_g4_protodunehd.fcl -s gen.root -o g4.root
lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/pdhd_wirecell_sim_nf_sp_img.fcl -s g4.root 

#convert larsoft result to bee display
export PYTHONPATH="/nfs/data/1/yujin/wire-cell-python/venv/lib/python3.11/site-packages:/nfs/data/1/yujin/wire-cell-python"
source /nfs/data/1/yujin/wire-cell-python/venv/bin/activate

# python wct-img-2-bee-hd.py clusters-apa-apa0-ms-active.tar.gz clusters-apa-apa1-ms-active.tar.gz clusters-apa-apa2-ms-active.tar.gz clusters-apa-apa3-ms-active.tar.gz
python /nfs/data/1/yujin/img_test/pdhd/wct-img-2-bee-hd.py clusters-apa-apa0.tar.gz clusters-apa-apa1.tar.gz clusters-apa-apa2.tar.gz clusters-apa-apa3.tar.gz
deactivate

zip -r upload data

source /nfs/data/1/yujin/img_test/pdhd/upload-to-bee.sh upload.zip