#!/bin/sh

# ==== LArSoft Commands ====
lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/gen/gen_protodunehd_muon_1GeV_dp5_apa2.fcl -o gen.root
lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/g4/standard_g4_protodunehd.fcl -s gen.root -o g4.root
lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/detsim_reco/standard_detsim_protodunehd.fcl -s g4.root -o detsim.root 
lar -n1 -c /nfs/data/1/yujin/LArSoft-WireCell/fcl_sim/detsim_reco/standard_reco_protodunehd_MC.fcl -s detsim.root -o reco.root

