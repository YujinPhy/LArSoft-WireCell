# `reality` (`data` / `sim`)에 따른 Wire-Cell 설정 차이

`wirecell_dune.fcl`의 `params.reality`가 Jsonnet 쪽에서 어떤 설정을 바꾸는지 정리한다.
PDHD(`pgrapher/experiment/pdhd`)와 PDVD(`pgrapher/experiment/protodunevd`)를 중심으로 하고,
다른 detector는 5절에 요약한다.

- 기준 tree: `/nfs/data/1/yujin/wire-cell-cfg`. pdhd/protodunevd 디렉터리는
  `dunereco v10_26_00d01`의 `wire-cell-cfg`(CVMFS, 기본 `WIRECELL_PATH` 1번)와 동일하다.
- 공통 base: `pgrapher/dune/params.jsonnet`(WCT release `v0_37_1`) -> `pgrapher/common/params.jsonnet`.
- 현재 setup script의 `MY_WIRECELL_PATH`는 `$WORKDIR/wire-cell-toolkit/cfg`이므로 실제 job에서는
  그쪽 파일이 우선한다. 차이는 6절에 적었다.
- 확인일: 2026-10-12.

## 1. 전달 경로

```
wirecell_dune.fcl                      Jsonnet (wcls-*.jsonnet)
params: { reality: "data" }   --->     local reality = std.extVar('reality');
protodunehd_nfsp_mc:                   local params = if reality == 'data'
  ...params.reality: "sim"                            then data_params    // params.jsonnet
                                                      else simu_params;   // simparams.jsonnet
```

- `wcls_main.params`의 값은 모두 Jsonnet external variable(`std.extVar`)로 전달된다
  (`docs/03_wirecell_dune_module.md` 참고).
- `_mc` 블록은 data 블록을 복사한 뒤 `reality`만 `"sim"`으로 바꾼다
  (예: `wirecell_dune.fcl:160-161` `protodunehd_nfsp_mc`).
- 비교는 `reality == 'data'`뿐이다. `"data"`가 아닌 모든 문자열(`"sim"`, `"mc"`, 오타 포함)은 sim으로 처리된다.

`reality`가 바꾸는 것은 두 가지다.

| 항목 | 방식 | 해당 파일 |
|---|---|---|
| (A) parameter set | `params.jsonnet` vs `simparams.jsonnet` 선택 | 모든 `wcls-*.jsonnet` |
| (B) `Resampler` 삽입 여부 | `use_resampler = (reality == 'data')` | PDHD `wcls-nf`, `wcls-nf-sp`, `wcls-nf-sp-img`만 |

`simparams.jsonnet`은 `params.jsonnet`을 import해서 일부만 override한다. 따라서 (A)의 차이는
`simparams.jsonnet`이 override하는 필드뿐이다.

## 2. PDHD

### 2.1 Parameter 차이 (`params.jsonnet` vs `simparams.jsonnet`)

| 필드 | `data` (`params.jsonnet`) | `sim` (`simparams.jsonnet`) | 비고 |
|---|---|---|---|
| `det.volumes[n].faces` | cryostat 벽 쪽 face가 `null` (`:65`, `:79`) | 두 face 모두 정의 (`:65-90`) | 아래 2.2 |
| `daq.nticks` | `6000` | `6000` (`:113`) | 값 동일 |
| `sim.fixed` | `true` | `true` | 동일 |
| `sim.continuous` | `true` (common default) | `false` (`:171`) | sim graph 전용 |
| `sim.fluctuate` | `true` (common default) | `true` (`:172`) | 동일 |
| `sys_status`, `sys_resp` | 정의 없음 | `false`, `{start:-10us, magnitude:1.0, time_smear:1.0us}` (`:248-254`) | `tools.pirs` 전용 |
| `rc_resp` | 정의 없음 | `{width:1.1ms, rc_layers:0}` (`:256-259`) | `tools.pirs`, `tools.rc_resp` 전용 |
| `lar.*` | common default (`lifetime=8ms`, `drift_speed=1.6mm/us`) | 동일 (lifetime override는 주석 처리) | 차이 없음 |
| `adc`, `elecs`, `files` | `params.jsonnet` 정의 | 상속 | 차이 없음 |

- `elecs[*].gain`은 두 경우 모두 `std.extVar("elecGain")` (`params.jsonnet:110`)이고,
  noise file 선택(`:165`)도 gain만 본다. `reality`와 무관하다.
- `sys_status`, `sys_resp`, `rc_resp`는 `pgrapher/common/tools.jsonnet:121-167`의
  `rc_resp`, `sys_resp`, `pirs`에서만 읽는다. 이 object들은 sim graph(`sim.jsonnet`,
  `wcls-sim-drift-*.jsonnet`)에서만 참조되므로 NF/SP job에서는 평가되지 않는다
  (Jsonnet lazy evaluation). `params.jsonnet`에 이 필드가 없어도 NF/SP는 동작한다.

### 2.2 `det.volumes` face 차이의 영향

PDHD APA는 $x=\pm3.5734$m에 있고 바깥쪽 face는 cryostat 벽을 향한다.

- `data`: 벽 쪽 face를 `null`로 둔다.
- `sim`: 두 face 모두 `anode`/`response`/`cathode` 좌표를 준다.

`AnodePlane`(`gen/src/AnodePlane.cxx:159-208`)은 face가 `null`이면 `sensitive_face = false`로
표시만 하고, 그 face의 plane channel은 `m_channels`에 그대로 넣는다. 결과:

- NF/SP: channel 목록이 같으므로 처리 대상 channel은 `reality`와 무관하다.
- Drift/imaging처럼 face의 sensitive volume을 쓰는 단계: `data`에서는 벽 쪽 face가 비활성이다.

### 2.3 Entry 파일별 동작

| 파일 | params 선택 | `Resampler` | input `tick` |
|---|---|---|---|
| `wcls-nf.jsonnet` | `:16-18` | `data`만 (`:36`, `:150`) | `512ns` 고정 (`:51`) |
| `wcls-nf-sp.jsonnet` | `:24-26` | `data`만 (`:43`, `:165`) | `512ns` 고정 (`:56`) |
| `wcls-nf-sp-img.jsonnet` | `:13-15` | `data`만 (`:28`, `:143`) | `512ns` 고정 (`:42`) |
| `wcls-sp.jsonnet` | `:35-37` | 없음 | - |
| `wcls-rawdigit-sp.jsonnet` | `:35-38` | 없음 | `params.daq.tick` (`clock_speed`로 override, `:40`, `:72`) |
| `wcls-rawdigit-dnnsp.jsonnet` | `:33-36` | 없음 | `params.daq.tick` (`clock_speed`로 override, `:38`, `:70`) |
| `wcls-img.jsonnet` | `:10-12` | 없음 | - |

- `Resampler`는 `pgrapher/common/resamplers.jsonnet`에서 정의: `period: 500ns`, `time_pad: "linear"`.
  PDHD data는 `512ns` sampling이므로 NF 앞에서 `500ns`로 맞춘다.
- 이 세 파일은 fcl의 `params.use_resampler`를 읽지 않는다. `wirecell_dune.fcl`의
  `use_resampler: "false"`는 PDHD에서는 효과가 없다.

### 2.4 관찰: PDHD MC의 input tick

`wcls-nf*.jsonnet`의 `wclsRawFrameSource.tick`은 `reality`와 무관하게 `512ns`이고,
`sim`에서는 `Resampler`가 빠진다. 한편 PDHD sim parameter의 `daq.tick`은 `0.5us`
(`pgrapher/common/params.jsonnet:69`)이다. `OmnibusSigProc`은 `m_period = frame->tick()`
(`sigproc/src/OmnibusSigProc.cxx:828`)로 frame tick을 그대로 쓴다.

따라서 MC를 `protodunehd_nfsp_mc`로 처리하면 `500ns` sampling waveform이 `512ns` tick으로
표기된 채 SP에 들어가는 것으로 보인다. `wclsRawFrameSource`가 `tick`을 frame tick으로 쓰는지는
larwirecell 소스가 이 환경에 없어 확인하지 못했고, SP 출력에 대한 영향도 검증하지 않았다.

## 3. PDVD

### 3.1 Parameter 차이

| 필드 | `data` (`params.jsonnet`) | `sim` (`simparams.jsonnet`) | 사용처 |
|---|---|---|---|
| `lar.lifetime` | `8ms` (common default) | `1000ms` (`:8`) | sim drift |
| `lar.DL` | `7.2cm2/s` | `4.0cm2/s` (`:10`) | sim drift |
| `lar.DT` | `12.0cm2/s` | `8.8cm2/s` (`:12`) | sim drift |
| `lar.drift_speed` | `1.6mm/us` | `1.473mm/us` (`:13`) | sim drift, `params.sim.ductor` 계산, `img.jsonnet` dump |
| `daq.nticks` | `6000` | `6000` (`:21`) | 동일 |
| `sim.continuous` | `true` | `false` (`:79`) | sim graph 전용 |
| `overall_short_padding` | 정의 없음 | `0.2ms` (`:156`) | `tools.pirs` |
| `sys_status`, `sys_resp` | 정의 없음 | `false`, `{start:0us, magnitude:1.0, time_smear:1.0us}` (`:157-162`) | `tools.pirs` |
| `rc_resp` | 정의 없음 | `{width:1.1ms, rc_layers:0}` (`:165-168`) | `tools.pirs`, `tools.rc_resp` |
| `det`, `adc`, `elecs`, `files` | `params.jsonnet` 정의 | 상속 | 차이 없음 |

- PDHD와 달리 `det.volumes`는 override하지 않는다. anode 구성은 `reality`와 무관하다.
- NF/SP가 읽는 `params` 필드는 `adc.fullscale`, `adc.resolution`(`sp.jsonnet`),
  `daq.tick`, `nf.nsamples`(`chndb-base.jsonnet`), `files.strip_length`(`nf.jsonnet`)뿐이며
  모두 두 parameter set에서 같다. 따라서 PDVD NF/SP 결과는 `reality`에 영향을 받지 않는다.
- `reality`가 결과를 바꾸는 곳은 imaging의 `img.dump(..., params.lar.drift_speed)`
  (`img.jsonnet:307-328`)이다. `data`는 `1.6mm/us`, `sim`은 `1.473mm/us`를 쓴다.

### 3.2 `use_resampler`는 `reality`와 독립

PDVD entry 파일은 `use_resampler`를 fcl에서 직접 받는다.

| 파일 | `use_resampler` | input `tick` | `Resampler` 적용 |
|---|---|---|---|
| `wcls-nf.jsonnet` | `std.extVar("use_resampler")` (`:25`) | `"true"`면 `512ns`, 아니면 `500ns` (`:37`) | `n<4` anode (bottom) (`:143`) |
| `wcls-nf-sp.jsonnet` | `std.extVar("use_resampler")` (`:84`); `reality` 기반 코드는 주석 (`:86`) | 동일 (`:99`) | `n<4` anode (`:233`) |
| `wcls-rawdigit-sp.jsonnet` | 읽지만 tick은 `params.daq.tick` (`:40`) | - | - |
| `wcls-nf-sp-img.jsonnet` | 사용 안 함 | - | - |

- data job은 fcl에서 `use_resampler: "true"`를 따로 지정한다
  (`fcl_data/standard_reco_pdvd_offline.fcl:151`, `:162`, `:166`, `:170`).
- `reality: "data"`만 바꾸고 `use_resampler`를 빼먹으면 PDVD bottom 데이터는 resampling 없이
  `500ns`로 처리된다.

## 4. 요약

| | PDHD | PDVD |
|---|---|---|
| NF/SP channel 및 response 설정 | 변화 없음 | 변화 없음 |
| `Resampler` (`512ns`->`500ns`) | `reality == 'data'`로 자동 결정 | `use_resampler` fcl 값으로 결정 |
| anode face | `data`는 벽 쪽 face `null` | 변화 없음 |
| `lar` 물성 | 변화 없음 | `lifetime`, `DL`, `DT`, `drift_speed` 변경 |
| imaging `drift_speed` | 변화 없음 (`1.6mm/us`) | `1.6mm/us` vs `1.473mm/us` |
| sim 전용 필드 (`sys_resp`, `rc_resp`, `sim.continuous`) | `sim`에만 존재 | `sim`에만 존재 |

## 5. 다른 detector

`/nfs/data/1/yujin/wire-cell-cfg/pgrapher/experiment` 안에서 `reality`를 읽는 패턴:

| 패턴 | 해당 디렉터리 |
|---|---|
| `if reality == 'data' then data_params else simu_params` | `pdsp`, `dunevd-crp2`, `dunevd-crp4`, `dune-vd-coldbox`, `dune10kt-1x2x2`, `dune10kt-1x2x6` (`params_maker`로 선택 후 호출), `iceberg/wcls-sp.jsonnet` |
| `reality`를 선언만 하고 사용 안 함 | `iceberg/wcls-nf-sp.jsonnet` (항상 `simparams.jsonnet`, `:34`), `dune-vd/wcls-nf-sp.jsonnet` (항상 `params.jsonnet`, `:34`) |

PDHD 외에는 `reality`로 `Resampler`를 켜는 entry 파일이 없다.

## 6. 현재 사용 중인 `wire-cell-toolkit/cfg`와의 차이

setup script는 `$WORKDIR/wire-cell-toolkit/cfg`(WCT `0.37.1` checkout)를 `WIRECELL_PATH` 앞에 둔다.
`reality` 관련 차이:

- PDHD `wcls-nf-sp.jsonnet`: `use_resampler = (reality == 'data')`, `tick: 512ns` 동일.
- PDHD `simparams.jsonnet`: `daq.tick: 0.5us`를 명시적으로 추가 (값은 common default와 같음).
- PDVD `simparams.jsonnet`: `daq.nticks`가 `6000` -> `6400`. 즉 이 tree에서는 PDVD `data`(`6000`)와
  `sim`(`6400`)의 `nticks`가 다르다. 단 PDVD `params.jsonnet:115-117`이 `nf.nsamples: 8000`으로
  고정하고 `sim`도 이를 상속하므로, `chndb-base.jsonnet`의 `nsamples`는 두 경우 모두 `8000`이다.
- PDVD `wcls-nf-sp.jsonnet`: `use_resampler`를 `std.extVar`로 받는 구조 동일.

## 7. 업데이트

### [2026-10-12] 공통 base 출처 정정

- 문서 머리의 "공통 base: `pgrapher/dune/params.jsonnet`(WCT release `v0_37_1`)"은 부정확하다.
  `/nfs/data/1/yujin/wire-cell-cfg` 사본에는 `pgrapher/dune/`이 없지만, CVMFS `dunereco v10_26_00d01`
  `wire-cell-cfg`에는 `pgrapher/dune/params.jsonnet`이 있고 `WIRECELL_PATH`에서 WCT release보다 앞선다.
- 공식 dunereco 환경에서는 `adc.resolution = std.extVar("Nbit")`, `elec.gain = std.extVar("elecGain")`인
  dunereco 버전이 쓰인다. 현재 local 환경에서는 `wire-cell-toolkit/cfg`의 버전(`14`, `7.8mV/fC` 고정)이 쓰인다.
- PDHD/PDVD는 `adc.resolution`과 elec gain을 detector `params.jsonnet`에서 직접 정하므로 본문 결론은 바뀌지 않는다.
- 상세: `docs/06_dunereco_wirecell_cfg_common.md` 3.2절, 6절.

### [2026-10-12] 기준 tree 정정: local `wire-cell-cfg` 사본 != 공식 dunereco

- 문서 머리의 "pdhd/protodunevd 디렉터리는 `dunereco v10_26_00d01`의 `wire-cell-cfg`와 동일하다"는 **틀렸다**.
  당시 `diff -rq` 출력을 `head`로 잘라 보는 바람에 차이를 놓쳤다. `/nfs/data/1/yujin/wire-cell-cfg`는
  공식 CVMFS 버전보다 오래된 사본이다. 본문 1-5절은 이 오래된 사본을 기준으로 쓴 것이다.
- 공식 버전(`$D = /cvmfs/dune.opensciencegrid.org/products/dune/dunereco/v10_26_00d01/wire-cell-cfg/pgrapher/experiment`)에서도
  유지되는 결론:
  - `reality == 'data'`이면 `params.jsonnet`, 그 외에는 `simparams.jsonnet`을 쓴다.
  - PDHD는 `use_resampler = (reality == 'data')`, input `tick: 512ns` 고정이다.
    해당 파일: `wcls-nf`, `wcls-nf-sp`, `wcls-nf-sp-img`, 그리고 추가로 `wcls-nf-sp-dnnroi`(`:106`), `wcls-nf-dnnsp-img`(`:34`).
  - PDVD는 `use_resampler`를 fcl에서 받는다. 해당 파일: `wcls-nf`, `wcls-nf-sp`, 그리고 추가로
    `wcls-nf-sp-dnnroi`(`:95`), `wcls-nf-sp-out`(`:67`).
- 공식 버전에서 새로 생기거나 바뀌는 `reality` 관련 차이:

| 항목 | 공식 `params.jsonnet` (data) | 공식 `simparams.jsonnet` (sim) | 본문(구 사본) |
|---|---|---|---|
| PDHD `daq.tick` | `512ns` (`params.jsonnet:109`) | `0.5us` (`simparams.jsonnet:111`) | 두 경우 모두 `0.5us` |
| PDVD `daq.nticks` | `6000` (`params.jsonnet:107`) | `6400` (`simparams.jsonnet:22`) | 두 경우 모두 `6000` |
| PDVD `nf.nsamples` | `8000` (`params.jsonnet:116`) | 상속 (`8000`) | `daq.nticks` |

  - PDHD `daq.tick`은 `params.sim.ductor`/`reframer` 계산(`params.jsonnet:152-164`),
    `funcs.jsonnet:99`, `wcls-rawdigit-dnnsp.jsonnet:70`의 input tick에 쓰인다.
    따라서 공식 버전에서는 `reality`가 PDHD의 tick 관련 값도 바꾼다.
  - PDHD `wcls-sp-dnn-l1sp.jsonnet:120`은 `input_tick = if reality == 'data' then 500ns else 512ns`이다.
    주석(`:113-119`)은 "sim에는 resampler가 없으므로 native `512ns` DAQ tick"이라고 설명하지만,
    `simparams.jsonnet:111`의 sim tick은 `0.5us`이다. 본문 2.4절의 관찰(PDHD MC가 `512ns` tick으로 표기됨)과 같은 문제이다.
- 공식 버전의 기타 차이(noise file 선택 함수, PDVD wire/FR 파일 및 `postgain` 등)는
  `docs/07_pdhd_pdvd_common_files.md`에 정리한다.
