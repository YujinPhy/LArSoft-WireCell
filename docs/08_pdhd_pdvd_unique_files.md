# dunereco `wire-cell-cfg`: PDHD / PDVD 한쪽에만 있는 설정 파일

공식 dunereco 배포본에서 `pgrapher/experiment/pdhd/` 또는 `pgrapher/experiment/protodunevd/`
**한쪽에만 있는** 22개 파일(PDHD 10개, PDVD 12개)을 정리한다. 양쪽에 모두 있는 파일은
`docs/07_pdhd_pdvd_common_files.md`를 참고한다.

- 대상: `$D = /cvmfs/dune.opensciencegrid.org/products/dune/dunereco/v10_26_00d01/wire-cell-cfg/pgrapher/experiment`
- 표기: `파일:n`은 해당 파일의 n번째 줄이다.
- FHiCL 사용처는 CVMFS `dunereco`, `dunesw`, `duneprototypes`, `dunesim` `v10_26_00d01`의 `fcl/`을 grep한 결과이다.
  `wirecell_dune.fcl` 줄 번호는 dunereco 원본 기준이다(local 사본과 다를 수 있다).
- 확인일: 2026-10-12
- 검증 수준: 모든 파일을 코드 읽기로 정리했다. 5절의 "확인" 표시는 해당 줄을 직접 다시 열어 확인한 항목이다.

## 1. 목록과 대응 관계

| PDHD 전용 | 분류 | PDVD에서 같은 역할 |
|---|---|---|
| `chndb-resp.jsonnet` | NF 응답 kernel | `chndb-resp-bot.jsonnet`, `chndb-resp-top.jsonnet` |
| `pdhd-coh-groups.jsonnet` | coherent noise group | `chndb-base.jsonnet` 안에 inline |
| `pdhd-femb-negpulse-groups.jsonnet` | FEMB negative pulse group | 없음 |
| `femb-negpulse-groups-shifted_v2.jsonnet` | 구버전 group (미사용) | 없음 |
| `wcls-sp.jsonnet` | wcls entry: recob::Wire 입력 SP | 없음 |
| `wcls-rawdigit-dnnsp.jsonnet` | wcls entry: NF 출력 -> SP + DNN-ROI | 비슷한 것: `wcls-nf-sp.jsonnet` (`use_dnnroi`) |
| `wcls-sp-dnn-l1sp.jsonnet` | wcls entry: NF 출력 -> SP + DNN-ROI + L1SP | 비슷한 것: `wcls-nf-sp-dnnroi.jsonnet` (NF 포함) |
| `wcls-img.jsonnet` | wcls entry: SP 출력 -> imaging | 비슷한 것: `wct-img.jsonnet`, `wct-img-all.jsonnet` (단독 실행) |
| `wcls-sim-drift-simchannel-priorSCE-depoflux.jsonnet` | wcls sim (production) | `wcls-sim-drift-depoflux.jsonnet` |
| `wcls-sim-drift-simchannel-priorSCE.jsonnet` | wcls sim (SimChannel 방식) | `wcls-sim-drift-simchannel.jsonnet` |

| PDVD 전용 | 분류 | PDHD에서 같은 역할 |
|---|---|---|
| `chndb-resp-bot.jsonnet` | NF 응답 kernel (bottom) | `chndb-resp.jsonnet` |
| `chndb-resp-top.jsonnet` | NF 응답 kernel (top) | `chndb-resp.jsonnet` |
| `chndb-perfect.jsonnet` | "perfect" noise DB (미사용) | PDHD sim 파일은 `pdsp/chndb-perfect.jsonnet` import |
| `wcls-nf-sp-out.jsonnet` | wcls entry: NF + SP + anode별 frame 파일 출력 | 비슷한 것: `wcls-nf-sp.jsonnet` |
| `wcls-sim-drift-depoflux.jsonnet` | wcls sim (production) | `wcls-sim-drift-simchannel-priorSCE-depoflux.jsonnet` |
| `wcls-sim-drift-simchannel.jsonnet` | wcls sim (SimChannel 방식) | `wcls-sim-drift-simchannel-priorSCE.jsonnet` |
| `wcls-sim-drift-simchannel-splusn.jsonnet` | wcls sim: signal과 signal+noise 둘 다 저장 | 없음 |
| `wcls-sim-drift-y-simchannel.jsonnet` | wcls sim: drift 축이 $y$인 geometry | 없음 |
| `wct-img.jsonnet` | wct entry: frame 파일 -> imaging (anode 5) | 없음 |
| `wct-img-all.jsonnet` | wct entry: frame 파일 -> imaging (anode 전체) | 없음 |
| `wct-sim-check-dnnsp.jsonnet` | wct entry: sim -> NF -> SP -> DNN-ROI 점검 | `wct-sim-check.jsonnet` (DNN 없음) |
| `wct-sim-sigproc-fans.jsonnet` | wct entry: sim -> SP 점검 (magnify) | `wct-sim-fans.jsonnet` |

## 2. PDHD 전용

### 2.1 NF 데이터 파일

**`chndb-resp.jsonnet`**
- `{u_resp, v_resp}`: coherent noise 제거에 쓰는 FR⊗ER kernel. U, V 각각 200 sample.
- 생성 조건(주석 1-11행): `wirecell-sigproc track-response -d pdhd`, FR `dune-garfield-1d565.json.bz2`,
  gain `14mV/fC`, shaping `2.2us`, tick `500ns`. 최솟값 위치는 U `127`, V `132`이다.
- 사용처: `chndb-base.jsonnet:5`. `gain_scale = elec.gain/14mV/fC`로 scale한다. APA0의 V는 kernel을 쓰지 않는다.
- APA0의 FR은 `np04hd-garfield-6paths-mcmc-bestfit.json.bz2`(`params.jsonnet:173`)이므로,
  APA0 U kernel은 실제 FR과 다른 FR(`1d565`)로 만든 것이다.

**`pdhd-coh-groups.jsonnet`**
- `groups[4][60]`: anode별 coherent noise group. U FEMB 20개(40 channel씩), V FEMB 20개(40), W FEMB 20개(48).
- 출처: `PD2HDChannelMap_WIBEth_visiblewires_v1.txt` (주석 2-3행).
- 사용처: `chndb-base.jsonnet:6`, `groups: coh_groups.groups[n]` (`:46`).

**`pdhd-femb-negpulse-groups.jsonnet`**
- half-FEMB 단위 group 160개(4 anode × 20 FEMB × 2), 64 channel씩.
- 사용처: `chndb-base.jsonnet:7`, `femb_negpulse_groups` (`:48`) -> `nf.jsonnet`의 `PDHDFEMBNoiseSub`.
  160개 전체를 모든 anode에 넘긴다.
- 주석(14-16행)에 따르면 `femb-negpulse-groups`, `-shifted`, `-shifted_v2`, `-shifted_v3`를 대체한다.

**`femb-negpulse-groups-shifted_v2.jsonnet`**
- 위 파일의 구버전이다(U/V에 APA별 ±3 channel cyclic shift).
- import하는 파일이 없다. 주석이 가리키는 `femb-negpulse-groups.jsonnet`과 `coh_group_shift`도 현재는 없다.

### 2.2 Entry 파일 (reco)

| 파일 | 처리 흐름 | 입력 | 출력 | FHiCL 블록 |
|---|---|---|---|---|
| `wcls-sp.jsonnet` | recob::Wire -> ChSel -> 빈 NF(bad channel mask만) -> SP | `wclsCookedFrameSource` (`recobwire_tags: [raw_input_label]`) | `wclsFrameSaver:spsaver` (`gauss`, `wiener`, `summary_tags: ['threshold']`) | `protodunehddata_wctsp` |
| `wcls-rawdigit-dnnsp.jsonnet` | NF 출력 RawDigit -> ChSel -> SP -> DNN-ROI(`dnnroi_pp`) | `wclsRawFrameSource` (`tick: params.daq.tick`) | `spsaver`(DNN 이전 SP, splice), `dnnsaver`(`dnnsp`) | `protodunehd_dnnsp` |
| `wcls-sp-dnn-l1sp.jsonnet` | NF 출력 RawDigit -> ChSel -> SP -> DNN-ROI -> L1SP(`hybrid`) | `wclsRawFrameSource` (data `500ns`, sim `512ns`) | `spsaver`, `tradspsaver` | `protodunehd_sp_dnn_l1sp(_mc)` |
| `wcls-img.jsonnet` | recob::Wire gauss + wiener -> ChSel -> imaging | `wclsCookedFrameSource:charge`, `wclsCookedFrameSource:wiener` | 없음 (`ClusterFileSink` 파일) | `protodunehd_img` |

`std.extVar`:
- `wcls-sp`: `epoch`(미사용), `reality`, `signal_output_form`, `raw_input_label`
- `wcls-rawdigit-dnnsp`: `reality`, `signal_output_form`, `raw_input_label`, `clock_speed`(숫자, `tick = 1/clock_speed us`)
- `wcls-sp-dnn-l1sp`: `epoch`(미사용), `reality`, `signal_output_form`, `raw_input_label`, `use_dnnroi`(boolean, `structs`로 전달)
- `wcls-img`: `reality`, `charge_input_label`, `wiener_input_label`

주요 설정:
- `wcls-sp-dnn-l1sp`는 `wcls-nf-sp-dnnroi`를 둘로 나눈 것의 뒷부분이다. 앞부분은 `wcls-nf.jsonnet`(`raw` RawDigit 저장)이다.
  - DNN-ROI 모델: `/cvmfs/dune.osgstorage.org/.../dnn-roi/pdhd/20260615/pipe_distill_transformer_6ch.ts` (`:65`)
  - L1SP 모델: `.../l1sp/pdhd/20260615/l1sp_dnn_pdhd_v1.ts` (`:90`)
  - L1SP: `hybrid`, threshold `0.5`, `gmax_min 1500`, `min_length 30`, `energy_frac 0.66`
- `wcls-rawdigit-dnnsp`: resampler가 없다. 입력 tick은 `1/ClockSpeedTPC`이다.
  모델은 상대 경로 `dnnroi/pdhd/pipe_distill_transformer_6ch.ts`(`:284`)를 쓴다.
- `wcls-img`: `pdhd/img.jsonnet`의 기본 `"multi"` pipe(active + masked)를 쓴다.

### 2.3 Entry 파일 (sim)

| 항목 | `wcls-sim-drift-simchannel-priorSCE-depoflux` | `wcls-sim-drift-simchannel-priorSCE` |
|---|---|---|
| 처리 흐름 | DepoSet source -> `DepoSetDrifter` -> `wclsDepoFluxWriter` -> sim(S+N) -> `simdigits` | Depo source -> `Drifter` -> `wclsSimChannelSink` -> bagger -> sim(S+N) -> `simdigits` |
| 입력 | `wclsSimDepoSetSource:electron` (`art_tag: IonAndScint`, `assn_art_tag: ""`) | `wclsSimDepoSource` (`art_tag: IonAndScint`, `assn_art_tag: IonAndScint:priorSCE`) |
| truth 출력 | `wclsDepoFluxWriter:postdrift` (`simpleSC`, tick `0.5us`, 6000 tick, `energy: 1`) | `wclsSimChannelSink:postdrift` (`simpleSC`, tick `0.5us`, `u/v/y_to_rp 100mm`) |
| digit 출력 | `wclsFrameSaver:simdigits` (`daq`) | 같음 |
| `std.extVar` | `DL`, `DT`, `lifetime`, `driftSpeed` | 같음 |
| FHiCL | `wirecell_protodunehdmc` (`wirecell_protodunespmc` 상속) | 없음 |

- 이름에 "priorSCE"가 있지만 depoflux 버전은 `assn_art_tag`가 비어 있어서(`:63`) prior-SCE association을 쓰지 않는다.
  prior-SCE를 실제로 쓰는 것은 depoflux가 아닌 버전(`:48`)이다.
- 두 파일 모두 `pdsp/chndb-perfect`, `pdsp/nf`, `pdsp/sp`를 import하지만 graph에는 쓰지 않는다.

## 3. PDVD 전용

### 3.1 NF 데이터 / library 파일

| 파일 | 내용 | 사용처 |
|---|---|---|
| `chndb-resp-bot.jsonnet` | bottom(anode `0-3`) kernel, U/V 각 320 sample. FR `protodunevd_FR_imbalance3p_260501.json.bz2`, gain `7.8mV/fC`, `postgain 1.1365`. 최솟값 U `239`, V `245` | `chndb-base.jsonnet:5`, `gain/7.8mV/fC`로 scale |
| `chndb-resp-top.jsonnet` | top(anode `4-7`) kernel, 320 sample. ER `dunevd-coldbox-elecresp-top-psnorm_400.json.bz2`, `postgain 1.52`. 최솟값 U `240`, V `243` | `chndb-base.jsonnet:6`, scale `1.0` |
| `chndb-perfect.jsonnet` | `function(params, anode, field, n)`, group만 있는 noise DB | sim entry 3개가 import하지만 graph에 쓰지 않는 `nf_pipes`에만 들어가므로 평가되지 않음 |

- `chndb-resp-bot.jsonnet` 주석(13-21행): `postgain 1.1365`는 FR W-plane 정규화 차이를 흡수한 값이고
  배열은 의도적으로 다시 만들지 않았다. 반면 현재 `params.jsonnet`의 bottom `postgain`은 `1.0`이다.
- `chndb-perfect.jsonnet:22-24`의 group 공식은 PDHD/PDSP 배치(`n*2560`, U/V 40, W 48)를 그대로 쓴다.
  PDVD channel 배치(anode당 1536)와 맞지 않는다.

### 3.2 Entry 파일 (reco / imaging)

| 파일 | 처리 흐름 | 입력 | 출력 |
|---|---|---|---|
| `wcls-nf-sp-out.jsonnet` | Raw -> ChSel -> [Resampler, bottom] -> NF -> SP -> anode별 `FrameFileSink` tap | `wclsRawFrameSource` (`use_resampler`면 `512ns`, 아니면 `500ns`) | `wclsFrameSaver:spsaver` (scale `0.005`) + 파일 `protodune-sp-frames-anode%d.tar.bz2` |
| `wct-img.jsonnet` | `FrameFileSource` -> imaging (`single`) -> `ClusterFileSink` | TLA `input` (기본 `protodune-sp-frames.tar.bz2`) | `clusters-apa-<anode>.tar.gz` |
| `wct-img-all.jsonnet` | anode별 `FrameFileSource` -> imaging -> `ClusterFileSink` | TLA `input_prefix`(기본 `protodune-sp-frames`), `anode_indices`(기본 8개 전부) | 같음 |

- 세 파일은 "SP 결과를 파일로 저장 -> 단독 `wire-cell` 실행으로 imaging"하는 2단계 흐름을 이룬다.
  `wct-img-all`의 입력 이름 규칙(`<prefix>-anode<ident>.tar.bz2`)은 `wcls-nf-sp-out`의 출력과 맞다.
  `wct-img`의 기본 입력 이름은 맞지 않는다.
- `wct-img.jsonnet`은 `tools_all.anodes[5]`(`:39`) 하나만 쓴다.
- `wcls-nf-sp-out.jsonnet`은 `signal_output_form`을 읽지 않고 `dense`로 고정한다(`:26`).
  import하는 파일이나 FHiCL 블록이 없다.

### 3.3 Entry 파일 (sim)

| 항목 | `wcls-sim-drift-depoflux` | `wcls-sim-drift-simchannel` | `wcls-sim-drift-simchannel-splusn` | `wcls-sim-drift-y-simchannel` |
|---|---|---|---|---|
| 입력 | `wclsSimDepoSetSource:electron` | `wclsSimDepoSource:electron` | `wclsSimDepoSource:electron` | `wclsSimDepoSetSource:` |
| drift | `DepoSetDrifter` | `Drifter` | `Drifter` | `DepoSetRotate`(축 교환 `[1,0,2]`, $y$ 반전) -> `DepoSetDrifter` |
| truth 출력 | `wclsDepoFluxWriter:postdrift` (`energy: 0`) | `wclsSimChannelSink:postdrift` | `wclsSimChannelSink:postdrift` | `wclsDepoSetSimChannelSink:postdrift` (`to_rp 189.5mm` 고정) |
| digit 출력 | `simdigits` | `simdigits` | `simsignals`(noise 없는 signal) + `simdigits` | `simdigits` |
| FHiCL | `wirecell_protodunevd_mc` | 없음 | `wirecell_protodunevd_mc_splusn` | `dunesw` `protodunevd_detsim_driftY.fcl:61-77` |

- `std.extVar`(4개 공통): `nticks`, `DL`, `DT`, `lifetime`, `efield`, `temperature`.
  drift speed는 `funcs.drift_velocity(efield, temperature)`로 계산한다.
  depoflux 버전에는 쓰이지 않는 `fcl_params`(`G4RefTime`, `apa_sparsity`, `use_dnnroi`, `dnn_model`)도 있다.
- PDHD production sim과 비교:

| 항목 | PDHD `...-priorSCE-depoflux` | PDVD `wcls-sim-drift-depoflux` |
|---|---|---|
| drift 파라미터 출처 | fcl `structs` `DL`, `DT`, `lifetime`, `driftSpeed` 직접 지정 | LArSoft service 값(`efield`, `temperature`)에서 계산 |
| `wclsDepoFluxWriter.energy` | `1` (`:183`) | `0` (`:188`) |
| window | 6000 tick | 6000 tick (`simparams` `nticks 6400`와 별개로 하드코딩) |

### 3.4 Entry 파일 (단독 점검)

| 파일 | 처리 흐름 | 출력 |
|---|---|---|
| `wct-sim-check-dnnsp.jsonnet` | track 6개 -> Drifter -> sim(S+N) -> NF -> SP -> DNN-ROI(`dnnroi_pp`, `output_scale 1.2`) | `protodunevd-sim-check-dnnsp.root` (magnify) |
| `wct-sim-sigproc-fans.jsonnet` | track 1개 -> Drifter -> sim(S+N) -> SP | `mag-sim-sp.root` (magnify) |

- `wct-sim-check-dnnsp.jsonnet:169`의 모델은 상대 경로 `dnnroi/pdvd/pipe_distill_nestedunet_6ch.ts`이다.
- `wct-sim-sigproc-fans.jsonnet`은 `wct-sim-fans.jsonnet`의 변형이다. imaging 대신 magnify와 SP fan-in을 켠다.

## 4. FHiCL 연결 요약

| 파일 | FHiCL 블록 (CVMFS `v10_26_00d01`) |
|---|---|
| PDHD `wcls-sp` | `protodunehddata_wctsp` |
| PDHD `wcls-rawdigit-dnnsp` | `protodunehd_dnnsp(_mc)` |
| PDHD `wcls-sp-dnn-l1sp` | `protodunehd_sp_dnn_l1sp(_mc)` |
| PDHD `wcls-img` | `protodunehd_img` |
| PDHD `wcls-sim-drift-simchannel-priorSCE-depoflux` | `wirecell_protodunehdmc` |
| PDVD `wcls-sim-drift-depoflux` | `wirecell_protodunevd_mc` |
| PDVD `wcls-sim-drift-simchannel-splusn` | `wirecell_protodunevd_mc_splusn` |
| PDVD `wcls-sim-drift-y-simchannel` | `protodunevd_detsim_driftY.fcl` (dunesw) |
| PDHD `wcls-sim-drift-simchannel-priorSCE`, PDVD `wcls-nf-sp-out`, PDVD `wcls-sim-drift-simchannel` | 없음 |
| `wct-*` | 없음 (`wire-cell` CLI로 직접 실행) |
| 데이터/library 파일 | `chndb-base.jsonnet`을 통해서만 사용. `femb-negpulse-groups-shifted_v2`, `chndb-perfect`(평가 안 됨)은 미사용 |

## 5. 관찰된 문제

| # | 파일 | 내용 | 확인 |
|---|---|---|---|
| 1 | PDHD `wcls-sp.jsonnet:218` | Retagger merge key 오타 `'theshold\\d': 'theshold'`. saver는 `threshold` summary를 기대한다(`:117`) | 확인 |
| 2 | PDHD `wcls-img.jsonnet:38` | wiener 입력의 `summary_tags`가 `'wclsdatahd:wiener'`로 하드코딩되어 있다. `wiener_input_label`을 바꿔도 따라가지 않는다 | 확인 |
| 3 | PDHD `wcls-sim-drift-simchannel-priorSCE-depoflux.jsonnet:63` | 이름과 달리 `assn_art_tag: ""`이다. prior-SCE association을 쓰지 않는다 | 확인 |
| 4 | `wclsDepoFluxWriter.energy` | PDHD `1`, PDVD `0`. 두 production sim의 설정이 다르다(의미는 larwirecell 소스에서 확인하지 않음) | 확인 |
| 5 | PDVD `chndb-perfect.jsonnet:22-24` | group 공식이 PDHD/PDSP channel 배치(`n*2560`)이다. 현재는 평가되지 않으므로 영향은 없다 | 확인 |
| 6 | PDHD `wcls-sp-dnn-l1sp.jsonnet:120` | sim 입력 tick을 `512ns`로 둔다. 주석은 "native 512 ns DAQ tick"이지만 `simparams.jsonnet:111`의 sim tick은 `0.5us`이다 (`docs/04` 7절) | 확인 |
| 7 | 상대 경로 DNN 모델 | `dnnroi/pdhd/pipe_distill_transformer_6ch.ts`(PDHD `wcls-rawdigit-dnnsp`), `dnnroi/pdvd/pipe_distill_nestedunet_6ch.ts`(PDVD `wct-sim-check-dnnsp`)는 `$D/..`, WCT release, `dune_pardata`에 없다. CVMFS `dune.osgstorage.org`의 `dnn-roi/pdvd/20260615/`에는 `transformer` 모델만 있고 `nestedunet`은 없다 | 확인 (파일 탐색) |
| 8 | PDHD `chndb-resp.jsonnet` | APA0 U kernel이 APA0 FR(`np04hd-...-mcmc-bestfit`)이 아닌 `1d565` FR로 만들어졌다 | 코드 읽기 |
| 9 | PDHD `wcls-rawdigit-dnnsp.jsonnet:121-124` | `summary_tags: ['wiener']`인데 `summary_operator` key는 `threshold`이다 | 코드 읽기 |
| 10 | PDVD `wcls-sim-drift-simchannel-splusn` | `simsignals`의 `frame_scale`(ADC/mV 비)을 bottom ADC 설정(`1.4V`)으로 한 번 계산해서 top에도 쓴다. top Digitizer는 `2V` fullscale이다 | 코드 읽기 |
| 11 | PDVD `wcls-sim-drift-y-simchannel.jsonnet:231` | "FIXME: need a bagger to gate depos" 주석대로 graph에 bagger가 없다 | 코드 읽기 |
| 12 | PDVD `wct-img.jsonnet` | anode 5 하나로 고정. 기본 입력 이름이 `wcls-nf-sp-out` 출력 이름과 다르다 | 코드 읽기 |
| 13 | PDHD `femb-negpulse-groups-shifted_v2.jsonnet` | 미사용. `pdhd-femb-negpulse-groups.jsonnet`으로 대체됨 | 확인 (import grep) |
