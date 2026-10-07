# Runnging Wire-Cell in LArSoft: ProtoDUNE-HD and ProtoDUNE-VD

In this document, the standard WireCell processing pipelines are summarized.

## Environment

To set up the environment, refer to [01_setup.md](01_setup.md).

All file paths in this document are relative to the project root (`LArSoft-WireCell/`), unless they start with `/`.

- e.g. `fcl_sim/gen/prod_cosmics_protodunehd.fcl` = `<project root>/fcl_sim/gen/prod_cosmics_protodunehd.fcl`
- Paths starting with `/` (e.g. `/nfs/data/1/yujin/wire-cell-python/...`) are absolute and point outside the project.

## `lar` Command

### (a) Options

| Option | Description | Example |
|---|---|---|
| `-c <fcl>` | Configuration fcl file to run (searched in `FHICL_FILE_PATH`) | `-c standard_g4_protodunehd.fcl` |
| `-s <file>` | Input ROOT file (not used for generator stage) | `-s gen.root` |
| `-o <file>` | Output ROOT file name; overrides `outputs.out1.fileName` in the fcl | `-o g4.root` |
| `-n <N>` | Number of events to process; overrides `source.maxEvents` in the fcl | `-n1` |
| `--nskip <N>` | Skip the first N events of the input file, then start processing | `--nskip 3 -n1` (4th event only) |

### (b) Helpers: inspecting FHiCL and art/ROOT files

Read-only tools shipped with `dunesw` (none of them modify the input).
Checked with `dunesw v10_26_00d01` (2026-10-05).

| Tool | Type | Inspects | Input |
|---|---|---|---|
| `fhicl-dump` | executable (`fhiclcpp`) | Final configuration of a FHiCL file | `.fcl` |
| `config_dumper` | executable (`art_root_io`) | Configuration stored in a file by the jobs that produced it | art/ROOT file |
| `eventdump.fcl` | fcl (`lardata`) | List of data products per event | art/ROOT file |
| `file_info_dumper` | executable (`art_root_io`) | Run/subrun/event list, process history | art/ROOT file |
| `count_events` | executable (`art_root_io`) | Number of runs/subruns/events | art/ROOT file |
| `product_sizes_dumper` | executable (`art_root_io`) | Disk size per data product | art/ROOT file |
| `dump_*.fcl` | fcl (`lardata`, `larsim`) | Content of one data product type | art/ROOT file |

#### Configuration: `fhicl-dump`, `config_dumper`

`fhicl-dump` resolves every `#include` and `@local::` and prints the configuration `lar` would actually run.
Useful to check which `wirecell_dune.fcl` block or jsonnet a detsim/reco fcl ends up with.

```bash
fhicl-dump -c fcl_sim/detsim_reco/standard_detsim_protodunehd.fcl          # print to STDOUT
fhicl-dump -c fcl_sim/detsim_reco/standard_detsim_protodunehd.fcl -a       # annotate each value with its source file:line
fhicl-dump -c fcl_sim/detsim_reco/standard_detsim_protodunehd.fcl -o out.fcl
```

`config_dumper` prints the configuration stored inside an art/ROOT file, i.e. what was actually used to produce it.

```bash
config_dumper -P detsim.root                       # process-level configuration
config_dumper -M -f tpcrawdecoder detsim.root      # one module by label
config_dumper -S detsim.root                       # services
```

#### File contents: `eventdump.fcl`, `file_info_dumper`, `count_events`, `product_sizes_dumper`

`eventdump.fcl` prints the list of data products stored in each event.

```bash
lar -n1 -c eventdump.fcl -s g4_detsim_reco.root
```

| Column | Meaning |
|---|---|
| `PROCESS NAME` | `process_name` of the stage that made the product (`SinglesGen`, `G4`, `Detsim`, `Reco`, ...) |
| `MODULE LABEL` | Producer label in that fcl (`largeant`, `tpcrawdecoder`, `wclsdatahd`, ...) |
| `PRODUCT INSTANCE NAME` | Instance name (`daq`, `simpleSC`, `gauss`, `wiener`, ...) |
| `DATA PRODUCT TYPE` | C++ type (`std::vector<raw::RawDigit>`, `std::vector<recob::Wire>`, ...) |
| `SIZE` | Number of elements (`?` = dropped/not present, `-` = not a collection) |

The other three run directly on the file, without `lar`:

```bash
file_info_dumper --event-list detsim.root          # run/subrun/event numbers
file_info_dumper --process-history detsim.root     # processes that produced the file, in order
count_events --hr detsim.root                      # number of events
product_sizes_dumper detsim.root                   # disk size per product
```

#### Product contents: `dump_*.fcl`

Each `dump_*.fcl` prints the content of one product type (e.g. ADC values per channel).
The input label is a module parameter, and the output goes to a **log file**, not to the terminal.

| fcl | Product | Input parameter (default) | Log file |
|---|---|---|---|
| `dump_rawdigits.fcl` | `raw::RawDigit` | `DetSimModuleLabel` (`daq`) | `DumpRawDigits.log` |
| `dump_wires.fcl` | `recob::Wire` | `CalWireModuleLabel` (`caldata`) | `DumpWires.log` |
| `dump_simchannels.fcl` | `sim::SimChannel` | `InputSimChannels` (`largeant`) | `DumpSimChannels.log` |
| `dump_hits.fcl` | `recob::Hit` | `HitModuleLabel` (`gaushit`) | `DumpHits.log` |
| `dump_mctruth.fcl` | `simb::MCTruth` | | `DumpMCTruth.log` |

Others: `dump_mcparticles.fcl`, `dump_simphotons.fcl`, `dump_tracks.fcl`, `dump_clusters.fcl`, ... (`lardata/.../job/`, `larsim/.../job/`).

The defaults rarely match the ProtoDUNE labels (`tpcrawdecoder:daq`, `wclsdatahd:gauss`, ...), so override them in a small wrapper fcl:

```
#include "dump_rawdigits.fcl"
physics.analyzers.dumpdigits.DetSimModuleLabel: "tpcrawdecoder:daq"
```

```bash
lar -n1 -c my_dump_rawdigits.fcl -s detsim.root    # -> DumpRawDigits.log
```


## 2. Simulations

### (a) Standard pipeline

```
Gen -> G4 -> Detector Sim/Reco
```

| Stage | Role | Main products |
|---|---|---|
| Gen | Primary particles (`EmptyEvent` source): CORSIKA cosmics, single-particle gun, radiologicals | `simb::MCTruth` |
| G4 | Particle propagation in LAr, ionization/scintillation (`largeant`, `IonAndScint`) | `sim::SimEnergyDeposit` |
| Detector Sim | drift + field response + electronics + noise (`tpcrawdecoder` = `WireCellToolkit` module) | `raw::RawDigit`, `sim::SimChannel` |
| Reco | WCT NF + SP (`wclsdatahd`), then hit finding / Pandora | `recob::Wire` (`gauss`, `wiener`) |

Each stage is a separate `lar` call chained by file:

```bash
lar -n1 -c <gen.fcl>    -o gen.root
lar -n1 -c <g4.fcl>     -s gen.root -o g4.root
lar -n1 -c <detsim.fcl> -s g4.root -o detsim.root        
lar -n1 -c <reco.fcl>   -s g4_detsim.root -o reco.root   # The reco stage could be integrated into the `detsim` stage.
```

### (b) `fcl` file for simulations (`fcl_sim/`)

| Stage | PDHD | PDVD | Notes |
|---|---|---|---|
| Gen (cosmics) | `fcl_sim/gen/prod_cosmics_protodunehd.fcl` | `fcl_sim/gen/gen_protodunevd_cosmics_radio.fcl` | Cosmic rays + radiologicals |
| Gen (single $e^-$) | `fcl_sim/gen/gen_protodunehd_electron_1GeV_dp5.fcl` | `fcl_sim/gen/gen_protodunevd_electron_1GeV.fcl` | Single electron gun |
| Gen (single $\mu^-$) | `fcl_sim/gen/gen_protodunehd_muon_1GeV_dp5_apa2.fcl` | `fcl_sim/gen/gen_protodunevd_muon_1GeV.fcl` | Single muon gun |
| G4 | `fcl_sim/g4/standard_g4_protodunehd.fcl` | `fcl_sim/g4/protodunevd_refactored_g4_stage1.fcl` -> `fcl_sim/g4/protodunevd_refactored_g4_stage2.fcl` | Particle propagation, ionization/scintillation |
| DetSim + WCT | `fcl_sim/detsim_reco/standard_detsim_protodunehd.fcl` -> `fcl_sim/detsim_reco/standard_reco_protodunehd_MC.fcl` | `fcl_sim/detsim_reco/protodunevd_detsim.fcl` | Drift + field response + electronics + noise + WireCell processing |

#### PDHD Example pipeline (Single muon sim up to WCT nf + sp):

```bash
lar -n1 -c fcl_sim/gen/gen_protodunehd_muon_1GeV_dp5_apa2.fcl -o gen.root
lar -n1 -c fcl_sim/g4/standard_g4_protodunehd.fcl -s gen.root -o g4.root
lar -n1 -c fcl_sim/detsim_reco/standard_detsim_protodunehd.fcl -s g4.root -o detsim.root 
lar -n1 -c fcl_sim/detsim_reco/standard_reco_protodunehd_MC.fcl -s detsim.root -o reco.root
```

#### PDVD Example pipeline

```bash

```



## 3. Real Data Processing

The input data is usually given in `.h5` format. Then just run reco stage `.fcl`s.

### PDHD

### PDVD

#### Traditional sigproc pipeline
- `fcl_data/standard_reco_pdvd_offline_nodnnroi.fcl`
    - Load `protodunevd_nfsp` in `wirecell_dune.fcl`.
    - This use `pgrapher/experiment/protodunevd/wcls-nf-sp.jsonnet` cfg file.

#### DNN sigproc pipeline
- `fcl_data/standard_reco_pdvd_offline.fcl`
    - Load `protodunevd_nfsp_dnnroi` in `wirecell_dune.fcl`.
    - This use `pgrapher/experiment/protodunevd/wcls-nf-sp-dnnroi.jsonnet` cfg file.

## 4. `wirecell-dune.fcl`

#### PDHD

| Reality | `fcl` file | Module Name in `wirecell-dune.fcl` | Related WCT configuration | Notes | Pipeline scripts |
|---|---|---|---|---|---|
| sim |`fcl_sim/detsim_reco/standard_reco_protodunehd_MC.fcl` | `protodunehd_nfsp` | `pgrapher/experiment/pdhd/wcls-nf-sp.jsonnet` | nfsp | `pipline_scirpts/larwc_pdhd_sim_nfsp.sh` |

#### PDVD  

| Reality | `fcl` file | Module Name in `wirecell-dune.fcl` | Related WCT configuration | Notes | Pipeline scripts |
|---|---|---|---|---|---|
| sim |`fcl_sim/detsim_reco/pdvd_wirecell_sim_nfsp.fcl` | `protodunevd_nfsp` | `pgrapher/experiment/protodunevd/wcls-nf-sp.jsonnet` | nfsp | `pipline_scirpts/larwc_pdvd_sim_nfsp.sh` |
| sim |`fcl_sim/detsim_reco/pdvd_wirecell_sim_deposplat.fcl` | `wirecell_protodunevd_sim_deposplat` | `pgrapher/experiment/protodunevd/wcls-sim-drift-deposplat.jsonnet` | nfsp+dnnroi | - |


## 5. Util Scripts
| File Path | Description | Command |
|---|---|---|
| `cleanup.sh` | Removes `lar` outputs (`*root`, `*log`, `*db`, `*pndr`, `*h5`) in the current directory | `./cleanup.sh` |
| `findfcl.sh` | Finds where an fcl file is located in `FHICL_FILE_PATH` | `./findfcl.sh wirecell_dune.fcl` |

