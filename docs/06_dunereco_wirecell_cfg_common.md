# dunereco `wire-cell-cfg`: `pgrapher` 공통 설정 파일

공식 `dunereco` 배포본의 `wire-cell-cfg/pgrapher` 아래에서 `experiment/`를 제외한 공통 설정 파일을 정리한다.

- 대상 경로: `/cvmfs/dune.opensciencegrid.org/products/dune/dunereco/v10_26_00d01/wire-cell-cfg/pgrapher`
  (이하 `$D`)
- 비교 기준: WCT release `wirecell v0_37_1`의 `share/wirecell` (이하 `$R`)
- jsonnet 평가: SL7 container, `gojsonnet v0_18_0a`, `jsonnet -J $R -J $D`
  (`$D` 우선, 2절 참고)
- 확인일: 2026-10-12

## 1. 파일 목록

| 파일 | 줄 | top-level 형태 | 역할 | `$R` 대비 | `experiment/`에서 import |
|---|---|---|---|---|---|
| `common/params.jsonnet` | 251 | object | 모든 detector parameter의 기본값 | 동일 | `dune10kt-vd` 1개 (나머지는 `dune/params` 경유) |
| `dune/params.jsonnet` | 14 | object | `common/params` + DUNE 공통 override (`Nbit`, `elecGain`) | 다름 | 11개 detector의 `params.jsonnet` |
| `common/tools.jsonnet` | 191 | `function(params)` | non-INode tool component 구성 (wire, FR, ER, PIR, anode, DFT, RNG) | 다름 | 12개 detector, 91개 파일 |
| `common/sim/nodes.jsonnet` | 319 | `function(params, tools)` | simulation pnode (Drifter, Ductor, DepoTransform, Digitizer 등) | 다름 | 12개 detector의 `sim.jsonnet` |
| `common/sim/depos.jsonnet` | 51 | `function(params, tools)` | depo source pnode (Ar39, TrackDepos, JsonDepoSource) | 동일 | 없음 (`sim/nodes`가 merge) |
| `common/sim/ar39nodes.jsonnet` | 30 | - | Ar39 `BlipSource` (구버전) | 동일 | 없음. **parse 불가** |
| `ui/wcls/nodes.jsonnet` | 91 | `function(params, tools)` | larwirecell 입출력 converter pnode (`wclsSimDepoSource`, `wclsRawFrameSource`, `wclsFrameSaver`) | 다름 | 12개 detector, 63개 파일 |
| `common/pgraph.jsonnet` | 374 | object | graph 구성 helper (`pnode`, `pipeline`, `edges`, `uses`, `fan.*`) | `$R/pgraph.jsonnet`과 다름 (`$R/pgrapher/common`에는 없음) | 직접 import 없음. `common/` 안 파일이 사용 (2절) |
| `common/funcs.jsonnet` | 212 | object | `fanpipe`/`fansink`/`fanout` alias + `multifanpipe`/`multifanout`/`multifanin` | 동일 | 12개 detector, 81개 파일 |
| `common/resamplers.jsonnet` | 16 | `function(g, wc, tools)` | anode별 `Resampler` (`500ns`, `linear`) | 동일 | `pdhd`(5), `protodunevd`(3) |
| `common/fileio.jsonnet` | 41 | object | `NumpyFrameSaver`, `NumpyDepoSaver` pnode | `$R`에 없음 | 12개 detector, 52개 파일 (주로 sim) |
| `common/io.jsonnet` | 33 | - | `fileio.jsonnet`의 구버전 | 동일 | 없음. **parse 불가** |
| `common/helpers.jsonnet` | 15 | - | WCT의 `helpers/*.jsonnet` 묶음 | `$R`에 없음 | 없음. **import 불가** |

- "`experiment/`에서 import" 열은 `import "pgrapher/<파일>"` 형태의 문자열을 `$D/pgrapher/experiment` 전체에서 grep한 결과이다.
- 실제로 쓰이는 핵심 파일은 `common/params` -> `dune/params` -> `common/tools` -> `ui/wcls/nodes` 계열이다.
  `helpers`, `io`, `ar39nodes`는 사용처가 없고 단독으로 평가하면 오류가 난다.

## 2. Import 경로 해석 규칙

두 규칙이 겹쳐서 어떤 파일이 실제로 쓰이는지가 정해진다.

1. **`WIRECELL_PATH` 순서**: 앞쪽 항목이 우선한다. WCT는 `WIRECELL_PATH`를 뒤에서부터
   `jsonnet_jpath_add`로 넣고(`util/src/Persist.cxx:356`), jsonnet은 마지막에 추가된 경로를 우선하므로
   결과적으로 첫 항목이 이긴다.
2. **상대 경로 우선**: jsonnet은 import 문자열을 먼저 *import하는 파일의 디렉터리* 기준으로 찾고,
   없을 때만 library path를 찾는다.

이 규칙 때문에 `import "pgraph.jsonnet"`은 import하는 파일의 위치에 따라 다른 파일로 해석된다.

| import하는 파일 위치 | `"pgraph.jsonnet"` 해석 결과 |
|---|---|
| `$D/pgrapher/common/*.jsonnet` (`funcs`, `fileio`, `io`) | 같은 디렉터리의 `$D/pgrapher/common/pgraph.jsonnet` |
| `$D/pgrapher/common/sim/*`, `$D/pgrapher/ui/wcls/*`, `$D/pgrapher/experiment/*/*` | `$R/pgraph.jsonnet` (WCT release) |

검증: `f.fanpipe(..., in_tag_rules=[])`가 `function has no parameter in_tag_rules`로 실패한다
(`in_tag_rules`는 `$R/pgraph.jsonnet`의 `fan.pipe`에만 있다). 같은 호출에서 `in_tag_rules`를 빼면 정상 평가된다.

즉 experiment 파일이 `funcs.fanpipe`를 쓰면 dunereco 사본 `pgraph`의 `fan.pipe`가,
`g.fan.pipe`를 직접 쓰면 WCT release `pgraph`의 `fan.pipe`가 호출된다.

## 3. 파일별 상세

### 3.1 `common/params.jsonnet`

모든 detector `params.jsonnet`의 최상위 base이다. detector 파일은 `super.<section> { ... }`로 일부만 override한다.

| section | 필드 | 기본값 | 비고 |
|---|---|---|---|
| `lar` | `DL`, `DT` | `7.2cm2/s`, `12.0cm2/s` | Drifter |
| | `lifetime` | `8ms` | Drifter |
| | `drift_speed` | `1.6mm/us` (500V/cm) | Drifter, `elec.fields.drift_dt`, imaging dump |
| | `density`, `ar39activity` | `1.389g/cm3`, `1Bq/kg` | Ar39 depo source |
| `det` | `volumes` | 예시 3개 (`onesided`, `twosided`, `anothertwosided`) | detector 파일에서 반드시 교체 |
| `daq` | `tick` | `0.5us` | `tools` sim response binning, `chndb` |
| | `nticks` | `10000` | readout 길이 |
| | `readout_time`, `stop_time` | `tick*nticks`, `start_time + nreadouts*readout_time` | 계산값 |
| | `nreadouts`, `start_time`, `first_frame_number` | `1`, `0s`, `100` | |
| `adc` | `gain`, `baselines`, `fullscale` | `1.0`, `[900, 900, 200]mV`, `[0, 2.0]V` | `resolution` 없음 (`dune/params`가 추가) |
| `elec` | `shaping`, `postgain` | `2.0us`, `1.0` | `gain` 없음 (`dune/params`가 추가) |
| | `fields.start_dx` | `10cm` | |
| | `fields.drift_dt`, `fields.nticks` | `start_dx/drift_speed`, `round(drift_dt/tick)` | 기본값으로 `62.5us`, `125` |
| `sim` | `nimpacts` | `10` | `AnodePlane.nimpacts` |
| | `fluctuate`, `continuous`, `fixed` | `true`, `true`, `false` | |
| | `depo_toffset` | `0.0` | Drifter `time_offset` |
| | `ductor.{nticks, readout_time, start_time}` | `daq.nticks + fields.nticks` 등 | `tools` sim response binning이 `ductor.nticks`를 씀 |
| | `reframer.{tbin, nticks}` | `fields.nticks`, `daq.nticks` | |
| `nf` | `nsamples` | `daq.nticks` | `chndb-base.jsonnet`, `wcls.input.digits` |
| `files` | `wires`, `fields`, `noise`, `chresp` | `null`, `[]`, `null`, `null` | detector 파일에서 지정 |

### 3.2 `dune/params.jsonnet`

```jsonnet
common_params {
    adc : super.adc { resolution: std.extVar("Nbit") },
    elec: super.elec { gain: std.extVar("elecGain")*wc.mV/wc.fC },
}
```

- fcl `structs`의 `Nbit`, `elecGain`이 여기서 처음 쓰인다. 두 extVar 중 하나라도 없으면
  `Undefined external variable` 오류가 난다(평가로 확인).
  `structs`로 넘기므로 숫자이다. `params`(문자열)로 넘기면 `Unexpected type string` 오류가 난다.
- 평가 결과(`Nbit=14`, `elecGain=14`): `adc.resolution=14`, `elec.gain=14mV/fC`,
  `daq.tick=0.5us`, `daq.nticks=10000`, `nf.nsamples=10000`, `elec.fields.nticks=125`.
- `$R/pgrapher/dune/params.jsonnet`은 extVar를 쓰지 않고 `resolution: 14`,
  `gain: 7.8mV/fC`로 고정한다. dunereco가 `WIRECELL_PATH`에서 앞서므로 공식 환경에서는 extVar 버전이 쓰인다.
- import하는 detector: `dune10kt-1x2x2`, `dune10kt-1x2x6`, `dune10kt-hd`, `dune-vd`, `dune-vd-coldbox`,
  `dunevd-crp2`, `dunevd-crp4`, `iceberg`, `pdhd`, `pdsp`, `protodunevd`.
  `dune10kt-vd/params-10kt.jsonnet`만 `common/params.jsonnet`을 직접 import한다.

### 3.3 `common/tools.jsonnet`

`local tools = tools_maker(params)`로 호출한다. 반환 object의 필드:

| 필드 | WCT type | 입력 `params` | 비고 |
|---|---|---|---|
| `random` | `Random` | - | `seeds: [0,1,2,3,4]` |
| `dft` | `FftwDFT` | - | 파일 주석에 `TorchDFT`로 바꾸는 `std.mergePatch` 예시가 있음 |
| `fields`, `field` | `FieldResponse` | `files.fields` | file 하나당 하나. `field = fields[0]` |
| `perchanresp`, `perchanresp_nameuses` | `ParamsPerChannelResponse` | `files.chresp` | `chresp: null`이면 `{name:"", uses:[]}` |
| `filter_responses`, `fltrespuses` | `FilterResponse` | `files.fltresp` | plane 3개. `null`이면 `uses: []` |
| `wires` | `WireSchemaFile` | `files.wires` | |
| `elec_resp` | `params.elec.type` 또는 `ColdElecResponse` | `elec.*` | 단일 ER (구버전 호환) |
| `elec_resps` | 동일 | `elecs` 또는 `[elec]` | `elecs`가 있으면 원소마다 하나 |
| `rc_resp` | `RCResponse` | `rc_resp.width` (없으면 `1.0ms`) | |
| `sys_resp` | `ResponseSys` | `sys_resp.*` | `params`에 `sys_resp`가 없으면 평가 시 오류 (sim에서만 평가됨) |
| `pirs` | `PlaneImpactResponse` | `sys_status`, `rc_resp.rc_layers`, `overall_short_padding` | FR 하나당 plane 3개. `elec_resps[n]` 사용 |
| `anodes`, `anode` | `AnodePlane` | `det.volumes`, `sim.nimpacts` | volume 하나당 하나. `anode = anodes[0]` |

- ER/RC/sys/PIR의 binning은 `tick: daq.tick`, `nticks: sim.ductor.nticks`로 고정된다.
- `$R`과의 차이: `$R`은 `elec_resp_for(n)`을 추가해서 elec 수가 FR 수보다 적으면 `elec_resps[0]`을 재사용한다.
  dunereco 사본은 `elec_resps[n]`을 그대로 쓰므로 `len(elecs) < len(fields)`이면 `pirs` 평가가 index 오류로 실패한다.
  PDHD(`fields` 4개, `elecs` 4개)와 PDVD(2개, 2개)는 수가 같아서 영향이 없다.
- Jsonnet은 lazy evaluation이므로 `sys_resp`, `pirs`처럼 NF/SP graph가 참조하지 않는 필드는 평가되지 않는다.

### 3.4 `common/sim/nodes.jsonnet`

`function(params, tools)`이고 결과에 `depos(params, tools)`(3.5절)를 merge한다.

| 필드 | WCT type | 비고 |
|---|---|---|
| `drifter` | `Drifter` | `xregions` = 모든 `det.volumes[].faces`의 unique list. `lar.*`, `sim.fluctuate`, `sim.depo_toffset` |
| `make_bagger()` | `DepoBagger` | gate = `[ductor.start_time, start_time + readout_time]` |
| `make_ductor(name, anode, pir_trio, type, frame_tag)` | `Ductor` | `frame_tag` 인자는 dunereco에만 있음 |
| `make_depotransform(name, anode, pirs)` | `DepoTransform` | |
| `make_depozipper(name, anode, pirs)` | `DepoZipper` | |
| `make_reframer(name, anode, tags)` | `Reframer` | `sim.reframer.*` |
| `make_anode_ductors`, `make_detector_ductors`, `ductors` | `Ductor` 묶음 | `ductors`는 `tools.pirs`별로 생성 |
| `make_wbdepo(anode, regions, mode, name)` | `WireBoundedDepos` | |
| `multi_ductor_graph`, `multi_ductor` | `DepoFanout`/`FrameFanin`/`Reframer`, `MultiDuctor` | |
| `misconfigure(params, chndbobj)` | `FrameSplitter`, `ChannelSelector`/`DBChannelSelector`, `Misconfigure`, `FrameMerger` | |
| `digitizer(anode, name, tag)` | `Digitizer` | `data: params.adc { anode, frame_tag }` |
| `frame_sink`, `depo_sink` | `DumpFrames`, `DumpDepos` | |

`$R`과의 차이:
- `$R`은 `xregions`에서 `null` face를 걸러낸다. dunereco 사본은 거르지 않으므로 `null` face가 있는
  parameter set(예: PDHD data `params.jsonnet`)으로 `drifter`를 만들면 `xregions`에 `null`이 들어간다.
  PDHD sim은 `simparams.jsonnet`(두 face 모두 정의)을 쓰므로 현재 경로에서는 해당되지 않는다.
- `$R`에만 `make_depotransform_withplane`(plane 단위 `DepoTransform`)이 있다.

### 3.5 `common/sim/depos.jsonnet`

| 필드 | WCT type | 비고 |
|---|---|---|
| `ar39(bb, name)` | `BlipSource` | `bb = det.bounds` 내부 균일, activity = `ar39activity * density * volume` |
| `tracks(tracklist, name, step)` | `TrackDepos` | `step` 기본 `1.0mm` |
| `jsondepos(name, file)` | `JsonDepoSource` | `model: "electrons"`, `scale: 1.0` |

### 3.6 `ui/wcls/nodes.jsonnet`

`local wcls = wcls_maker(params, tools)`로 호출한다.

| 필드 | WCT type | 주요 설정 |
|---|---|---|
| `input.depos(name, model, scale, art_tag, assn_art_tag)` | `wclsSimDepoSource` | `scale` 기본 `-1.0` (SimDepoSource 부호 보정) |
| `input.digits(arttag, name, tags, nticks)` | `wclsRawFrameSource` | `tags` 기본 `["orig"]`, `nticks` 기본 `nf.nsamples` |
| `output.digits(name, tags, cmm)` | `wclsFrameSaver` | `digitize: true` (`raw::RawDigit`), `anode: tools.anode` |
| `output.signals(tags, name, cmm)` | `wclsFrameSaver` | `digitize: false` (`recob::Wire`) |
| `output.thresholds(tags, name, cmm)` | `wclsFrameSaver` | `frame_scale: null`, `summary_tags` 기본 `["threshold"]` |

- 세 output 모두 `nticks: params.daq.nticks`, `anode: tools.anode`(첫 anode 하나)를 쓴다.
  multi-anode detector의 entry 파일(예: `pdhd/wcls-nf-sp.jsonnet`)은 이 함수를 쓰지 않고
  `MegaAnodePlane`을 쓰는 `wclsFrameSaver`를 직접 정의한다.
- `$R`과의 차이: `$R`은 `thresholds`의 기본 tag가 `["wiener"]`이다 (wiener RMS를 summary로 저장).

### 3.7 `common/pgraph.jsonnet`

graph 조립용 helper이다. 주요 함수:

| 분류 | 함수 |
|---|---|
| node/edge | `pnode(inode, nin, nout, uses, name)`, `port`, `edge`, `edge_labels` |
| subgraph | `pipeline(elements, name)`, `intern(...)`, `components`, `join_sources` |
| 삽입/분할 | `break_edge`, `break_insert_edge`, `insert_one`, `insert_node`, `splice` |
| 결과 추출 | `edges(graph)`, `uses(graph)`, `resolve_uses`, `strip_pnodes` |
| fan | `fan.fanout`, `fan.fanin`, `fan.pipe`, `fan.sink`, `fan.tap` |

- `$R/pgraph.jsonnet`과의 차이는 `fan.pipe`의 `in_tag_rules` 인자(fan-in 쪽 `tag_rules`) 하나다(6줄 diff).
- 2절대로 이 사본은 `common/` 디렉터리 안의 파일(`funcs`, `fileio`, `io`)에서만 쓰인다.

### 3.8 `common/funcs.jsonnet`

- 파일 머리 주석: 함수들은 `pgraph.jsonnet`의 `fan.` 아래로 옮겨졌으며, 이 파일은 하위 호환용으로만 남아 있다.
- `fanpipe`, `fansink`, `fanout`은 `g.fan.pipe`, `g.fan.sink`, `g.fan.fanout`의 alias이다.
  여기서 `g`는 dunereco 사본 `common/pgraph.jsonnet`이다.
- `multifanpipe`, `multifanout`, `multifanin`은 다단 fan(예: `fan_nnodes=[1,8,16]`)을 만든다.
  기본값은 APA 수가 많은 FD 구성에 맞춰져 있다.

### 3.9 `common/resamplers.jsonnet`

```jsonnet
function(g, wc, tools) { resamplers: [ Resampler{name:'resmp%d', period: 500ns, time_pad: "linear"} for each tools.anodes ] }
```

- `g`, `wc`를 인자로 받는다(파일 안의 import는 주석 처리됨).
- `uses=[tools.dft, tools.anodes[n]]`. PDHD/PDVD 사용 방식은 `docs/04_reality_data_vs_sim.md` 참고.

### 3.10 `common/fileio.jsonnet`

- `numpy.frames(fname, name, tags)`: `NumpyFrameSaver`. `tags`에 쉼표로 구분한 문자열도 받는다.
- `numpy.depos(fname, name)`: `NumpyDepoSaver`.
- `.npz` 파일이 이미 있으면 덮어쓰지 않고 이어서 쓴다(파일 주석).
- `celltree: {}`: 비어 있다.

## 4. 의존 관계

```
experiment/<det>/params.jsonnet
   └─ pgrapher/dune/params.jsonnet        (Nbit, elecGain extVar)
        └─ pgrapher/common/params.jsonnet

experiment/<det>/wcls-*.jsonnet
   ├─ params.jsonnet / simparams.jsonnet  (reality로 선택)
   ├─ pgrapher/common/tools.jsonnet       (params)
   ├─ pgrapher/ui/wcls/nodes.jsonnet      (params, tools)   -> $R/pgraph.jsonnet
   ├─ pgrapher/common/funcs.jsonnet                         -> $D/pgrapher/common/pgraph.jsonnet
   ├─ pgrapher/common/resamplers.jsonnet  (g, wc, tools)    [pdhd, protodunevd]
   └─ pgrapher/common/fileio.jsonnet                        -> $D/pgrapher/common/pgraph.jsonnet  [sim]

experiment/<det>/sim.jsonnet
   └─ pgrapher/common/sim/nodes.jsonnet   (params, tools)   -> $R/pgraph.jsonnet
        └─ pgrapher/common/sim/depos.jsonnet
```

## 5. 확인된 문제

| 파일 | 문제 | 확인 방법 |
|---|---|---|
| `common/io.jsonnet` | 최상위 object의 `}`가 빠져 있어 parse 불가 (`34:1 Expected a comma before next field`). `$R` 사본도 같다 | jsonnet 평가 |
| `common/sim/ar39nodes.jsonnet` | `import "ar39.jsonnet"` 뒤 `;` 누락으로 parse 불가 (`6:1-9 Expected , or ; but got "function"`). `g`, `v`도 import하지 않음 | jsonnet 평가 |
| `common/helpers.jsonnet` | `helpers/gen.jsonnet` 등을 import하지만 `$D`, `$R` 어디에도 없음 (`couldn't open import "helpers/gen.jsonnet"`) | jsonnet 평가 |
| `common/tools.jsonnet` | `len(elecs) < len(fields)`이면 `pirs`에서 index 오류. `$R`은 `elec_resp_for`로 처리 | 코드 비교 |
| `common/sim/nodes.jsonnet` | `drifter.xregions`에서 `null` face를 거르지 않음. `$R`은 거름 | 코드 비교 |
| `common/pgraph.jsonnet` | `$R/pgraph.jsonnet`보다 오래된 사본. `funcs.fanpipe`로는 `in_tag_rules`를 쓸 수 없음 | jsonnet 평가 |

위 세 파일(`io`, `ar39nodes`, `helpers`)은 어떤 experiment 파일도 import하지 않으므로 현재 job에는 영향이 없다.

## 6. 현재 작업 환경과의 관계

setup script는 `WIRECELL_PATH`를 다음 순서로 둔다.

1. `/nfs/data/1/yujin/wire-cell-toolkit/cfg` (local WCT checkout)
2. `$D/..` (dunereco `wire-cell-cfg`)
3. `$R` (WCT release)
4. `dune_pardata/v01_84_00/WireCellData`

local WCT checkout에 같은 경로의 파일이 있으면 그 파일이 dunereco 파일을 가린다.

| 파일 | local WCT에 있음 | 실제로 쓰이는 파일 |
|---|---|---|
| `common/params`, `common/funcs`, `common/io`, `common/resamplers`, `common/sim/depos`, `common/sim/ar39nodes` | 있음 (`$D`와 동일) | local (내용 같음) |
| `common/tools`, `common/sim/nodes`, `ui/wcls/nodes` | 있음 (`$D`와 다름, `$R`과 동일) | local |
| `dune/params` | 있음 (`resolution: 14`, `gain: 7.8mV/fC` 고정, extVar 주석 처리) | local |
| `common/pgraph`, `common/fileio`, `common/helpers` | 없음 | `$D` |

- local 환경에서 `funcs.jsonnet`은 local WCT 디렉터리에 있으므로 2절의 상대 경로 규칙에 따라
  sibling `pgraph.jsonnet`이 없고, `"pgraph.jsonnet"`은 local WCT의 `cfg/pgraph.jsonnet`으로 해석된다.
  공식 dunereco 환경과 다른 `pgraph`가 쓰인다.
- `dune/params` 차이: 공식 환경은 `elec.gain = elecGain`(fcl `structs`), local 환경은 `7.8mV/fC` 고정이다.
  PDHD(`elecs[*].gain = elecGain` 명시)와 PDVD(bottom `7.8mV/fC` 명시, top은 gain을 쓰지 않는
  `JsonElecResponse`)는 detector 파일에서 gain을 직접 정하므로 결과가 같다.
  `params.elec.gain`을 override하지 않는 detector에서는 결과가 달라진다.
