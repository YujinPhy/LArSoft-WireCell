# `wirecell_dune.fcl`의 PDHD / PDVD 블록 목록

`/nfs/data/1/yujin/LArSoft-WireCell/wirecell_dune.fcl`(local override 사본, 2363줄)의 prolog에 정의된
PDHD/PDVD용 `WireCellToolkit` 블록을 표로 정리한다. 블록 구조와 각 key의 의미는
`docs/03_wirecell_dune_module.md`, `reality`의 효과는 `docs/04_reality_data_vs_sim.md`를 참고한다.
확인일: 2026-10-12.

- 모든 블록은 `module_type: WireCellToolkit`, `wcls_main.tool_type: WCLS`, `apps: ["Pgrapher"]`이다.
- jsonnet 경로는 `pgrapher/experiment/` 접두어를 생략했다.
- `Nbit`는 모두 `@local::Nbit_standard`, `elecGain`은 모두 `14`(mV/fC)이므로 표에서 뺐다.

## 1. 전체 목록

| 블록 | 줄 | 검출기 | 단계 | 정의 방식 | data/MC |
|---|---|---|---|---|---|
| `protodunehddata_wctsp` | 129 | PDHD | SP | `@local::protodunespdata_wctsp` + override | data |
| `protodunehd_nfsp` | 134 | PDHD | NF+SP | 직접 정의 | data |
| `protodunehd_nfsp_mc` | 160 | PDHD | NF+SP | `@local::protodunehd_nfsp` | MC |
| `protodunehd_nfsp_dnnroi` | 167 | PDHD | NF+SP+DNN-ROI+L1SP | 직접 정의 | data |
| `protodunehd_nfsp_dnnroi_mc` | 195 | PDHD | NF+SP+DNN-ROI+L1SP | `@local::protodunehd_nfsp_dnnroi` | MC |
| `protodunehd_nf` | 198 | PDHD | NF | 직접 정의 | data |
| `protodunehd_nf_mc` | 223 | PDHD | NF | `@local::protodunehd_nf` | MC |
| `protodunehd_sp` | 226 | PDHD | SP (NF 출력 입력) | 직접 정의 | data |
| `protodunehd_sp_mc` | 251 | PDHD | SP | `@local::protodunehd_sp` | MC |
| `protodunehd_sp_dnn_l1sp` | 259 | PDHD | SP+DNN-ROI+L1SP (NF 출력 입력) | 직접 정의 | data |
| `protodunehd_sp_dnn_l1sp_mc` | 287 | PDHD | SP+DNN-ROI+L1SP | `@local::protodunehd_sp_dnn_l1sp` | MC |
| `protodunehd_dnnsp` | 290 | PDHD | SP+DNN-ROI (NF 출력 입력) | 직접 정의 | data |
| `protodunehd_dnnsp_mc` | 315 | PDHD | SP+DNN-ROI | `@local::protodunehd_dnnsp` | MC |
| `protodunehd_nfspimg` | 2159 | PDHD | NF+SP+imaging | 직접 정의 | data |
| `protodunehd_img` | 2184 | PDHD | imaging (SP 출력 입력) | 직접 정의 | data |
| `wirecell_protodunehdmc` | 360 | PDHD | sim (drift+digitize) | `@local::wirecell_protodunespmc` + override | sim |
| `wirecell_pdhd_sim_deposplat` | 559 | PDHD | sim (DepoSplat) | 직접 정의 | sim |
| `protodunevd_nfsp` | 2024 | PDVD | NF+SP | 직접 정의 | data |
| `protodunevd_nfsp_dnnroi` | 2055 | PDVD | NF+SP+DNN-ROI+L1SP | 직접 정의 | data |
| `protodunevd_nfsp_dnnroi_mc` | 2081 | PDVD | NF+SP+DNN-ROI+L1SP | `@local::protodunevd_nfsp_dnnroi` | MC |
| `protodunevd_nf` | 2084 | PDVD | NF | 직접 정의 | data |
| `protodunevd_sp` | 2110 | PDVD | SP (NF 출력 입력) | 직접 정의 | data |
| `protodunevd_nfspimg` | 2135 | PDVD | NF+SP+imaging | 직접 정의 | data |
| `wirecell_protodunevd_mc` | 461 | PDVD | sim (drift+digitize) | 직접 정의 | sim |
| `wirecell_protodunevd_mc_splusn` | 494 | PDVD | sim (signal+noise) | 직접 정의 | sim |
| `wirecell_protodunevd_sim_deposplat` | 531 | PDVD | sim (DepoSplat) | 직접 정의 | sim |

- `_mc` 블록은 모두 원본 블록을 복사한 뒤 `wcls_main.params.reality: "sim"` 한 줄만 바꾼다.
- PDVD는 `protodunevd_nfsp`, `protodunevd_nf`, `protodunevd_sp`, `protodunevd_nfspimg`의 `_mc` 블록이 없다.
  MC에 쓰려면 job fcl에서 `reality`를 직접 override해야 한다.

## 2. Reconstruction 블록 (NF / SP / DNN-ROI / imaging)

### 2.1 PDHD

| 블록 | `configs` | `inputers` | `outputers` | `params` | 추가 `structs` |
|---|---|---|---|---|---|
| `protodunehddata_wctsp` | `pdhd/wcls-sp.jsonnet` | `wclsCookedFrameSource` | `wclsFrameSaver:spsaver` | `raw_input_label: "caldata:dataprep"`, `epoch: "after"`, `sparse` (`protodunespdata_wctsp`에서 상속) | `wire_col_nsigma: 10.0` (상속) |
| `protodunehd_nfsp` | `pdhd/wcls-nf-sp.jsonnet` | `wclsRawFrameSource` | `wclsFrameSaver:spsaver` | `tpcrawdecoder:daq`, `epoch: "after"`, `sparse`, `use_resampler: "false"` | - |
| `protodunehd_nfsp_dnnroi` | `pdhd/wcls-nf-sp-dnnroi.jsonnet` | `wclsRawFrameSource` | `spsaver`, `tradspsaver` | `tpcrawdecoder:daq`, `epoch: "after"`, `dense`, `use_resampler: "false"` | `use_dnnroi: true` |
| `protodunehd_nf` | `pdhd/wcls-nf.jsonnet` | `wclsRawFrameSource` | `wclsFrameSaver:nfsaver` | `tpcrawdecoder:daq`, `sparse`, `use_resampler: "false"` | `clock_speed` |
| `protodunehd_sp` | `pdhd/wcls-rawdigit-sp.jsonnet` | `wclsRawFrameSource` | `wclsFrameSaver:spsaver` | `wclsdatahdfilter:raw`, `epoch: "after"`, `sparse` | `clock_speed` |
| `protodunehd_sp_dnn_l1sp` | `pdhd/wcls-sp-dnn-l1sp.jsonnet` | `wclsRawFrameSource` | `spsaver`, `tradspsaver` | `wclsdatahdfilter:raw`, `epoch: "after"`, `dense` | `use_dnnroi: true` |
| `protodunehd_dnnsp` | `pdhd/wcls-rawdigit-dnnsp.jsonnet` | `wclsRawFrameSource` | `spsaver`, `dnnsaver` | `wclsdatahdfilter:raw`, `dense` | `clock_speed` |
| `protodunehd_nfspimg` | `pdhd/wcls-nf-sp-img.jsonnet` | `wclsRawFrameSource` | 없음 | `tpcrawdecoder:daq`, `dense`, `use_magnify: "false"`, `use_resampler: "false"` | - |
| `protodunehd_img` | `pdhd/wcls-img.jsonnet` | `wclsCookedFrameSource:charge`, `wclsCookedFrameSource:wiener` | 없음 | `charge_input_label: "wclsdatahd:gauss"`, `wiener_input_label: "wclsdatahd:wiener"` | - |

- `params`의 `reality`는 모두 `"data"`이므로 표에서 생략했다.
- `clock_speed`는 `@local::protodunehd_services.DetectorClocksService.ClockSpeedTPC`이다.
- `outputers`의 `spsaver` 등은 `wclsFrameSaver:` 접두어를 생략했다.
- `protodunehddata_wctsp`는 `protodunespdata_wctsp`(PDSP 블록)를 복사하므로 PDSP용
  `raw_input_label: "caldata:dataprep"`가 그대로 남아 있다.

### 2.2 PDVD

| 블록 | `configs` | `inputers` | `outputers` | `params` | 추가 `structs` |
|---|---|---|---|---|---|
| `protodunevd_nfsp` | `protodunevd/wcls-nf-sp.jsonnet` | `wclsRawFrameSource` | `wclsFrameSaver:spsaver` | `tpcrawdecoder:daq`, `epoch: "after"`, `sparse`, `use_magnify: "false"`, `use_resampler: "false"` | `use_dnnroi: false` |
| `protodunevd_nfsp_dnnroi` | `protodunevd/wcls-nf-sp-dnnroi.jsonnet` | `wclsRawFrameSource` | `wclsFrameSaver:spsaver` | `tpcrawdecoder:daq`, `epoch: "after"`, `dense`, `use_magnify: "false"`, `use_resampler: "false"` | `use_dnnroi: true` |
| `protodunevd_nf` | `protodunevd/wcls-nf.jsonnet` | `wclsRawFrameSource` | `wclsFrameSaver:nfsaver` | `tpcrawdecoder:daq`, `epoch: "after"`, `sparse`, `use_magnify: "false"`, `use_resampler: "false"` | - |
| `protodunevd_sp` | `protodunevd/wcls-rawdigit-sp.jsonnet` | `wclsRawFrameSource` | `wclsFrameSaver:spsaver` | `wclsdatavdfilter:raw`, `epoch: "after"`, `sparse`, `use_magnify: "false"` | - |
| `protodunevd_nfspimg` | `protodunevd/wcls-nf-sp-img.jsonnet` | `wclsRawFrameSource` | 없음 | `tpcrawdecoder:daq`, `dense`, `use_magnify: "false"` | - |

- PDVD는 `use_resampler: "false"`가 기본값이다. data job에서는 job fcl에서 `"true"`로 override한다
  (`fcl_data/standard_reco_pdvd_offline.fcl:151`, `:162`, `:166`, `:170`).
- `protodunevd_sp`의 `params`에는 `use_resampler`가 없다. `wcls-rawdigit-sp.jsonnet`이
  `std.extVar("use_resampler")`를 읽으므로 이 블록을 쓸 때는 job fcl에서 값을 넣어야 한다
  (`docs/04_reality_data_vs_sim.md` 3.2절).

## 3. Simulation 블록

| 블록 | `configs` | `inputers` | `outputers` | `structs` |
|---|---|---|---|---|
| `wirecell_protodunehdmc` | `pdhd/wcls-sim-drift-simchannel-priorSCE-depoflux.jsonnet` | `wclsSimDepoSetSource:electron` | `wclsDepoFluxWriter:postdrift`, `wclsFrameSaver:simdigits` | `DL: 4.0`(cm2/s), `DT: 8.8`(cm2/s), `lifetime: 35.0`(ms), `driftSpeed: 1.565`(mm/us) (`wirecell_protodunespmc`에서 상속) |
| `wirecell_pdhd_sim_deposplat` | `pdhd/wcls-sim-drift-deposplat.jsonnet` | `wclsSimDepoSource:` | 없음 (주석 처리) | - |
| `wirecell_protodunevd_mc` | `protodunevd/wcls-sim-drift-depoflux.jsonnet` | `wclsSimDepoSetSource:electron` | `wclsDepoFluxWriter:postdrift`, `wclsFrameSaver:simdigits` | `nticks`, `lifetime`, `DL`, `DT`, `efield`, `temperature` (LArSoft service 값 참조) |
| `wirecell_protodunevd_mc_splusn` | `protodunevd/wcls-sim-drift-simchannel-splusn.jsonnet` | `wclsSimDepoSource:electron` | `wclsSimChannelSink:postdrift`, `wclsFrameSaver:simsignals`, `wclsFrameSaver:simdigits` | `wirecell_protodunevd_mc`와 동일 |
| `wirecell_protodunevd_sim_deposplat` | `protodunevd/wcls-sim-drift-deposplat.jsonnet` | `wclsSimDepoSource:` | 없음 (주석 처리) | `wirecell_protodunevd_mc`와 동일 |

- PDVD sim 블록의 `structs` 출처: `nticks`, `lifetime`, `efield`, `temperature`는
  `protodunevd_services.DetectorPropertiesService`, `DL`, `DT`는 `dunefd_largeantparameters`.
- sim 블록은 `params`가 비어 있고 `reality`를 쓰지 않는다.

## 4. Job fcl에서의 사용 (이 저장소 기준)

| 블록 | module label | job fcl |
|---|---|---|
| `protodunehd_nfsp` | `wclsdatahdfilter` | `fcl_data/standard_reco_stage1_protodunehd_keepup.fcl:8` |
| `protodunehd_nfsp` | `wclsdatahd` | `fcl_data/standard_reco_stage2_calibration_protodunehd_keepup.fcl:8` |
| `protodunehd_dnnsp` | `wclsdatahd` | `fcl_data/standard_reco_stage2_calibration_protodunehd_keepup_dnnroi.fcl:8` |
| `protodunehd_nfspimg` | `wclsdatahd` | `fcl_data/standard_reco_stage2_calibration_protodunehd_keepup_img.fcl:8` |
| `protodunehd_nfsp_mc` | `wclsdatahd` | `fcl_sim/detsim_reco/standard_reco_protodunehd_MC.fcl:89` |
| `protodunehd_nfsp_dnnroi_mc` | `wclsdatahd` | `fcl_sim/detsim_reco/standard_reco_protodunehd_MC_dnnroi.fcl:90` |
| `wirecell_protodunehdmc` | `tpcrawdecoder` | `fcl_sim/detsim_reco/standard_detsim_protodunehd.fcl:31` |
| `wirecell_pdhd_sim_deposplat` | `wirecell` | `fcl_sim/pdhd_wirecell_sim_deposplat.fcl:44` |
| `wirecell_pdhd_sim_deposplat` | `wclsdatahd` | `fcl_sim/detsim_reco/standard_reco_protodunehd_MC_depofluxsplat.fcl:89` |
| `protodunevd_nf` | `wclsdatavdnf` | `fcl_data/standard_reco_pdvd_offline.fcl:94`, `..._nodnnroi.fcl:84` |
| `protodunevd_nfspimg` | `wclsdatavdimg` | `fcl_data/standard_reco_pdvd_offline.fcl:95`, `..._nodnnroi.fcl:85` |
| `protodunevd_nfsp` | `wclsdatavd` | `fcl_data/standard_reco_pdvd_offline.fcl:96`, `..._nodnnroi.fcl:86` |
| `protodunevd_nfsp_dnnroi` | `wclsdatavddnn` | `fcl_data/standard_reco_pdvd_offline.fcl:97`, `..._nodnnroi.fcl:87` |
| `wirecell_protodunevd_sim_deposplat` | `wirecell` | `fcl_sim/detsim_reco/pdvd_wirecell_sim_deposplat.fcl:34` |

## 5. 확인된 문제

- jsonnet 파일 존재 여부. 현재 `WIRECELL_PATH`의 첫 항목은 `$WORKDIR/wire-cell-toolkit/cfg`이다.
  아래 파일은 이 tree에는 없고 `dunereco v10_26_00d01`의 `wire-cell-cfg`(CVMFS)에만 있으므로
  CVMFS 버전으로 fallback된다.
  - `pdhd/wcls-nf-sp-dnnroi.jsonnet` (`protodunehd_nfsp_dnnroi`, `_mc`)
  - `pdhd/wcls-sp-dnn-l1sp.jsonnet` (`protodunehd_sp_dnn_l1sp`, `_mc`)
  - `protodunevd/wcls-nf-sp-dnnroi.jsonnet` (`protodunevd_nfsp_dnnroi`, `_mc`)
  - `protodunevd/wcls-sim-drift-depoflux.jsonnet` (`wirecell_protodunevd_mc`)
- `fcl_sim/pdhd_wirecell_sim_nf_sp_img.fcl:44`은 `@local::wirecell_pdhd_sim_nf_sp_img`를 참조하지만
  이 블록은 이 저장소와 CVMFS DUNE product(`*/v10_26_00d01/fcl`) 어디에도 정의되어 있지 않다.
  이 job fcl은 지금 상태로는 parse 단계에서 실패한다.
