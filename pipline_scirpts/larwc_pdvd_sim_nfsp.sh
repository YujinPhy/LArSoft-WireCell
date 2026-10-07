#!/bin/sh

# ==== LArSoft Commands ====
lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/gen/gen_protodunevd_muon_override.fcl -o gen.root
lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/g4/protodunevd_refactored_g4_stage1.fcl -s gen.root -o g4_stage1.root
lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/g4/protodunevd_refactored_g4_stage2.fcl -s g4_stage1.root -o g4_stage2.root
lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/detsim_reco/pdvd_wirecell_sim_deposplat.fcl -s g4_stage2.root -o detsim.root

# ==== Command for Wire-Cell 3D Imaging/Clustering ====
#convert larsoft result to bee display
# export PYTHONPATH="/nfs/data/1/yujin/wire-cell-python/venv/lib/python3.11/site-packages:/nfs/data/1/yujin/wire-cell-python"
# source /nfs/data/1/yujin/wire-cell-python/venv/bin/activate

# python wct-img-2-bee-hd.py clusters-apa-apa0-ms-active.tar.gz clusters-apa-apa1-ms-active.tar.gz clusters-apa-apa2-ms-active.tar.gz clusters-apa-apa3-ms-active.tar.gz
# python /nfs/data/1/yujin/img_test/pdhd/wct-img-2-bee-hd.py clusters-apa-apa0.tar.gz clusters-apa-apa1.tar.gz clusters-apa-apa2.tar.gz clusters-apa-apa3.tar.gz
# deactivate

# zip -r upload data

# source /nfs/data/1/yujin/img_test/pdhd/upload-to-bee.sh upload.zip