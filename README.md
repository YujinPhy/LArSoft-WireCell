# LArSoft-WireCell

FHiCL/Jsonnet configurations and shell pipelines for running the Wire-Cell Toolkit (WCT) inside LArSoft (`dunesw`) for ProtoDUNE-HD (PDHD) and ProtoDUNE-VD (PDVD).
Covers both simulation (Gen -> G4 -> DetSim -> WCT NF/SP) and real-data reconstruction (`.hdf5` raw -> WCT NF/SP/DNN-ROI/imaging -> Bee display).

Tested with `dunesw v10_26_00d01` (`e26:prof`) in the SL7 container on `wcgpu1`.

## Related references
- 2024 WCT summit: https://indico.bnl.gov/event/21492/
- For some specific concepts: https://www.phy.bnl.gov/~bviren/wire-cell/docs/
- https://indico.bnl.gov/event/21492/contributions/86835/attachments/53789/92010/toolkit.pdf
- https://www.phy.bnl.gov/~bviren/talks/wire-cell/topics/config/config.pdf


### Tutorials for the BNL WireCell group
| Contents | Links | Hands-On |
|---|---|---|
| Basic/SigProc | https://hackmd.io/@HaiwangYu/ry4aZv9l5 | Basic Dev Setup for WCT, Compiling and Debugging |
| PD-HD sim and dataproc | https://docs.google.com/document/d/1oNks017VsIirl3cR5RBfRew3xSz1GGs19fZnEfQEjGg/edit?tab=t.0#heading=h.ri6d4un44yqv | LarWC Simulation and Data Processing |
| DNN SigProc | https://docs.google.com/document/d/1NDr3G70T4uKac8D0xa5tijS96EGndLhSU3hYTH-7DVM/edit?tab=t.0#heading=h.s41y26sr2b3s | DNN ROI SP |
| Hokyeong's SP Tutorial | https://docs.google.com/document/d/1BhIoJsJN32LHJFUiSGQT3O4ibWF33XDm3bbFwyeuy24/edit?tab=t.0 | DNN ROI SP|
| 2025 PDHD Imaging | https://docs.google.com/document/d/1nCg2Tsz-khUpH-FNou14MZoLuRVj0r9xOLVjeDJEMvA/edit?tab=t.0#heading=h.tfookkook54l | WCT 3D Imaging and Clustering                                                          |
| 2026 Img(PDHD&PDVD) | https://docs.google.com/document/d/1Z1mSnsfBWEsmYTXTJR7GWMJk_wGmjgATjuewVnRaIcY/edit?tab=t.0#heading=h.h5ljvejct3sw | WCT 3D Imaging and Clustering |


## Directory Structure
```
LArSoft-WireCell/
├── wirecell_dune.fcl            # Local copy of dunereco's wirecell_dune.fcl (overrides CVMFS)
├── wirecell_dune_modified.fcl   # For user modified configurations
├── docs/
│   ├── 01_setup.md              # SL7 container, `setup dunesw`, search-path variables
│   └── 02_larwc.md              # `lar` usage, inspection tools, sim/data pipelines, fcl tables
├── fcl_sim/                     # Simulation configurations
│   ├── gen/                     
│   ├── g4/                      
│   └── detsim_reco/             
├── fcl_data/                    # Real-data configurations
│   ├── standard_reco_stage1_protodunehd_keepup.fcl
│   ├── standard_reco_stage2_calibration_protodunehd_keepup{,_dnnroi,_img}.fcl
│   └── standard_reco_pdvd_offline{,_nodnnroi}.fcl
├── pipline_scripts/             # End-to-end shell pipelines (sim and data/ PDHD and PDVD)
└── utils/                       # Helper scripts
```

## Documentation
- [docs/01_setup.md](docs/01_setup.md): environment setup and search-path variables (`WIRECELL_PATH`, `FHICL_FILE_PATH`, `LD_LIBRARY_PATH`, `FW_SEARCH_PATH`)
- [docs/02_larwc.md](docs/02_larwc.md): `lar` options, FHiCL/ROOT inspection tools, simulation and data pipelines, `wirecell_dune.fcl` block mapping