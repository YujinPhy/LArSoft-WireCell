# `wirecell_dune.fcl` 모듈 블록 구조

`wirecell_dune.fcl`에서 Wire-Cell 모듈 하나가 정의되는 방식, 각 키의 역할, 그리고 각 키가
Jsonnet 쪽과 연결되는 방식을 정리한다. `inputers`/`outputers` 설정 방법은 4절에 있다.
`dunesw v10_26_00d01` / `larwirecell v10_04_03` 기준으로 확인 (2026-10-10).

## 1. 파일 구성과 job fcl에서의 사용

### 1.1 파일 구성

```
#include "services_dune.fcl"          # signalservices_dune.fcl 포함 -> Nbit_legacy / Nbit_standard
#include "services_vdcoldbox.fcl"
#include "wirecell_dune-vd.fcl"       # 재사용 outputer 리스트 (예: dune10ktvd_nfsp_outputers_singledigits)
#include "wirecell_dune10kt-vd.fcl"

BEGIN_PROLOG
<block_name>: { module_type: WireCellToolkit  wcls_main: { ... } }
<block_name>_mc: @local::<block_name>
...
END_PROLOG
```

모든 블록은 `BEGIN_PROLOG ... END_PROLOG` 안에 있으므로 이름이 붙은 table(템플릿)일 뿐이다.
job fcl이 `physics.producers`로 복사하기 전까지는 아무것도 실행되지 않는다.

### 1.2 job fcl에서 블록 사용

job fcl은 prolog의 블록을 `physics.producers` 아래의 key에 복사해서 module을 만든다.
예: `fcl_sim/detsim_reco/standard_reco_protodunehd_MC.fcl`

```
process_name: Reco                                      # :28
physics.producers: {
    wclsdatahd: @local::protodunehd_nfsp_mc             # :89
}
physics.reco: [ ..., wclsdatahd, ... ]                  # :146
physics.producers.gaushit.CalDataModuleLabel: "wclsdatahd:gauss"   # :204
```

이 예에는 이름이 네 가지 나온다.

| 이름 | 예시 값 | 정의 위치 | 의미 |
|---|---|---|---|
| 블록 이름 | `protodunehd_nfsp_mc` | `wirecell_dune.fcl` prolog | 설정 템플릿의 이름. `@local::`로 참조할 때만 쓰며 job 실행 중에는 남지 않는다 |
| `module_type` | `WireCellToolkit` | 블록 내부 | 실행할 C++ module class (`WireCellToolkit_module.cc`) |
| **module label** | `wclsdatahd` | job fcl의 `physics.producers` key | job 안에서 이 module instance를 가리키는 이름 |
| instance name | `gauss`, `wiener` | jsonnet saver의 `frame_tags` 등 (4.3절) | 한 module이 같은 type의 product를 여러 개 만들 때 서로 구분하는 이름 |

이 절에서 말하는 label은 **module label**이다. module label은 블록 이름과 상관없이 job fcl 작성자가 정한다.
같은 블록을 서로 다른 label로 두 번 복사하면 독립된 module 두 개가 된다.

module label이 쓰이는 곳:

1. **path 등록**: `physics.reco: [ ..., wclsdatahd, ... ]`처럼 label로 실행 순서에 넣는다. path에 없는 producer는 실행되지 않는다.
2. **job별 override**: `physics.producers.<label>.wcls_main...`처럼 label을 경로에 넣는다.
   예: `physics.producers.wclsdatavd.wcls_main.params.use_resampler: "true"`
   (`fcl_data/standard_reco_pdvd_offline_nodnnroi.fcl:125`).
3. **출력 product 식별**: art는 product를 `<module label>:<instance name>:<process_name>`(art `InputTag`)으로 구분한다.
   위 예의 `spsaver` 출력은 `wclsdatahd:gauss:Reco`, `wclsdatahd:wiener:Reco`가 되고, 후단 module은 보통
   process 부분을 생략하고 `wclsdatahd:gauss`로 읽는다 (`gaushit.CalDataModuleLabel`, `:204`).

detsim도 같은 방식이다. `fcl_sim/detsim_reco/standard_detsim_protodunehd.fcl:31`의
`tpcrawdecoder: @local::wirecell_protodunehdmc`에서 module label은 `tpcrawdecoder`이다. 그 출력
`tpcrawdecoder:daq` (`raw::RawDigit`)를 reco 블록이 `params.raw_input_label: "tpcrawdecoder:daq"`로 읽는다 (4.6절).
따라서 detsim job에서 label을 바꾸면 reco 블록의 `raw_input_label`도 함께 바꿔야 한다.

최종 resolve된 module 설정은 `fhicl-dump -c <job>.fcl`로, 출력 파일의 label/instance는
`lar -c eventdump.fcl -s <file> -n1`로 확인한다 ([02_larwc.md](02_larwc.md) 참고).

## 2. 2단계 구조

```
<block_name>: {
    module_type : WireCellToolkit          # 1단계: art module (larwirecell)
    wcls_main: {                           # 2단계: 이 sub-table로 생성되는 art tool
        tool_type: WCLS
        apps:      [...]
        logsinks:  [...]
        loglevels: [...]
        plugins:   [...]
        inputers:  [...]
        outputers: [...]
        configs:   [...]
        params:    { ... }                 # -> Jsonnet std.extVar(), 문자열
        structs:   { ... }                 # -> Jsonnet std.extVar(), Jsonnet 코드
    }
}
```

- `module_type: WireCellToolkit`은 `art::SharedProducer`이다
  (`larwirecell/Modules/WireCellToolkit_module.cc`). `reconfigure()`는
  `pset.get<fhicl::ParameterSet>("wcls_main")`와 `art::make_tool<wcls::MainTool>(...)`만 수행한다.
  다른 key는 읽지 않으며, 모든 설정은 `wcls_main` 안에 있다.
- `wcls_main.tool_type: WCLS`는 `liblarwirecell_Tools_WCLS_tool.so`를 선택한다. 이 tool이 WCT
  application을 시작하고 매 `art::Event`마다 inputer/outputer를 호출한다.

## 3. `wcls_main`의 키

| Key | Type | 역할 | 대표 값 |
|---|---|---|---|
| `tool_type` | string | 생성할 art tool | `WCLS` |
| `apps` | list[string] | event마다 실행할 WCT application | `["Pgrapher"]` |
| `logsinks` | list[string] | WCT log 출력 대상 (선택) | `["stdout"]` |
| `loglevels` | list[string] | 기본 level, 이후 `logger:level` 항목 (선택) | `["debug", "pgraph:info"]` |
| `plugins` | list[string] | component를 불러올 WCT shared library | `["WireCellPgraph", "WireCellGen", "WireCellSio", "WireCellSigProc", "WireCellLarsoft"]` |
| `inputers` | list[string] | graph 실행 전에 `art::Event`를 읽는 WCT component의 `type[:name]` | `["wclsRawFrameSource"]`, `["wclsSimDepoSetSource:electron"]` |
| `outputers` | list[string] | graph 실행 후에 `art::Event`에 쓰는 WCT component의 `type[:name]` | `["wclsFrameSaver:spsaver"]` |
| `configs` | list[string] | main Jsonnet 파일, `WIRECELL_PATH` 기준으로 탐색 | `["pgrapher/experiment/pdhd/wcls-nf-sp.jsonnet"]` |
| `paths` | list[string] | `configs` 추가 탐색 경로 (선택, 이 파일에서는 미사용) | - |
| `params` | table | **문자열**로 전달되는 external variable | 3.1 참고 |
| `structs` | table | **Jsonnet 코드**(숫자, bool)로 전달되는 external variable | 3.2 참고 |

`params`와 `structs`는 `WCLS` tool의 `m_extvars` / `m_extcode` 멤버에 대응한다
(`strings liblarwirecell_Tools_WCLS_tool.so`로 확인 가능). 둘 다 Jsonnet에서 같은
`std.extVar('<key>')`로 읽으며, 결과의 Jsonnet type만 다르다.

### 3.1 `params` (문자열 ext-var)

자주 쓰이는 key (`wirecell_dune.fcl`에서 해당 key를 사용하는 블록 수):

| Key | 개수 | 의미 |
|---|---|---|
| `reality` | 29 | `"data"` 또는 `"sim"`; Jsonnet에서 data/MC parameter 선택 |
| `signal_output_form` | 27 | `recob::Wire` 출력 형식 `"sparse"` 또는 `"dense"` |
| `raw_input_label` | 27 | `raw::RawDigit` collection의 art input tag, 예: `"tpcrawdecoder:daq"` |
| `epoch` | 23 | noise filter channel DB epoch: `"after"`, `"before"`, `"perfect"`, `"dynamic"` |
| `use_resampler` | 7 | `"true"`/`"false"` (문자열) |
| `process_mode` | 8 | Jsonnet이 연결할 saver 선택; `outputers`와 일치해야 함 |

모든 값이 문자열이므로 bool은 `"true"`/`"false"`로 쓰고, Jsonnet에서는 문자열로 비교해야 한다.
fcl에 정의되었지만 Jsonnet이 읽지 않는 key는 경고 없이 무시된다. 예: `pdhd/wcls-nf-sp.jsonnet:43`은
`use_resampler = (reality == 'data')`로 직접 계산하며 `params.use_resampler`를 읽지 않는다.

### 3.2 `structs` (코드 ext-var)

| Key | 단위 / 의미 |
|---|---|
| `Nbit` | ADC bit 수; `@local::Nbit_standard` (14) 또는 `@local::Nbit_legacy` (12, ProtoDUNE-SP), `dunecore/fcl/signalservices_dune.fcl`에 정의 |
| `elecGain` | FE gain, `mV/fC` 단위 (PDHD는 14 또는 7.8); `pdhd/params.jsonnet`에서 `std.extVar("elecGain")*wc.mV/wc.fC`로 사용 |
| `DL`, `DT` | 종/횡 방향 diffusion constant, `cm2/s` (sim 블록) |
| `lifetime` | electron lifetime, `ms` |
| `driftSpeed` | electron drift speed, `mm/us` |
| `use_dnnroi` | bool, DNN-ROI branch 활성화 |
| `wire_col_nsigma` | SP의 collection plane wire filter 폭 |

값이 숫자/bool로 전달되므로 Jsonnet에서 바로 산술 연산에 사용한다.
`pdhd/params.jsonnet`은 `elecGain`을 두 type 모두 허용하지만
(`if std.isString(g) then std.parseJson(g) else g`), 대부분의 다른 key는 그렇지 않으므로
Jsonnet이 기대하는 table에 key를 두어야 한다.

## 4. `inputers` / `outputers`

### 4.1 역할과 호출 순서

WCT graph는 `art::Event`에 직접 접근하지 못한다. `inputers`/`outputers`에 나열되는 `wcls*` component가
두 interface를 함께 구현해서 art와 WCT 사이의 데이터 변환을 담당한다.

- `wcls::IArtEventVisitor` (`larwirecell/Interfaces/IArtEventVisitor.h`): `visit(art::Event&)`, `produces(art::ProducesCollector&)`
- WCT graph node interface: source (`nin=0, nout=1`) 또는 filter (`nin=1, nout=1`)

`WCLS` tool의 처리 순서 (`larwirecell/Tools/WCLS_tool.cc`):

```
[module 생성]
  WCT 초기화: configs/plugins/params/structs 적용, jsonnet에 있는 모든 component 생성 및 configure
  inputers/outputers 각 항목 -> Factory::find_tn<IArtEventVisitor>("type:name")로 기존 instance 조회
  outputers 각 항목 -> produces(collector)    # art에 product type/instance 등록
[event마다 process(event)]
  1. inputers 각 항목  -> visit(event)        # art::Event -> component 내부 buffer
  2. m_wcmain()                               # Pgrapher가 graph 실행
  3. outputers 각 항목 -> visit(event)        # component 내부 buffer -> art::Event (put)
```

graph 안에서의 동작:

| 구분 | `visit()` (art 쪽) | graph 안 `operator()` (WCT 쪽) | graph 내 위치 |
|---|---|---|---|
| inputer (source) | art product를 읽어 buffer에 저장 | buffer에서 꺼내 graph로 출력; buffer가 비면 `false` 반환 | graph 시작점 (`nin=0, nout=1`) |
| outputer (saver/writer) | buffer를 art product로 변환해 저장 | 입력을 다음 node로 그대로 전달하면서 buffer에 보관 (pass-through) | graph 중간 (`nin=1, nout=1`), 뒤에 `DumpFrames` 같은 종단 sink |

예: `pdhd/wcls-nf-sp.jsonnet:207`
`g.pipeline([wcls_input.adc_digits, fanpipe, retagger, wcls_output.sp_signals, sink])`.
outputer는 종단 sink가 아니라 그 앞에 놓인 filter이다.

### 4.2 이름 규칙

fcl의 `"type:name"` 문자열이 jsonnet node의 `type`, `name`과 정확히 같아야 한다.

| fcl 항목 | jsonnet node |
|---|---|
| `"wclsRawFrameSource"` | `type: 'wclsRawFrameSource', name: ''` |
| `"wclsSimDepoSource:"` | `type: 'wclsSimDepoSource', name: ''` |
| `"wclsSimDepoSetSource:electron"` | `type: 'wclsSimDepoSetSource', name: 'electron'` |
| `"wclsFrameSaver:spsaver"` | `type: 'wclsFrameSaver', name: 'spsaver'` |

- `:name`이 없거나 `:` 뒤가 비어 있으면 `name: ''`와 대응된다.
- 같은 type을 여러 개 쓸 때는 name으로 구분한다. 예: `protodunehd_img`의
  `"wclsCookedFrameSource:charge"`, `"wclsCookedFrameSource:wiener"` (`pdhd/wcls-img.jsonnet:25`, `:35`).
- jsonnet에 정의만 되어 있고 graph에 연결되지 않은 node는 configuration에 포함되지 않는다
  (`g.uses(graph)`는 graph에 연결된 node만 모은다). 예: `pdhd/wcls-sim-drift-simchannel-priorSCE-depoflux.jsonnet`은
  `wclsSimDepoSource` (`:54`)와 `wclsSimChannelSink:postdrift` (`:150`)를 정의하지만, graph (`:230`)에는
  `wclsSimDepoSetSource:electron`과 `wclsDepoFluxWriter:postdrift`만 연결한다. fcl에는 graph에 연결된 node만 적는다.

### 4.3 주요 component

`libWireCellLarsoft.so`에 등록된 type 중 이 파일에서 쓰이는 것들이다. key 설명은 `larwirecell/Components/*.cxx`의
`default_configuration()` 기준이며, 값은 jsonnet node의 `data`에 설정한다.

**Inputer**

| type | art에서 읽는 product | graph로 내보내는 것 | 주요 `data` key |
|---|---|---|---|
| `wclsRawFrameSource` | `std::vector<raw::RawDigit>` | `IFrame` (event당 1개) | `art_tag` (필수; 비면 configure 단계 예외), `frame_tags` (기본 `["orig"]`), `tick` (기본 `0.5us`), `nticks` (0이면 입력 길이 유지, 아니면 자르거나 baseline 값으로 padding) |
| `wclsCookedFrameSource` | `std::vector<recob::Wire>` | `IFrame` | `recobwire_tags`, `trace_tags`, `summary_tags`, `frame_tags` |
| `wclsSimDepoSource` | `std::vector<sim::SimEnergyDeposit>` | `IDepo` stream | `art_tag`, `assn_art_tag`, `model`, `scale` |
| `wclsSimDepoSetSource` | `std::vector<sim::SimEnergyDeposit>` | `IDepoSet` (event당 1개) | `art_tag`, `assn_art_tag` (선택, 크기가 같은 두 번째 SED collection), `model`, `scale`, `id_is_track` |
| `wclsMultiChannelNoiseDB` | geometry service 기반 channel 정보 | graph node가 아님 (channel noise DB) | `epoch: "dynamic"`일 때만 `inputers`에 추가 (`wirecell_dune.fcl:24-26`, `:46-49` 주석) |

- `wclsRawFrameSource`의 `art_tag`가 event에 없으면 `visit()`에서 `RuntimeError`가 발생한다.
- `wclsSimDepoSetSource`는 SED가 0개인 event에서 charge 0의 depo 1개를 만들어 graph가 멈추지 않게 한다.

**Outputer**

| type | graph에서 받는 것 | art에 쓰는 product | instance name | 주요 `data` key |
|---|---|---|---|---|
| `wclsFrameSaver` | `IFrame` | `digitize: true` -> `std::vector<raw::RawDigit>`, `false` -> `std::vector<recob::Wire>`; summary -> `std::vector<double>`; channel mask | `frame_tags`의 각 tag; summary는 `<tag>` + `summary_suffix` (기본 `"summary"`); mask는 `<name>channels`, `<name>masks` | `anode`, `digitize`, `sparse` (기본 `true`, `recob::Wire` zero suppression), `frame_tags`, `frame_scale` (tag별 list 가능), `nticks` (0: 입력 유지, -1: detector properties), `pedestal_mean` (숫자, `"native"`, `"fiction"`), `summary_tags`, `chanmaskmaps` |
| `wclsDepoFluxWriter` | depo set | `std::vector<sim::SimChannel>` | `simchan_label` | `anodes` (필수), `field_response`, `tick`, `window_start`, `window_duration`, `nsigma`, `sed_label`, `sparse` |
| `wclsSimChannelSink` | depo | `std::vector<sim::SimChannel>` | `artlabel` | `anodes_tn`, `tick`, `start_time`, `readout_time`, `nsigma`, `drift_speed`, `u_to_rp`, `v_to_rp`, `y_to_rp` |

- `wclsFrameSaver`에 frame이 도달하지 않은 event에서는 등록된 모든 product를 빈 상태로 저장한다.
- 그 외에 `wclsChannelNoiseDB`, `wclsChannelSelectorDB`, `wclsCookedFrameSink`, `wclsDepoSetSimChannelSink`,
  `wclsLazyFrameSource`, `wclsOpFlashSource`도 등록되어 있다.

### 4.4 불일치 시 동작

| 상황 | 결과 |
|---|---|
| fcl 항목에 해당하는 instance가 configuration에 없음 (오타, graph에 미연결) | module 생성 단계에서 job 종료: `Failed to lookup instance for <type> <name>` (`find_tn`은 instance를 새로 만들지 않음) |
| graph의 source가 `inputers`에 없음 | `visit()`가 호출되지 않아 buffer가 비어 있음 -> `operator()`가 `false` 반환 -> graph에 입력이 없음. 예외는 발생하지 않음 |
| graph의 saver가 `outputers`에 없음 | frame은 saver buffer에 보관되지만 art에 쓰이지 않으며, product도 등록되지 않음. 다음 event에서 이전 frame을 버린다는 warning 출력 |
| source의 `art_tag`가 입력 파일에 없음 | `visit()`에서 `RuntimeError` |
| 후단 module이 기대하는 label과 instance name 불일치 | WCT 쪽 오류 없음. 후단 module(예: `gaushit`)에서 product를 찾지 못함 |

### 4.5 설정 방법

1. **graph에 연결된 `wcls*` node 찾기.** `configs`에 지정한 jsonnet에서 `wcls*` node와 graph 정의를 확인한다.
   ```bash
   grep -n "type: *['\"]wcls" <jsonnet>     # wcls* node의 type/name
   grep -n "local graph" <jsonnet>          # 실제로 graph에 들어가는 node
   ```
2. **`inputers` 작성.** graph에 연결된 source node마다 `"type:name"`을 하나씩 적는다. name이 `''`이면 `"type"` 또는 `"type:"`로 쓴다.
3. **입력 art tag 맞추기.** source의 `art_tag` (`wclsCookedFrameSource`는 `recobwire_tags`)가 입력 파일의 product label과
   같아야 한다. jsonnet이 `std.extVar`로 받는 경우에는 fcl `params`에서 바꾼다
   (예: `params.raw_input_label` -> `wclsRawFrameSource.art_tag`, `pdhd/wcls-nf-sp.jsonnet:21`, `:54`).
   입력 파일의 product는 `lar -c eventdump.fcl -s <file> -n1`로 확인한다.
4. **`outputers` 작성.** graph에 연결된 saver/writer node마다 `"type:name"`을 하나씩 적는다. `process_mode` 같은 jsonnet 스위치가
   saver 구성을 바꾸면 그에 맞는 리스트를 쓴다 (6절 (c)).
5. **출력 product 이름 확인.** art product는 `<module_label>:<instance>`로 저장된다. instance는 `wclsFrameSaver`의 `frame_tags`,
   `wclsDepoFluxWriter`의 `simchan_label`이다. 후단 module의 입력 label(예: `gaushit.CalDataModuleLabel`)과 맞춘다.
6. **검증.** `lar -n1` 실행 log에서 `WCLS` tool이 출력하는 `Inputer: "..."` / `Outputer: "..."` 줄을 확인하고,
   출력 파일을 `eventdump.fcl`로 열어 product가 생성되었는지 확인한다.

### 4.6 예시

**(a) Reco: `raw::RawDigit` -> `recob::Wire`** (`protodunehd_nfsp`, `wirecell_dune.fcl:134`)

```
inputers:  ["wclsRawFrameSource"]
outputers: ["wclsFrameSaver:spsaver"]
params:    { raw_input_label: "tpcrawdecoder:daq" ... }
```

| fcl | `pdhd/wcls-nf-sp.jsonnet` |
|---|---|
| `"wclsRawFrameSource"` | `name: ''`, `art_tag: raw_input_label`, `frame_tags: ['orig']` (`:50-58`) |
| `"wclsFrameSaver:spsaver"` | `digitize: false`, `frame_tags: ['gauss', 'wiener']`, `frame_scale: [0.001, 0.001]` (`:96-110`) |

job fcl에서 label이 `wclsdatahd`이면 `wclsdatahd:gauss`, `wclsdatahd:wiener` (`recob::Wire`)가 저장되고,
`gaushit`이 `wclsdatahd:gauss`를 읽는다 (`fcl_sim/detsim_reco/standard_reco_protodunehd_MC.fcl:204`).

**(b) Detsim: depo -> `raw::RawDigit` + `sim::SimChannel`** (`wirecell_protodunehdmc`, `wirecell_dune.fcl:360`)

```
inputers:  ["wclsSimDepoSetSource:electron"]
outputers: ["wclsDepoFluxWriter:postdrift", "wclsFrameSaver:simdigits"]
```

| fcl | `pdhd/wcls-sim-drift-simchannel-priorSCE-depoflux.jsonnet` |
|---|---|
| `"wclsSimDepoSetSource:electron"` | `art_tag: 'IonAndScint'` (`:36`, `:56-64`) |
| `"wclsDepoFluxWriter:postdrift"` | `simchan_label: 'simpleSC'`, `sed_label: 'IonAndScint'` (`:173-188`) |
| `"wclsFrameSaver:simdigits"` | `digitize: true`, `frame_tags: ['daq']`, `pedestal_mean: 'native'` (`:82-91`) |

job fcl에서 label이 `tpcrawdecoder`이면 `tpcrawdecoder:daq` (`raw::RawDigit`)와 `tpcrawdecoder:simpleSC` (`sim::SimChannel`)가
저장된다. (a)의 `raw_input_label: "tpcrawdecoder:daq"`가 이 출력을 읽는다.

**(c) 출력 추가: NF 결과 저장**

`pdhd/wcls-nf-sp.jsonnet`은 `wclsFrameSaver:nfsaver` (`nf_digits`, `:78`)를 정의하지만 graph (`:207`)에는 연결하지 않는다.
따라서 fcl `outputers`에 `"wclsFrameSaver:nfsaver"`만 추가하면 module 생성 단계에서 lookup 오류로 종료된다.
NF 결과를 저장하려면 jsonnet graph의 NF 뒤에 `nf_digits`를 연결한 다음 fcl `outputers`에 추가해야 한다.

**(d) art 출력 없음** (`protodunehd_img`, `wirecell_pdhd_sim_deposplat`)

`outputers: []`이면 art event에 product가 추가되지 않는다. 결과는 jsonnet 안의 file sink(HDF5, Magnify ROOT, cluster archive)가
직접 기록한다.

## 5. Jsonnet과의 계약

fcl 블록과 `configs`에 지정된 Jsonnet 파일은 다음 세 가지가 일치해야 한다.
불일치는 FHiCL 단계에서 검출되지 않으며, WCT configuration 시점에 실패하거나 출력이 조용히 누락된다.

1. **Jsonnet의 모든 `std.extVar('<key>')`는 `params` 또는 `structs`에 정의되어야 한다**
   (역방향은 필요 없음; 사용되지 않는 key는 무시됨).
2. **모든 `inputers`/`outputers` 항목은 같은 `type`과 `name`을 가진 node로 존재해야 한다.**
   `wclsRawFrameSource` (`:name` 없음)는 `name: ''`인 node와 대응된다 (4.2절).
3. **`outputers` 리스트는 Jsonnet이 실제로 graph에 넣는 saver와 일치해야 한다**
   (`process_mode`, `save_tradsp` 등이 saver를 켜고 끈다).

예시: `protodunehd_nfsp` (`wirecell_dune.fcl:134`)와
`pgrapher/experiment/pdhd/wcls-nf-sp.jsonnet` (`wire-cell-toolkit/cfg` 내) 대조:

| fcl | Jsonnet |
|---|---|
| `params.epoch` | `local epoch = std.extVar('epoch');` (13행) |
| `params.reality` | `local reality = std.extVar('reality');` (14행) |
| `params.signal_output_form` | `local sigoutform = std.extVar('signal_output_form');` (15행) |
| `params.raw_input_label` | `local raw_input_label = std.extVar('raw_input_label');` (21행) |
| `inputers: ["wclsRawFrameSource"]` | `type: 'wclsRawFrameSource', name: ''` (51행) |
| `outputers: ["wclsFrameSaver:spsaver"]` | `type: 'wclsFrameSaver', name: 'spsaver'` (97행), `frame_tags: ['gauss', 'wiener']` |

saver의 `frame_tags`가 art product instance name이 되므로, 후단에서는 출력을
`<module_label>:gauss` / `<module_label>:wiener`로 읽는다.



## 6. 파생 블록 (상속 패턴)

파일에는 세 가지 패턴이 있다. 짧은 것부터 유연한 순서이다.

**(a) 복사 + dotted override** -- 일부 leaf 값만 변경:

```
protodunehd_nfsp_mc: @local::protodunehd_nfsp
protodunehd_nfsp_mc.wcls_main.params.reality: "sim"
```

거의 모든 `_mc` 변형에 사용된다 (`wirecell_dune.fcl:160`, `:195`, `:223`, `:251`, ...).
Jsonnet 교체에도 사용된다. 예: `protodunehddata_wctsp` (`:129`)와
`wirecell_protodunehdmc` (`:360`)는 `wcls_main.configs`를 override한다.

**(b) `@table::` splice** -- table을 재구성하고 sub-table 전체를 교체:

```
dune10kt_vertdrift_sim_nfsp_singledigits : {
    @table::dune10kt_vertdrift_sim_nfsp
    wcls_main: {
        @table::dune10kt_vertdrift_sim_nfsp.wcls_main
        outputers: @local::dune10ktvd_nfsp_outputers_singledigits
        params: {
            @table::dune10kt_vertdrift_sim_nfsp.wcls_main.params
            process_mode: "single-sim-sp"
        }
    }
}
```

(`wirecell_dune.fcl:2348`.) splice 안에서 다시 정의한 table은 상속된 table을 통째로 대체하므로,
다른 key를 유지하려면 `params`에서도 부모를 다시 splice해야 한다.

**(c) `@local::`로 공유하는 리스트** -- `outputers` 리스트를
`wirecell_dune-vd.fcl` / `wirecell_dune10kt-vd.fcl`에 한 번만 정의하고 이름으로 참조한다.
이렇게 하면 리스트가 Jsonnet의 `process_mode`와 일관되게 유지된다 (`wirecell_dune.fcl:4` 주석).

## 7. 파일 내 블록 분류

| 패턴 | 단계 | Inputer | Outputer | 예시 |
|---|---|---|---|---|
| `*_nfsp`, `*_nf`, `*_sp`, `*_dnnroi` | NF / SP (reco) | `wclsRawFrameSource` | `wclsFrameSaver:spsaver` (+ `nfsaver`, `tradspsaver`) | `protodunehd_nfsp`, `protodunehd_nfsp_dnnroi`, `protodunevd_nfsp` |
| `*_wctsp` | cooked data에 대한 SP | `wclsCookedFrameSource` | `wclsFrameSaver:spsaver` | `protodunespdata_wctsp` |
| `wirecell_*mc`, `tpcrawdecoder_*` | detector simulation | `wclsSimDepoSetSource:electron` 또는 `wclsSimDepoSource:` | `wclsDepoFluxWriter:postdrift`, `wclsFrameSaver:simdigits` | `wirecell_protodunehdmc` |
| `*_sim_deposplat` | DepoSplat simulation | `wclsSimDepoSource:` | (없음) | `wirecell_pdhd_sim_deposplat` |
| `*_img`, `*_nfspimg` | imaging | `wclsRawFrameSource` (`nfspimg`) 또는 `wclsCookedFrameSource:charge`, `:wiener` (`img`) | `[]` (출력은 Jsonnet file sink가 기록) | `protodunehd_nfspimg`, `protodunehd_img` |

## 8. 새 블록 작성 체크리스트

1. 가장 가까운 기존 블록에서 패턴 (a) 또는 (b)로 시작한다. 전체 텍스트를 복사하지 않는다.
2. `configs`에 Jsonnet을 지정하고, 그 파일이 읽는 모든 `std.extVar()`를 나열한다.
3. 문자열 스위치는 `params`, 숫자/bool 값은 `structs`에 둔다. Jsonnet이 기대하는 type에 맞춘다.
4. `inputers`/`outputers`를 Jsonnet node의 `type`/`name`과 정확히 일치시킨다 (4.5절).
5. 추가로 필요한 WCT library를 `plugins`에 넣는다 (예: DNN-ROI는 `WireCellPytorch`, imaging은 `WireCellImg`).
6. `fhicl-dump -c <job>.fcl`과 1-event `lar -n1` 실행으로 검증한다.

## Related Documents

- [01_setup.md](01_setup.md): `lar` 실행 전에 필요한 환경 설정.
- [02_larwc.md](02_larwc.md): 이 블록들을 사용하는 pipeline과 `fhicl-dump` helper.
