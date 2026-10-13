# dunereco `wire-cell-cfg`: PDHD / PDVD 공통 설정 파일

공식 dunereco 배포본에서 `pgrapher/experiment/pdhd/`와 `pgrapher/experiment/protodunevd/`에
**같은 이름으로 모두 있는** 25개 파일을 정리하고 두 detector를 비교한다.
한쪽에만 있는 파일은 `docs/08_pdhd_pdvd_unique_files.md`를 참고한다.

- 대상: `$D = /cvmfs/dune.opensciencegrid.org/products/dune/dunereco/v10_26_00d01/wire-cell-cfg/pgrapher/experiment`
- 표기: `HD:n`은 `$D/pdhd/<파일>`의 n번째 줄, `VD:n`은 `$D/protodunevd/<파일>`의 n번째 줄이다.
- 상위 공통 파일(`common/*`, `dune/params`, `ui/wcls/nodes`): `docs/06_dunereco_wirecell_cfg_common.md`
- `reality`의 효과: `docs/04_reality_data_vs_sim.md` (7절에 공식 버전 기준 정정이 있음)
- 확인일: 2026-10-12
- 검증 수준: 모든 파일을 코드 읽기로 정리했다. 9절의 "확인" 표시는 해당 줄을 직접 다시 열어 확인한 항목이다.
  jsonnet 평가나 job 실행으로 검증한 항목은 없다.

## 1. 파일 분류

| 분류 | 파일 | 줄 수 (HD / VD) | 역할 | 사용 여부 |
|---|---|---|---|---|
| parameter | `params.jsonnet` | 190 / 206 | data용 detector parameter (`dune/params` 상속) | 사용 |
| parameter | `simparams.jsonnet` | 263 / 170 | `params` + sim override | 사용 |
| NF library | `chndb-base.jsonnet` | 221 / 589 | `OmniChannelNoiseDB` 설정 (channel group, bad channel, 응답, RMS cut) | 사용 |
| NF library | `nf.jsonnet` | 103 / 102 | `OmnibusNoiseFilter` pnode | 사용 |
| SP library | `sp.jsonnet` | 285 / 323 | `OmnibusSigProc` (+ 기본 `L1SPFilterPD` envelope) | 사용 |
| SP library | `sp-filters.jsonnet` | 85 / 115 | SP용 `HfFilter`/`LfFilter` 정의 | 사용 |
| DNN library | `dnnroi.jsonnet` | 141 / 85 | 구버전 3-channel DNN-ROI | **미사용** |
| DNN library | `dnnroi_mp.jsonnet` | 144 / 166 | U+V를 한 번에 넣는 multi-plane DNN-ROI | **미사용** |
| DNN library | `dnnroi_pp.jsonnet` | 161 / 159 | plane별 DNN-ROI (현재 배포 버전) | 사용 |
| DNN library | `l1sp_after_dnnroi.jsonnet` | 210 / 227 | SP -> DNN-ROI -> `L1SPFilterPD` envelope | 사용 |
| imaging | `img.jsonnet` | 369 / 366 | slicing, tiling, solving, `ClusterFileSink` | 사용 |
| clustering | `clus.jsonnet` | 678 / 670 | `MultiAlgBlobClustering` 4단계 + Bee 출력 | **미사용** |
| utility | `funcs.jsonnet` | 138 / 192 | fan helper (detector별 tag rule), PDHD `splat`, PDVD channel map | 사용 |
| utility | `magnify-sinks.jsonnet` | 173 / 184 | 디버그용 `MagnifySink` pipe 묶음 | 사용 (대부분 주석 처리) |
| sim library | `sim.jsonnet` | 88 / 109 | signal / signal+noise sim pipeline | 사용 |
| wcls entry | `wcls-nf.jsonnet` | 198 / 217 | NF만 수행 | `protodunehd_nf`, `protodunevd_nf` |
| wcls entry | `wcls-nf-sp.jsonnet` | 217 / 325 | NF + SP | `protodunehd_nfsp(_mc)`, `protodunevd_nfsp` |
| wcls entry | `wcls-nf-sp-dnnroi.jsonnet` | 449 / 331 | NF + SP + DNN-ROI + L1SP(hybrid) | `protodunehd_nfsp_dnnroi(_mc)`, `protodunevd_nfsp_dnnroi(_mc)` |
| wcls entry | `wcls-nf-sp-img.jsonnet` | 231 / 237 | NF + SP + imaging | `protodunehd_nfspimg`, `protodunevd_nfspimg` |
| wcls entry | `wcls-nf-dnnsp-img.jsonnet` | 397 / 348 | NF + SP + DNN-ROI + L1SP + imaging | `wirecell_dune.fcl`에 블록 없음 |
| wcls entry | `wcls-rawdigit-sp.jsonnet` | 244 / 211 | NF 출력 RawDigit -> SP | `protodunehd_sp(_mc)`, `protodunevd_sp` |
| wcls entry | `wcls-sim-drift-deposplat.jsonnet` | 379 / 523 | depo -> drift -> sim + truth splat -> SP -> DNN-ROI, HDF5 출력 | `wirecell_pdhd_sim_deposplat`, `wirecell_protodunevd_sim_deposplat` |
| wct entry | `wct-sim-check.jsonnet` | 135 / 399 | 단독 실행: track -> sim -> NF -> SP, magnify 출력 | `wire-cell` CLI |
| wct entry | `wct-sim-drift-deposplat.jsonnet` | 344 / 534 | wcls deposplat의 단독 실행 버전 | `wire-cell` CLI |
| wct entry | `wct-sim-fans.jsonnet` | 175 / 187 | 단독 실행: track -> sim -> SP -> imaging | `wire-cell` CLI |

- "사용 여부"의 library 판정은 `$D/pdhd`, `$D/protodunevd` 안 파일의 `import` 문을 grep한 결과이다.
  PDVD `wcls-nf-sp.jsonnet:180`은 같은 디렉터리의 `dnnroi.jsonnet`이 아니라
  `pgrapher/experiment/dune-vd/dnnroi.jsonnet`을 import한다.
- `clus.jsonnet`은 `pgrapher/common/clus.jsonnet`을 import한다. 이 파일은 dunereco `wire-cell-cfg`에는 없고
  WCT release(`v0_37_1`)에만 있다.
- wcls entry와 fcl 블록의 대응은 `docs/05_wirecell_dune_pdhd_pdvd_blocks.md` 기준이다.

## 2. 두 detector의 기본 구조

| 항목 | PDHD | PDVD |
|---|---|---|
| anode 수 / 이름 | 4 APA, `apa%d` (`params` HD:68-94) | 8 anode, `anode%d` (`params` VD:49-92) |
| anode 배치 | APA 짝수는 $x<0$, 홀수는 $x>0$. cryostat 벽 쪽 face는 `null` | ident `0-3` bottom drift($x<0$), `4-7` top drift($x>0$). 두 face를 같은 값으로 정의 |
| channel / anode | 2560 (U `[0,800)`, V `[800,1600)`, W `[1600,2560)` + `2560n`) | 1536. 짝수 ident는 U `0-475`, V `952-1427`, W `1904-2487`, 홀수 ident는 U `476-951`, V `1428-1903`, W `2488-3071`. 각각 `+3072*floor(ident/2)` (`funcs` VD:24-30) |
| channel 선택 | `std.range(2560*n, 2560*(n+1)-1)` | `util.anode_channels(ident)` |
| top/bottom 구분 | 없음. 대신 **APA0 예외**가 많다 (V plane 결함으로 collection처럼 동작) | `ident < 4`(bottom) vs `ident >= 4`(top). 접미사 `_b`/`_t`로 filter, 응답, threshold를 나눔 |
| data tick | `512ns` (`params` HD:109). NF 앞에서 `Resampler`로 `500ns` | `500ns` 기본. bottom만 `use_resampler: "true"`일 때 `512ns` -> `500ns` |
| sim tick / nticks | `0.5us` / `6000` (`simparams` HD:111, 116) | `0.5us` / `6400` (`simparams` VD:22) |
| gain 기준 | `elecGain` extVar (`params` HD:129-130), threshold scaling 기준 `14mV/fC` | bottom `7.8mV/fC` 고정 (`params` VD:140), top은 `JsonElecResponse`. scaling 기준은 bottom `7.8mV/fC`, top `1.0` |

## 3. Parameter: `params.jsonnet`, `simparams.jsonnet`

### 3.1 `params.jsonnet`

둘 다 `pgrapher/dune/params.jsonnet`을 상속하는 plain object이다.

| 항목 | PDHD | PDVD |
|---|---|---|
| geometry 상수 | `apa_cpa 3.5734m`, `cpa_thick 3.175mm`, `apa_w2w 85.87mm`, `plane_gap 4.76mm` (HD:30-34) | `apa_cpa 341.55cm`, `cpa_thick 50.8mm`, `apa_w2w 85.725mm`, `apa_g2g 114.3mm` (VD:29-33) |
| anode cut plane | 첫 induction plane (`0.5*g2g - gap`, HD:45) | grid (`0.5*g2g`, VD:35) |
| `response_plane` | `10cm` (HD:51) | `18.1cm` (VD:41) |
| `bounds` | $(-4,0,0)$ - $(4,6.1,7.0)$m | $(-3.15,-3.42,0)$ - $(3.13,3.42,3.04)$m |
| `daq` | `tick 512ns`, `nticks 6000` (HD:109-110) | `nticks 6000` (VD:107), tick은 기본 `500ns` |
| `nf.nsamples` | override 없음 (`6000`) | `8000` (VD:115-117, resampling 후 `7813` -> `8000`) |
| `adc` | `14`bit, baselines `[1003.4, 1003.4, 507.7]mV`, fullscale `[0.2, 1.6]V` | 같음 (VD:121-125) |
| `elecs` | 4개, 모두 `gain = elecGain*mV/fC`, `shaping 2.2us` (HD:123-136) | `[0]` bottom: `gain 7.8mV/fC`, `shaping 2.2us`, `postgain 1.0`. `[1]` top: `JsonElecResponse`, `dunevd-coldbox-elecresp-top-psnorm_400.json.bz2`, `postgain 1.36` (VD:137-146) |
| `files.wires` | `protodunehd-wires-larsoft-v1.json.bz2` | `protodunevd-wires-larsoft-v5.json.bz2` |
| `files.fields` | APA0 `np04hd-garfield-6paths-mcmc-bestfit.json.bz2`, APA1-3 `dune-garfield-1d565.json.bz2` (HD:172-177) | 2개 모두 `protodunevd_FR_imbalance3p_260501.json.bz2` (VD:183-190) |
| `files.fltresp` | `protodunehd-field-response-filters.json.bz2` (APA0 SP용) | 없음 |
| noise | `noise: pdhd_noise(gain)` (HD:12-18, 183) | `noises: [pdvd_bottom_noise(gain), "pdvd-top-noise-spectra-v3.json.bz2"]` (VD:13-19, 196-199) |
| `files.strip_length` | 없음 | `PDVD_strip_length.json.bz2` (shield coupling NF용) |

- noise file 선택 함수는 gain이 `7.8` 또는 `14`mV/fC가 아니면 `error`를 낸다.
  PDVD bottom gain은 `7.8`로 고정이므로 fcl의 `elecGain`과 무관하게 항상 `7d8mVfC` 파일이 선택된다.

### 3.2 `simparams.jsonnet`

| 항목 | PDHD | PDVD |
|---|---|---|
| `lar` | override 없음 (`lifetime 35ms`는 주석 처리, HD:7-10) | `lifetime 1000ms`, `DL 4.0cm2/s`, `DT 8.8cm2/s`, `drift_speed 1.473mm/us` (VD:7-14) |
| `det` | 재정의: 모든 APA의 두 face를 정의 (HD:21-94) | override 없음 |
| `daq` | `tick 0.5us`, `nticks 6000` | `nticks 6400` |
| `sim` | `fixed true`, `continuous false`, `fluctuate true` | 같음 |
| `sys_resp` | `start -10us` | `start 0us`, `overall_short_padding 0.2ms` |
| `rc_resp` | `width 1.1ms`, `rc_layers 0` | 같음 |

## 4. Noise filtering: `chndb-base.jsonnet`, `nf.jsonnet`

### 4.1 `chndb-base.jsonnet`

시그니처(공통): `function(params, anode, field, n, rms_cuts=[], use_freqmask=true)`. 반환값은 `OmniChannelNoiseDB`의 `data`이다.

| 항목 | PDHD | PDVD |
|---|---|---|
| import | `chndb-resp.jsonnet`, `pdhd-coh-groups.jsonnet`, `pdhd-femb-negpulse-groups.jsonnet` | `chndb-resp-bot.jsonnet`, `chndb-resp-top.jsonnet`, `funcs.jsonnet` |
| `gain_scale` | `elec.gain / 14mV/fC` (HD:21) | top `1.0`, bottom `elec.gain / 7.8mV/fC` (VD:28-29) |
| `tick` | `0.5us` 고정 (resampling 후, HD:33) | `params.daq.tick` (VD:46) |
| coherent group | `coh_groups.groups[n]`: anode별 60 group (FEMB 단위 U/V/W 각 20) (HD:46) | 360 group 목록을 **모든 anode에 동일하게** 사용 (VD:62-423) |
| FEMB negative pulse | `femb_negpulse_groups` (HD:48) | 없음 |
| top U 전체 group | 없음 | `top_u_groups` (VD:425-427, shield coupling용) |
| bad channel | 33개 (HD:51) | 362개 (VD:432-434) |
| `decon_limit` / `decon_limit1` | `0.02` / `0.09` | `0.005` / `0.008` |
| `adc_limit`, `min_adc_limit` | `30gs`, `100gs` | `60gs`, top `60` / bottom `50gs` |
| `min_rms_cut` / `max_rms_cut` | `10gs` / `50gs` | `1gs` / `60gs` (plane별 override 있음) |
| `rc_layers` | `1` | `0` |
| U/V 응답 | handmade 응답 `* gs`, offset U `127`, V `132`. **APA0 V는 응답 없음** (HD:95-133) | top/bottom 응답, offset U `240`/`239`, V `243`/`245` (VD:37-38) |
| freq mask | 모두 주석 처리 (HD:150-218) | top anode만 `23.5kHz`, `711kHz` 제거 (VD:534-545) |
| RMS cut | 기본값만 | top: wire length 기반 piecewise, bottom: wire length 기반 linear (VD:555-587) |

`gs`는 `gain_scale`이다.

### 4.2 `nf.jsonnet`

| 항목 | PDHD | PDVD |
|---|---|---|
| 시그니처 | `function(params, anode, chndbobj, n, name, dft, debug_dump_path, debug_dump_groups, maskmap)` | `function(params, anode, chndbobj, n, name, debug_dump_path, debug_dump_groups, maskmap, shield_dump_path, intraces='orig')` |
| single-channel | `PDHDOneChannelNoise` | `PDVDOneChannelNoise` |
| coherent | `PDHDCoherentNoiseSub` (APA0는 `Wiener_tight_*_APA1` filter) | `PDVDCoherentNoiseSub` (`_b`/`_t` filter) |
| 추가 filter | `PDHDFEMBNoiseSub` (FEMB negative pulse) | `PDVDShieldCouplingSub` (top만, `top_u_groups`, `strip_length`) |
| maskmap | `{noisy: "bad", femb_noise: "bad"}` | `{noisy: "bad"}` |
| 입력/출력 trace tag | `''`(전체) -> `raw%d`(n) | `intraces`(기본 `orig`) -> `raw%d`(ident) |

## 5. Signal processing: `sp.jsonnet`, `sp-filters.jsonnet`

### 5.1 `sp.jsonnet`

시그니처(공통): `function(params, tools, override={})`. 반환 object의 `make_sigproc(anode, name=null, ...)`가
`OmnibusSigProc` pnode를 만든다. L1SP가 켜져 있으면 `L1SPFilterPD`를 포함한 subgraph를 만든다.

| 항목 | PDHD | PDVD |
|---|---|---|
| `make_sigproc` 기본 L1SP mode | `'process'` (HD:30) | `'dump'` (VD:26) |
| field response | `tools.fields[ident]` (APA별) | `tools.field` (첫 FR) |
| elec response | `tools.elec_resp` | bottom `elec_resps[0]`, top `elec_resps[1]` |
| `ADC_mV` | `16383/1.4V` | bottom `16383/1.4V`, top `16383/2.0V` |
| `ctoffset` | `1.0us` | `4us` |
| APA0 처리 | `plane2layer [0,2,1]`, `filter_responses_tn`, `_APA1` Wiener filter, `r_th_factor 2.5`, W ROI tune | 없음 |
| collection BreakROI | APA1-3 끔 (`r_break_roi_loop_planes [2,2,0]`) | 모든 anode에서 끔 |
| `use_multi_plane_protection` | `false` | `true` |
| `isWrapped` | `false` | `false` |
| 출력 tag | `wiener%d`, `gauss%d`, `decon_charge%d`, ROI debug tag(`tight_lf`, `loose_lf`, `mp2_roi`, `mp3_roi` 등) | 같음 |

**`L1SPFilterPD` 설정**

| 항목 | PDHD | PDVD |
|---|---|---|
| kernel file | `pdhd_l1sp_kernels.json.bz2` | `pdvd_bottom_l1sp_kernels.json.bz2` / `pdvd_top_l1sp_kernels.json.bz2` |
| `process_planes` | APA0 `[0]`, 나머지 `[0,1]` | `[0,1]` |
| `gain_scale` 기준 | `14mV/fC` | bottom `7.8mV/fC`, top `1.0` |
| detector 전용 tuning | `l1_len_very_long 140`, `l1_asym_very_long 0.35` | `l1_len_long_mod 180`, `l1_len_fill_shape 90`, track veto, `peak_threshold 1000`, `mean_threshold 500` |

L1SP subgraph의 마지막 `FrameMerger`(`replace`)는 L1SP 결과를 `gauss%d`와 `wiener%d`에 모두 덮어쓴다
(HD:253-261, VD:294-303). 그 결과 `threshold`, `loose_lf`, `mp*_roi`, `decon_charge` 같은 tag는 출력에 남지 않는다.

### 5.2 `sp-filters.jsonnet`

plain array이다. PDHD는 16개, PDVD는 31개 filter를 정의한다(PDVD는 같은 값의 `_b`/`_t` 쌍). 단위는 sigma [MHz]이다.

| filter | PDHD | PDVD |
|---|---|---|
| `ROI_loose_lf` tau | `0.003` | `0.003` |
| `ROI_tight_lf` tau | `0.016` | `0.014` |
| `ROI_tighter_lf` tau | `0.08` | `0.06` |
| `Gaus_wide` | `0.12` | `0.12` |
| `Wiener_tight_U/V/W` sigma (power) | `0.2219 (6.55)`, `0.2227 (8.76)`, `0.2256 (3.48)` | `0.1488 (3.76)`, `0.1597 (4.36)`, `0.1362 (3.35)` |
| `Wiener_tight_*_APA1` | APA0 전용 3개 | 없음 |
| `Wiener_wide_U/V/W` | `0.1868`, `0.1936`, `0.1757` | 같음 |
| `Wire_ind` sigma | $0.75/\sqrt{\pi}$ | $5.0/\sqrt{\pi}$ |
| `Wire_col` sigma | $10/\sqrt{\pi}$ | $10/\sqrt{\pi}$ |

## 6. DNN-ROI, L1SP, imaging, clustering

### 6.1 DNN-ROI 세 가지 변형

| 파일 | 방식 | channel 수 | 사용 |
|---|---|---|---|
| `dnnroi.jsonnet` | plane별 `DNNROIFinding`, 3-channel (`loose_lf`, `mp2_roi`, `mp3_roi`) | 3 | 미사용 |
| `dnnroi_mp.jsonnet` | U+V를 쌓아 `DNNROIFindingMultiPlane` 한 번 호출 | HD 3 또는 6, VD 4 | 미사용 |
| `dnnroi_pp.jsonnet` | plane별 `DNNROIFinding` 호출 + tick padding + `wiener%d` summary 전달 | 6 | 모든 DNN-ROI caller |

`dnnroi_pp.jsonnet`:
- 시그니처: `function(anode, ts, prefix, output_scale, nticks=6000, tick_per_slice=4, ..., mask_thresh=0.2, nchan=6, ...)`.
  `ts`는 caller가 만든 `TorchService`이다.
- input 6 channel: `loose_lf`, `mp2_roi`, `mp3_roi`, `tight_lf`, `decon_charge`, `gauss`.
- W plane은 DNN을 거치지 않는다(`PlaneSelector`). 출력 tag는 `dnnsp%d`.
- PDHD: APA0의 V는 DNN 대신 `gauss`를 그대로 쓴다. `tick_pad_multiple 64`.
- PDVD: 모든 anode에서 U, V에 DNN을 적용한다. `tick_pad_multiple 128`.

### 6.2 `l1sp_after_dnnroi.jsonnet`

- 구조: SP -> DNN-ROI -> Retagger(`dnnsp%d` -> `gauss%d`, `wiener%d`) -> `L1SPFilterPD` -> `FrameMerger`(`replace`).
- mode: `'process'`, `'dump'`, `'dnn'`, `'hybrid'`. `'dnn'`/`'hybrid'`일 때 L1SP용 `TorchService`를 쓴다.
- DNN threshold 기본값: PDHD `0.9945`, PDVD `0.94`. PDVD는 top/bottom 별도 threshold를 받을 수 있다.
  실제 caller(`wcls-nf-sp-dnnroi`)는 두 detector 모두 `0.5`를 넘긴다.
- kernel, `gain_scale`, detector 전용 tuning은 5.1절 `L1SPFilterPD` 표와 같다.

### 6.3 `img.jsonnet`

| 항목 | PDHD | PDVD |
|---|---|---|
| 시그니처 | `function(cfg={})` (`use_dnn_img`, `nthreshold`) | `function(output_dir='', nthreshold=[3.6,3.6,3.6])` |
| `per_anode` 기본 `pipe_type` | `"multi"`: active(span 4, full solving) + masked(span 1500) | `"single"`: span 4, simple solving |
| `use_dnn_img` | `true`이면 `dnnsp%d`를 imaging 입력으로 사용 | 없음 (`gauss`/`wiener` 고정) |

공통 단계:
- 전처리: `CMMModifier` -> `FrameMasking` -> `ChargeErrorFrameEstimator`
- slicing: `MaskSlices` (charge `gauss%d`, summary `wiener%d`)
- tiling: `GridTiling` 두 face
- solving: `BlobClustering` -> `BlobGrouping` -> `ChargeSolving` -> `LocalGeomClustering` -> ... -> `GlobalGeomClustering`
- 출력: `ClusterFileSink` -> `clusters-apa-<anode>.tar.gz` (numpy 형식, 현재 작업 디렉터리 또는 `output_dir`)

### 6.4 `clus.jsonnet` (미사용)

- 시그니처: `function(output_dir='', runNo=1, subRunNo=1, eventNo=1, time_offset=0us)`.
  PDVD는 `stepped_center_fallback`, `relax_containment_filter` 인자를 추가로 받는다.
- 반환: `{per_face, per_apa, per_group, all_tpc}`. 각 단계는 `MultiAlgBlobClustering`이고 Bee용 `mabc-*.zip`을 쓴다.
- drift group: PDHD `group02`(APA 0, 2, face 0), `group13`(APA 1, 3, face 1). PDVD `group0123`, `group4567`.
- `drift_speed`는 `1.6mm/us`로 하드코딩되어 있다(HD:22, VD:26). `params.lar.drift_speed`를 쓰지 않는다.

## 7. Utility: `funcs.jsonnet`, `magnify-sinks.jsonnet`, `sim.jsonnet`

**`funcs.jsonnet`**

| 함수 | PDHD | PDVD |
|---|---|---|
| `fanpipe` | fanout tag `.*` -> `orig` 고정, fanin rule은 `raw`/`gauss`/`wiener`/`threshold`/`dnnsp` 하드코딩 (HD:9-78) | `fout_tag_rules`, `fin_tag_rules`를 인자로 받음 (VD:102-134) |
| `splat` | `DepoBagger` -> `DepoFluxSplat` -> `Retagger(deposplat%d)` (HD:81-135) | 없음 |
| `anode_channels(n)` | 없음 | anode별 1536 channel 목록 (VD:24-30) |
| `fansummer`, `anode_split` | 없음 | 구버전 split-anode ident(`anode110` 등) 기준 helper (VD:33-98) |
| `drift_velocity(efield, temperature)` | 없음 | LAr drift velocity parametrization [mm/us] (VD:142-190) |

**`magnify-sinks.jsonnet`**
- 시그니처(공통): `function(tools, outputfile, runinfo=null)`.
- `orig`, `raw`, `decon`, `decon_trun`, `debug`, `truth`, `threshold`, DNN 결과 pipe를 anode별로 반환한다.
- DNN pipe 이름: PDHD `dnnsp_pipe`, PDVD `dndecon_pipe`.
- truth tag: PDHD `deposplat%d`, PDVD `ductor%d`.

**`sim.jsonnet`**
- `DepoTransform` -> `Reframer` -> [`AddNoise`] -> `Digitizer`를 anode별 pipeline으로 만들고 `signal`/`splusn` fan graph로 묶는다.
- PDHD: anode별 PIR(`tools.pirs[n]`), noise `params.files.noise`.
- PDVD: bottom `pirs[0]`, top `pirs[1]`, noise `params.files.noises[top?1:0]`.
  자체 `Digitizer`를 쓴다(bottom baseline `[1003.4,1003.4,507.7]mV`, top baseline `1.0V`, fullscale `[0,2]V`).

## 8. Entry 파일

### 8.1 처리 흐름과 FHiCL 대응

| 파일 | 처리 흐름 | `inputers` | 실제 연결된 `outputers` |
|---|---|---|---|
| `wcls-nf` | Raw -> ChSel -> [Resampler] -> NF | `wclsRawFrameSource` | `wclsFrameSaver:nfsaver` |
| `wcls-nf-sp` | Raw -> ChSel -> [Resampler] -> NF -> SP(+L1SP) | `wclsRawFrameSource` | `wclsFrameSaver:spsaver` |
| `wcls-nf-sp-dnnroi` | ... -> NF -> SP -> DNN-ROI(`dnnroi_pp`) -> L1SP(`hybrid`) | `wclsRawFrameSource` | HD: `spsaver`, `tradspsaver`. VD: `spsaver` |
| `wcls-nf-sp-img` | ... -> NF -> SP -> imaging | `wclsRawFrameSource` | 없음 (`ClusterFileSink` 파일만) |
| `wcls-nf-dnnsp-img` | ... -> NF -> SP -> DNN-ROI -> L1SP -> imaging | `wclsRawFrameSource` | `spsaver` (DNN 이전 SP) |
| `wcls-rawdigit-sp` | NF 출력 RawDigit -> ChSel -> SP | `wclsRawFrameSource` | `wclsFrameSaver:spsaver` |
| `wcls-sim-drift-deposplat` | depo -> Drifter -> sim / truth splat -> SP -> DNN-ROI | `wclsSimDepoSource` (`art_tag: IonAndScint`) | 없음 (HDF5 파일만) |

### 8.2 `std.extVar` 목록

`params`(fcl)는 문자열로, `structs`(fcl)는 jsonnet code로 전달된다. 표의 "형식"은 jsonnet이 기대하는 형식이다.

| extVar | 형식 | 사용 파일 |
|---|---|---|
| `reality` | 문자열 (`'data'` 비교) | 모든 wcls entry (deposplat 제외) |
| `raw_input_label` | 문자열 | 모든 wcls entry (deposplat 제외) |
| `signal_output_form` | 문자열 (`'sparse'` 비교) | 모든 wcls entry. `wcls-nf`에서는 평가되지 않음 |
| `epoch` | 문자열 | HD `wcls-nf-sp`, `wcls-nf-sp-dnnroi`, `wcls-rawdigit-sp`, VD `wcls-nf-sp`, `wcls-nf-sp-dnnroi`. **모두 미사용** |
| `use_resampler` | 문자열 (`'true'` 비교) | VD `wcls-nf`, `wcls-nf-sp`, `wcls-nf-sp-dnnroi`, `wcls-rawdigit-sp`(미사용) |
| `use_magnify` | 문자열 (`'true'` 비교) | VD `wcls-nf`, `wcls-nf-sp`, `wcls-rawdigit-sp`, 양쪽 `wcls-nf-sp-img`, `wcls-nf-dnnsp-img` |
| `clock_speed` | 숫자 | HD `wcls-nf`, `wcls-rawdigit-sp` (`tick = 1/clock_speed us`) |
| `use_dnnroi` | boolean | 양쪽 `wcls-nf-sp-dnnroi`, VD `wcls-nf-sp` |
| `dnn_roi_model`, `inference_service`, `triton_url`, `use_ssl` | 문자열 / code | VD `wcls-nf-sp` (`use_dnnroi`가 참일 때) |
| `Nbit`, `elecGain` | 숫자 | `dune/params.jsonnet`, HD `params.jsonnet` |

- `use_dnnroi`를 fcl `params`로 문자열 `"false"`를 넘기면 jsonnet `if`에서 type 오류가 난다. `structs`로 넘겨야 한다.
- `wirecell_dune.fcl`의 `protodunehd_nfsp_dnnroi`, `protodunevd_nfsp`는 `use_dnnroi`를 `structs`에 둔다.

### 8.3 Entry 파일별 PDHD/PDVD 차이

| 파일 | PDHD | PDVD |
|---|---|---|
| `wcls-nf` | input tick `512ns` 고정, resampler `reality == 'data'` | input tick `use_resampler`에 따라 `512`/`500ns`, bottom만 resample. `use_magnify` 지원 |
| `wcls-nf-sp` | `spsaver` scale `0.001` | `spsaver` scale `0.005`. `use_dnnroi`이면 `dune-vd/dnnroi.jsonnet` 사용 (TorchService/TritonService 선택) |
| `wcls-nf-sp-dnnroi` | DNN-ROI 모델 `.../dnn-roi/pdhd/20260615/pipe_distill_transformer_6ch.ts`, L1SP 모델 `l1sp_dnn_pdhd_v1.ts`. `tradspsaver` 추가 | `.../pdvd/20260615/pipe_distill_transformer_6ch.ts`, `l1sp_dnn_pdvd_v1.ts`. top/bottom L1SP threshold |
| `wcls-nf-sp-img` | resampler `reality == 'data'`. 4 APA 모두 | resampler 없음, input tick 미지정. **`anodes[5]` 하나만 처리** (VD:21-29). `use_magnify == 'true'`이면 NF를 건너뜀 |
| `wcls-nf-dnnsp-img` | DNN-ROI 모델 `dnnroi/pdhd/pipe_distill_transformer_6ch.ts`, `img({use_dnn_img:true})` | `dnnroi/pdvd/pipe_distill_nestedunet_6ch.ts`, `img()`. resampler 없음 |
| `wcls-rawdigit-sp` | tick `1/clock_speed`, `summary_tags: ['threshold']` | tick `params.daq.tick`, summary 없음 |
| `wcls-sim-drift-deposplat` | truth: `util.splat`(`DepoFluxSplat`, tag `deposplat%d`). magnify 출력 | truth: `make_ductor(..., 'DepoSplat')`. `anodes[0]`만 처리 (두 detector 공통) |
| `wct-sim-check` | `DL 6.2`, `DT 16.3cm2/s`, lifetime `50ms`, drift `1.565mm/us` override | simparams 그대로 |
| `wct-sim-fans` | track `thetaXZ 45deg`, $x=-100$ | track `0deg`, $x=+100$ (top) |

## 9. 관찰된 문제

| # | 파일 | 내용 | 확인 |
|---|---|---|---|
| 1 | HD `wcls-nf`, `wcls-nf-sp`, `wcls-nf-sp-dnnroi`, `wcls-nf-sp-img`, `wcls-nf-dnnsp-img` | input tick이 `reality`와 무관하게 `512ns`이고, sim에서는 resampler가 빠진다. sim tick은 `0.5us`이므로 MC frame이 `512ns`로 표기된다 (`docs/04` 2.4절, 7절) | 확인 |
| 2 | VD `wcls-nf-sp.jsonnet:252-254` | `use_dnnroi`가 참이면 `mio.dnnroi_pipe[n]`을 참조하지만 VD `magnify-sinks.jsonnet`에는 `dnnroi_pipe`가 없다 (`dndecon_pipe`만 있음). 평가 오류가 날 것으로 보인다 | 확인 |
| 3 | 양쪽 `wcls-nf-dnnsp-img` (HD:340, VD:293) | `g.pipeline([source, fanpipe], retagger)`: `retagger`가 `pipeline(elements, name)`의 `name` 인자로 들어간다. Retagger와 `dnnsaver`는 graph에 포함되지 않는다 | 확인 |
| 4 | VD `wcls-sim-drift-deposplat` (`:179`, `:213`) | truth HDF5 tap은 `ductor%d` tag를 기대하지만 `make_ductor`는 `frame_tag` 없이 호출된다 (기본 `''`) | 확인 |
| 5 | HD `wcls-nf-dnnsp-img`, `wcls/wct-sim-drift-deposplat`, VD `wcls-nf-dnnsp-img`, `wcls-nf-sp` | SP override key 오타: `save_negtive_charge`, `m_save_negative_charge`. `OmnibusSigProc`의 key는 `save_negative_charge` (`OmnibusSigProc.cxx:197`)이므로 무시된다 | 확인 |
| 6 | VD `wcls-nf-sp-img.jsonnet:21-29` | `tools.anodes`를 `anodes[5]` 하나로 덮어쓴다. `protodunevd_nfspimg` 블록은 anode 5만 imaging한다 | 확인 |
| 7 | 사용처 | `dnnroi.jsonnet`, `dnnroi_mp.jsonnet`, `clus.jsonnet`은 두 디렉터리의 어떤 파일도 import하지 않는다 | 확인 |
| 8 | `sp.jsonnet` 기본 L1SP | `make_sigproc`를 인자 없이 부르면 L1SP envelope이 붙는다. 마지막 merge가 `gauss`를 `wiener`에 덮어쓰고 debug/threshold tag를 버린다. 또 `raw%d`가 필요하므로 NF가 없는 graph(`wcls-rawdigit-sp`, `*-deposplat`, `wct-sim-fans`)에서는 L1SP 입력이 없다 | 코드 읽기 |
| 9 | HD `wcls-nf-dnnsp-img` | `img({use_dnn_img:true})`는 `dnnsp%d`를 읽지만 L1SP envelope이 `dnnsp%d`를 `gauss%d`/`wiener%d`로 바꾼다. imaging 입력이 비어 있을 수 있다 | 코드 읽기 |
| 10 | VD `params.jsonnet:140` | bottom gain이 `7.8mV/fC`로 고정이다. fcl의 `elecGain`은 bottom에 영향이 없다 | 코드 읽기 |
| 11 | VD `chndb-base.jsonnet:62-423` | 360개 coherent group을 anode 구분 없이 모든 NF에 넘긴다. 다른 CRP channel의 처리 방식은 C++에서 확인하지 않았다 | 코드 읽기 |
| 12 | VD `chndb-base`, `sp` 주석 | 주석의 수치(top `postgain 1.52`, RMS cut 값, L1SP threshold 기준 `14mV/fC`)가 코드와 다르다 | 코드 읽기 |
| 13 | VD `funcs.jsonnet` | `anode_split`, `fansummer`(16 -> 8 고정 배선)는 구버전 split-anode ident 기준이다. 현재 ident `0-7`과 맞지 않는다 | 코드 읽기 |
| 14 | `clus.jsonnet`, `img.jsonnet` | `clus`의 `drift_speed`가 `1.6mm/us` 하드코딩이다. `img.dump()`의 `drift_speed` 인자는 사용되지 않는다 | 코드 읽기 |
| 15 | DNN 모델 경로 | `wcls-nf-sp-dnnroi`는 `/cvmfs/dune.osgstorage.org/...` 절대 경로를 쓰고, `wcls-nf-dnnsp-img`/deposplat은 `WIRECELL_PATH` 기준 상대 경로를 쓴다. PDVD는 파일에 따라 모델 종류(`transformer` vs `nestedunet`)도 다르다 | 코드 읽기 |
| 16 | `epoch` extVar | 5개 entry 파일에서 읽기만 하고 쓰지 않는다 | 코드 읽기 |
