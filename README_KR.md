# Ballclub

[English](README.md) | **한국어**

> **구단 성적표가 아닙니다. 멀티에이전트를 실제 팀처럼 운영하는 하네스입니다.**

모델은 많은데 누구에게 무슨 일을 맡겨야 할지 매번 직접 고르고 계신가요?
서브에이전트가 답을 가져오면 검증도 없이 완료로 치고, 다음 작업에서는 왜 잘했는지
왜 실패했는지 다시 잊어버리시나요?

그것은 사용자가 할 일이 아니라 감독이 할 일입니다.

Ballclub을 설치하고 작업을 맡기세요. 감독은 경기 상황을 읽고, 적격 선수 중 가장
작은 충분한 라인업을 고르고, 완료 조건이 있는 타석을 만듭니다. 반환된 결과는
자동으로 안타가 되지 않습니다. 검증을 통과한 결과만 공식 기록이 되고 다음
라인업에 반영됩니다.

**라인업 구성. 선수의 타석 배치. 결과 검증. 공식 기록.**

> **원본 프로젝트:** [obra/superpowers](https://github.com/obra/superpowers)의
> plugin, skill, hook, script 인프라 일부를 MIT 고지와 함께 계승했습니다. Ballclub의
> 야구식 멀티에이전트 운영 모델, 라우팅, 출전 기록, 검증 기반 스코어링은 독자적인
> 코어입니다.

## 설치

### Codex CLI 및 Codex 앱

```bash
codex plugin marketplace add doominkim/ballclub
codex plugin add ballclub@ballclub-marketplace
```

플러그인이 번들 선수단을 자동으로 관리합니다. 승인된 첫 `SessionStart`에서 Codex용
프로필을 동기화하고, 로드된 선수 목록이 바뀐 경우에만 새 세션 시작을 안내합니다.
선수단 인터뷰나 프로필별 설치 질문은 하지 않습니다.

짧은 `ballclub` 명령으로 Codex를 열고 싶다면 선택적으로 런처를 설치할 수 있습니다.

```bash
bash scripts/install-launcher
ballclub
```

`ballclub`은 별도 설정 프롬프트를 주입하지 않고 Codex를 엽니다. Codex 옵션도 그대로
전달할 수 있습니다. 예: `ballclub -C /path/to/project`

### Claude Code

```bash
claude plugin marketplace add doominkim/ballclub
claude plugin install ballclub@ballclub-marketplace
```

표시되는 hook을 승인하고 새 세션을 시작하면 됩니다.

승인된 첫 `SessionStart`에서 `~/.claude/agents/`의 번들 선수 프로필을 자동으로
동기화합니다. 선수단 변경 안내가 나오면 새 세션을 시작하면 됩니다.

## 30초 설명

```text
사용자 목표 입력
  -> 감독의 목표, 제약, 위험도, 현재 경기 상황 파악
  -> 실제 설계·구현·리뷰 단계마다 선수 타석 배정
  -> 필요한 작전 범위 선택
  -> 해당 범위 안에서 least-sufficient 선수 선발
  -> 완료 조건과 검증 방법이 있는 타석 배정
  -> hook을 통한 출전 기록과 token 수집
  -> 실제 검증 근거에 따른 감독의 공식 기록 판정
  -> 다음 라인업을 위한 스코어카드 피드백
```

Ballclub은 설계→구현→리뷰 체인을 자동으로 만들지 않습니다. 하지만 작업이 실제로
설계, 구현, 리뷰 단계에 들어가면 크기와 무관하게 각 단계에 적격 선수를 반드시
보냅니다. 대화, 상태 확인, 라우팅, 통합, acceptance 검증은 단계 타석이 아닙니다.

## 하이라이트

| 기능 | 하는 일 |
|---|---|
| ⚾ 작전 범위 우선 라우팅 | 모델 서열이 아닌 `Setter`·`Batter`·`Bench`의 허용 범위를 우선 선택 |
| 📋 Least-sufficient 라인업 | 적격 선수군 안에서 위험도와 실패 비용을 감당할 가장 낮은 충분 effort 선택 |
| 🎯 계약이 있는 타석 | 대상, 제약, 완료 조건, 검증 방법이 없는 막연한 위임 방지 |
| 🧠 컨텍스트 보호 | 큰 조사나 독립 구현을 격리하면서 감독의 목표와 종합 판단 유지 |
| ✅ 검증 기반 기록 | 답변 반환만으로 안타를 부여하지 않는 증거 기반 판정 |
| 📈 피드백 스코어카드 | 호출 수, 타율, 홈런, 실책, token 연봉을 다음 선발 판단에 활용 |
| 🪝 자동 출전 수집 | `SubagentStop` hook을 통한 선수와 Coach의 실제 출전 비동기 기록 |
| 🔌 두 하네스 지원 | 같은 운영 모델을 Codex와 Claude Code 플러그인으로 제공 |

## 보고서 플러그인이 아닙니다

스코어카드는 Ballclub의 끝단이지 시작점이 아닙니다.

Ballclub의 핵심은 **누구를 부를지**, **어디까지 맡길지**, **무엇으로 완료를
증명할지**를 하나의 운영 루프로 묶는 데 있습니다. 보고서는 그 루프가 실제로 잘
작동했는지 되돌아보는 계기판입니다. 선수 호출 수만 세는 통계 장식이 아니라 다음
라인업을 더 잘 짜기 위한 운영 데이터입니다.

## 하네스 구조

### 감독

메인 에이전트가 감독입니다. 목표와 제약, 사용자 소통, 라우팅, 통합, 공식 결정,
acceptance 검증과 판정은 감독에게 남아 있습니다. 필수 단계의 산출물을 선수
대신 작성하지 않습니다.

### 선수단

작업 단계 이름으로 선수를 고르지 않습니다. 설계, 구현, 조사, 리뷰는 모두 타석에서
맡을 수 있는 작업이고, 선수군은 **허용된 작전 범위**로 나뉩니다.

| 선수군 | 모델 계열 | 허용 범위 | 프로필 |
|---|---|---|---|
| `Setter` | GPT-5.6 Sol | 설계·구현·복합 판단을 포함한 전체 작전 수행 | `1setter(max)` ~ `5setter(low)` |
| `Batter` | GPT-5.6 Terra | 이미 정해진 범위 안의 제한 실행 | `1batter(xhigh)` ~ `4batter(low)` |
| `Bench` | GPT-5.6 Luna | 조사, 분류, 반복 검증, 근거 수집 | `1bench(high)` ~ `3bench(low)` |
| `Coach` | 반대편 공급자의 외부 자문 | 독립 맥락 분석과 결정 패킷 정제. 파일 수정과 공식 판정은 하지 않음 | `chief-coach`, `coach`, `assistant-coach` |

이 표는 GPT/Codex 감독용 기본 선수단이며 설명용 별칭이 아닙니다. Ballclub의
`SessionStart` bootstrap이 model과 effort가 명시된 Codex custom-agent TOML 15개를
동기화합니다. Claude Code에서는 Setter Fable, Batter Opus, Bench Sonnet, 외부
GPT-5.6 Sol Coach로 구성된 subagent Markdown 15개를 동기화합니다. 계정이나
workspace에서 해당 model을 사용할 수 있는지는 각 하네스의 model availability
정책을 따릅니다.

### 관리형 선수단 수명주기

현재 하네스에 따라 다음 번들 선수단을 자동으로 선택합니다.

| 메인 감독 | Setter | Batter | Bench | Coach |
|---|---|---|---|---|
| GPT / Codex | GPT-5.6 Sol | GPT-5.6 Terra | GPT-5.6 Luna | 외부 Claude Opus |
| Claude Fable 또는 Opus | Claude Fable | Claude Opus | Claude Sonnet | 외부 GPT-5.6 Sol |

같은 공급자의 모델만으로 판단과 검토를 반복하지 않도록 Coach는 반대편 공급자를
사용합니다. 누락된 프로필과 Ballclub이 관리하던 변경 전 파일은 자동으로
갱신합니다. 사용자 지침이 추가된 compatible 파일과 model 정의가 다른 conflict
파일은 그대로 보존합니다.

`1setter`가 모든 상황의 1등 선수라는 뜻은 아닙니다. 전체 프로필에는 단일 순위가
없습니다. 제한 실행이면 Batter 안에서, 근거 수집이면 Bench 안에서 가장 작은
충분한 effort를 고릅니다. 높은 effort라도 작전 권한이 맞지 않으면 선발 대상이
아닙니다.

### 타석 계약

한 번의 서브에이전트 실행은 한 타석입니다. 모든 타석에는 다음 내용이 들어갑니다.

1. 작업 단계와 선발 선수
2. 선수가 소유할 결과
3. 수정 가능 범위와 제약
4. 명시적인 완료 조건
5. 집중 검증 방법
6. 홈런 후보라면 실행 전 고효과 작업 선언

작업이 겹치거나 같은 결정을 기다리면 병렬로 보내지 않습니다. 병렬 실행은 독립성과
컨텍스트 격리가 조정 비용보다 클 때만 사용합니다.
리뷰 단계에서는 독립성이 확보되고 Coach를 사용할 수 있으면 리뷰를 배정받은 적격
player와 Coach를 기본으로 병렬 호출합니다. Coach는 unavailable이거나 리뷰가 독립적이지
않을 때만 생략합니다. Coach는 읽기 전용 자문이며 player나 감독의 acceptance 검증을
대체하지 않습니다. 단계 호출 의무 자체가 병렬 실행을 뜻하지는 않습니다.

### 검증과 공식 기록

```text
returned response != hit
```

선수가 “완료했다”고 말해도 안타가 아닙니다. 감독은 사전에 선언된 acceptance check만
재실행하거나 결과를 확인합니다. correctness, regression, security, 설계 tradeoff,
code quality, diff 판단은 리뷰 단계이므로 적격 player가 필요합니다. 근거가 부족하면
`검수대기`로 남습니다.

| 기록 | 판정 기준 |
|---|---|
| 안타 `hit` | 담당 완료 조건이 집중 검증을 통과한 경우 |
| 볼넷 `walk` | 추측하지 않고 올바르게 중단·상향 보고한 경우 |
| 아웃 `out` | 타당한 상향 보고 없이 실패하거나 미완료된 경우 |
| 실책 `error` | 완료를 주장했지만 확인된 재작업을 발생시킨 경우 |
| 홈런 `homeRun` | 사전에 선언된 고효과 타석이 재작업 없이 검증된 안타가 된 경우 |

### 기록 수집

`SubagentStop` hook은 선언된 선수와 Coach 출전을 감지해 transcript의 런타임 identity,
token 사용량, 출전 메타데이터를 미판정 이벤트로 저장합니다. 수집 실패가 선수
반환을 막지는 않습니다.

```text
${BALLCLUB_DATA:-~/.codex/ballclub}/events/YYYY-MM-DD/
```

Coach는 자문 호출로만 집계하고 선수 연봉, 팀 총연봉, 연봉 점유율, 안타당 token에서
제외합니다. token을 실제 통화 비용으로 추정하지도 않습니다.

## 스코어카드

외울 것은 이것뿐입니다.

```text
$score d                 # 오늘
$score w                 # 이번 주
$score m                 # 이번 달
$score d 2026-07-30      # 특정 날짜
$score m 2026-07         # 특정 월
```

자연어도 똑같이 동작합니다.

```text
오늘 일봉 보여줘
이번 주 구단 성적 보여줘
이번 달 선수 연봉 보여줘
```

기간별 보고서에는 타석, 타수, 안타, 타율, 홈런, 실책, 선수별 token 연봉,
검수대기, Coach 호출, 선언 프로필과 실제 런타임 불일치 경고가 포함됩니다.

직접 생성하거나 판정하려면 다음 명령을 사용합니다.

```bash
node scripts/generate-report.mjs --period daily
node scripts/generate-report.mjs --period weekly
node scripts/generate-report.mjs --period monthly

node scripts/score-appearance.mjs \
  --event <appearance-json> \
  --result <hit|walk|out|error> \
  --home-run <true|false> \
  --rbi <non-negative-integer> \
  --evidence <verification-summary>
```

## Skill은 작전 카드이며 의식 절차가 아닙니다

세션 bootstrap은 `using-ballclub`을 활성화하고, 적용 가능성이 있는 skill을 먼저
확인하게 합니다. 하지만 skill 하나를 불렀다고 TDD, 브레인스토밍, 계획, 리뷰,
worktree가 줄줄이 강제되지는 않습니다. 각 workflow는 자기 trigger가 실제로 맞을
때만 독립적으로 작동합니다. 선수 호출 의무도 실제로 존재하는 설계,
구현, 리뷰 단계에만 적용되며 없는 단계를 새로 만들지 않습니다.

주요 구성은 다음과 같습니다.

- `using-ballclub`: 감독, 선수, Coach, 타석, 공식 기록의 기본 규칙
- `capacity-routing`: 작전 가능 범위와 least-sufficient effort로 라인업 구성
- `dispatching-parallel-agents`: 독립 작업의 병렬 타순과 컨텍스트 격리
- `subagent-driven-development`: 범위가 확정된 구현 타석의 소유권 관리
- `score`: 미판정 출전 검토와 일봉·주봉·월봉 생성
- 개발 workflow skills: 각 trigger에 따라 독립 실행

### 설정 책임 경계

Ballclub 규칙을 전역 `AGENTS.md`에 그대로 복사하지 마세요. 같은 정책이 두 곳에서
독립적으로 바뀌면 라우팅 형식이나 위임 조건이 충돌할 수 있습니다.

| 설정 위치 | 책임 |
|---|---|
| Ballclub skills | 라인업, 작전 범위, least-sufficient 선택, 타석 계약, 검증과 기록의 공통 규칙 |
| 호스트의 `AGENTS.md` | 언어, 표시 형식, 조직별 승인 절차와 같은 사용자·저장소별 override |
| Codex `agents/*.toml`, Claude Code `agents/*.md` | 실제 profile의 모델, effort, 도구, mutation 권한 |
| plugin config와 hook trust | 설치 활성화와 hook 실행 승인 상태 |

충돌 시에는 사용자 지시와 저장소 규칙이 Ballclub의 공통 규칙보다 우선합니다.
호스트별 설정에는 공통 규칙을 반복하기보다 달라지는 부분만 두는 것을 권장합니다.

Ballclub은 관리 대상 파일의 hash를 별도로 기록합니다. 이전에 Ballclub이 설치한
파일은 새 버전으로 안전하게 갱신합니다. name·model·effort가 같고 지침만 다른 사용자
파일은 `compatible`로 인정해 그대로 유지합니다. 실제 model 정의가 다르거나 출처를
확인할 수 없는 파일은 `conflict`로 보존합니다. `$setup-ballclub`은 이런 충돌을
진단·복구하는 명시적 도구이며, 강제 교체는 대상 파일별 승인 뒤에만 수행하고 기존
파일을 먼저 백업합니다.

더 깊게 보려면 [아키텍처](docs/architecture.md),
[런타임 흐름](docs/runtime-flow.md), [경기 모델](docs/game-model.md)을 참고하세요.

## 업데이트

새 세션 시작 시 하루에 최대 한 번 새 버전을 확인합니다. 사용자 승인 없이
업데이트하지 않고, 업데이트 뒤에는 새 세션을 시작해야 합니다.

```bash
BALLCLUB_DISABLE_UPDATE_CHECK=true
```

## 검증

```bash
npm test
claude plugin validate .
```

## 라이선스와 출처

Ballclub은 MIT License로 배포됩니다. `obra/superpowers`에서 가져오거나 수정한
부분의 원본 고지는 `third_party/superpowers-LICENSE`에 보존되어 있습니다.
Ballclub은 독립 프로젝트이며 원본 프로젝트 관리자와 제휴하거나 보증받은 프로젝트가
아닙니다.
