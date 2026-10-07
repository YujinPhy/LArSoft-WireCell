# Setup: LArSoft + Wire-Cell Environment

How to set up the environment that runs the `LArSoft` and `Wire-Cell-Tollkit`.
The detail implementations are in [running_larwc.md](02_larwc.md), and here, only setup methods are described.

## 1. Procedures

DUNE is gradually transferring to use AL9 and spack, but we are not fully prepared for this

### (a) Enter SL7 container

In `dunegpvmXX`, 
```bash
/cvmfs/oasis.opensciencegrid.org/mis/apptainer/current/bin/apptainer shell --shell=/bin/bash -B /cvmfs,/exp,/nashome,/pnfs/dune,/opt,/run/user,/etc/hostname,/etc/hosts,/etc/krb5.conf --ipc --pid /cvmfs/singularity.opensciencegrid.org/fermilab/fnal-dev-sl7:latest && source .bashrc
```

In `wcgpu`,
```bash
wcwc container --image sl7
```

You can register this command as an alias, like `dune_sl7`.

### (b) Setup `dunesw`

In the SL7 container,
```bash
source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh

export DUNELAR_VERSION=v10_26_00d01
export DUNELAR_QUALIFIER=e26:prof

setup dunesw ${DUNELAR_VERSION} -q ${DUNELAR_QUALIFIER}
```

Use proper version and qualifier.



### (b) Environment variables

All four are colon-separated search paths, scanned from left to right; the **first match wins**.
`setup dunesw` fills them with CVMFS entries, so a local file or build takes effect only when its directory is **prepended**:

```bash
export WIRECELL_PATH=<local dir>:$WIRECELL_PATH     # not appended
```

Values below were checked inside the SL7 container right after `setup dunesw v10_26_00d01 -q e26:prof` (2026-10-05).

#### `WIRECELL_PATH`
- To use your own Wire-Cell configuration files
- Searched by WCT for every file named by a relative path:
  - jsonnet configs, e.g. `configs: ["pgrapher/experiment/pdhd/wcls-nf-sp.jsonnet"]` in `wirecell_dune.fcl`
  - data files such as wire geometry and field response (`*.json.bz2`)
- Default (3 entries):

  | Order | Entry | Content |
  |---|---|---|
  | 1 | `.../dune/dunereco/v10_26_00d01/wire-cell-cfg` | DUNE-shipped `cfg` (`pgrapher/experiment/*`) |
  | 2 | `.../larsoft/wirecell/v0_37_1/.../share/wirecell` | WCT release `cfg` |
  | 3 | `.../dune/dune_pardata/v01_84_00/WireCellData` | wires, field response, noise spectra (`*.json.bz2`) |

- Prepend a local `wire-cell-toolkit/cfg` (or `wire-cell-cfg`) checkout to make modified jsonnet files shadow entry 1.
- Data files are still found in entry 3, so only the `cfg` directory needs to be added.

#### `FHICL_FILE_PATH`
- To find examples of FHiCL files
- Searched by `lar -c <fcl>` and by every `#include "<fcl>"` inside a FHiCL file.
- Default: 37 entries, starting with `.` and `./job`, followed by the `fcl/` (or `job/`) directory of each UPS product (`dunesw`, `dunereco`, `protoduneana`, ...).
- Because `.` is included, `lar -c fcl_sim/gen/<file>.fcl` resolves relative to the current directory.
- Lookup is **not recursive**: each entry is checked only for `<entry>/<requested name>`, and subdirectories are not scanned.
  - With the project root in `FHICL_FILE_PATH`, `lar -c gen_protodunevd_muon_override.fcl` fails (the file is in `fcl_sim/gen/`), while `lar -c fcl_sim/gen/gen_protodunevd_muon_override.fcl` works from any directory.
  - A file pulled in by name only (e.g. `#include "wirecell_dune.fcl"`) must sit directly in a registered directory; to call files by name only, register each subdirectory (`fcl_sim/gen`, `fcl_sim/g4`, ...) separately.

#### `LD_LIBRARY_PATH`
- To use executable you newly built
- Searched by the dynamic linker for shared libraries, including the WCT plugins loaded at run time.
  - Each name in `plugins: [...]` of `wirecell_dune.fcl` (e.g. `WireCellGen`, `WireCellSigProc`) is loaded as `lib<name>.so`.
- Prepend the local WCT install `lib` directory (e.g. `$WORKDIR/opt/lib`) to load a newly built WCT instead.
  - Only libraries are affected. The `wire-cell` executable still comes from CVMFS unless the local `bin` is also prepended to `PATH`. The CVMFS binary loads the local libraries anyway, since its `RPATH` points at build-server paths that do not exist here (checked with `ldd`).
  - The local build must be compiled against the same `dunesw` stack (compiler `e26`, same external versions); a mismatch shows up as unresolved symbols at load time.

#### `FW_SEARCH_PATH`
- Useful for some cases
- Searched by `art`/LArSoft services for auxiliary files named in FHiCL that are neither FHiCL nor shared libraries: GDML geometry, photon libraries, channel maps, field response files for non-WCT code, etc.
- Default: 45 entries, e.g. `.../dunesim/v10_26_00d01/gdml`, `.../duneprototypes/v10_26_00d01/config_data`, `.../dune_pardata/v01_84_00/PhotonPropagation`.
- Not modified by the standard WCT setup.




## Caveats / ToDo

- `wire-cell` on `PATH` is the CVMFS binary; the local build is only picked up through `LD_LIBRARY_PATH`.
- `WARNING: group: unknown groupid 95471` at container start is harmless.

### Non-interactive use (`apptainer exec`) - `wcwc` only

`wcwc container` opens an interactive shell and cannot be used from scripts or batch jobs.
Call `apptainer exec` with the same image and mounts instead:

```bash
APP="/cvmfs/oasis.opensciencegrid.org/mis/apptainer/current/bin/apptainer"
IMG="/cvmfs/singularity.opensciencegrid.org/fermilab/fnal-dev-sl7:latest"
MOUNTS="/cvmfs,/home,/nfs,/opt,/run/user,/etc/hostname,/etc/hosts,/etc/krb5.conf"

"$APP" exec -B "$MOUNTS" --ipc --pid "$IMG" bash -c \
    'source ~/MyDotfiles/dune_setup/wcgpu1_setup_dunesw.sh; <command>'
```

Each `exec` is a fresh shell, so the setup script has to be sourced in every call.
