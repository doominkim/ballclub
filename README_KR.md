# Ballclub

[English](README.md) | **한국어**

> **원본 프로젝트:** [obra/superpowers](https://github.com/obra/superpowers)가
> 원본이야. Ballclub은 원본의 plugin, skill, hook, script 인프라 일부를 MIT
> 고지와 함께 계승하지만, 야구식 멀티에이전트 운영 모델을 독자적인 코어로
> 사용해.

**라인업을 짜고, 선수를 타석에 보내고, 결과를 기록한다.**

Ballclub은 Codex와 Claude Code를 위한 야구식 멀티에이전트 하네스야. 메인
에이전트는 감독, 실행 가능한 capacity profile은 선수, Coach profile은 외부
자문단으로 취급해. 서브에이전트의 한 번의 실행은 하나의 타석이 되고,
Ballclub은 작업에 적합한 선수를 고르고 출전 기록을 수집한 뒤 검증된 결과만
공식 기록으로 판정해. 기록은 일봉·주봉·월봉으로 확인할 수 있어.

## 경기 모델

| 야구 개념 | 에이전트 운영 |
|---|---|
| 감독 | 목표, 제약, 라인업, 종합 판단, 사용자 소통을 책임지는 메인 에이전트 |
| 선수 | 실제 작업을 수행할 수 있는 Setter·Batter·Bench profile |
| Coach | 결정 패킷을 검토하지만 파일 수정이나 공식 기록 판정은 하지 않는 외부 자문단 |
| 라인업 | 작업에 적격인 profile 중 가장 낮은 충분 effort를 선택하는 과정 |
| 타석 | 완료 조건과 검증 방법이 명시된 한 번의 서브에이전트 실행 |
| 안타 | 담당 완료 조건이 집중 검증을 통과한 결과 |
| 볼넷 | 추측하지 않고 올바르게 중단·상향 보고한 결과 |
| 아웃 | 타당한 상향 보고 없이 실패하거나 미완료된 결과 |
| 실책 | 완료를 주장했지만 확인된 재작업을 발생시킨 결과 |
| 홈런 | 사전에 고효과 작업으로 선언된 타석이 재작업 없이 검증된 안타가 된 결과 |
| 연봉 | 기록된 선수 token 사용량. Coach token은 제외 |

응답을 반환했다는 이유만으로 안타가 되지는 않아. 감독이 완료 조건과 검증
근거를 확인할 수 없으면 해당 타석은 `검수대기`로 남아.

## 설치

### Codex CLI 및 Codex 앱

```bash
codex plugin marketplace add doominkim/ballclub
codex plugin add ballclub@ballclub-marketplace
```

### Claude Code

```bash
claude plugin marketplace add doominkim/ballclub
claude plugin install ballclub@ballclub-marketplace
```

표시되는 hook 승인을 완료한 뒤 새 세션을 시작해.

## 코어 실행 흐름

```text
감독이 경기 상황을 파악
  -> 작업 범위에 맞는 라인업 구성
  -> 완료 조건과 검증 방법이 있는 타석 정의
  -> 선수를 타석에 배치
  -> 반환된 출전 기록 수집
  -> 검증 후 공식 기록 판정
  -> 스코어카드와 다음 라인업에 반영
```

`skills/using-ballclub`은 구단 운영 규칙을 정의해. `capacity-routing`은
라인업을 구성하고, dispatch 계열 skill은 타석을 정의하며, `score`는
공식 기록 검토와 기간별 보고서를 담당해. 기존 개발 workflow skill은 각각
독립적으로 작동하고, 야구식 용어가 TDD·계획·리뷰 같은 방법론을 자동으로
강제하지는 않아.

## 스코어카드 호출

명시적으로 호출하려면 기간을 한 글자로 붙이면 돼.

```text
$score d                 # 오늘 일봉
$score w                 # 이번 주 주봉
$score m                 # 이번 달 월봉
$score d 2026-07-30      # 특정 날짜
$score m 2026-07         # 특정 월
```

평소에는 skill 이름을 외우지 않고 자연어로 요청해도 돼.

```text
오늘 일봉 보여줘
이번 주 구단 성적 보여줘
이번 달 선수 연봉 보여줘
```

지원하는 주요 표현은 `일봉`, `주봉`, `월봉`, `구단 성적`, `선수 호출`,
`안타`, `타율`, `홈런`, `실책`, `token 연봉`, `안타당 token`이야.

## 기록과 보고서

기본 실행 데이터 경로는 `~/.codex/ballclub`이야. 다른 경로를 사용하려면
`BALLCLUB_DATA`를 지정해.

```bash
node scripts/generate-report.mjs --period daily
node scripts/generate-report.mjs --period weekly
node scripts/generate-report.mjs --period monthly
```

공식 기록은 다음 명령으로 판정해.

```bash
node scripts/score-appearance.mjs \
  --event <appearance-json> \
  --result <hit|walk|out|error> \
  --home-run <true|false> \
  --rbi <non-negative-integer> \
  --evidence <verification-summary>
```

Coach 출전에는 선수 기록을 부여할 수 없으며, 이벤트 디렉터리 밖의 파일도
수정할 수 없게 제한돼 있어.

## 업데이트

Ballclub은 새 세션 시작 시 하루에 최대 한 번 새 버전을 확인해. 사용자 승인
없이 업데이트하지 않으며, 업데이트가 끝나면 새 세션을 시작해야 해. 확인을
끄려면 `BALLCLUB_DISABLE_UPDATE_CHECK=true`를 사용해.

## 검증

```bash
npm test
claude plugin validate .
```

## 라이선스와 출처

Ballclub은 MIT License로 배포돼. `obra/superpowers`에서 가져오거나 수정한
부분의 원본 고지는 `third_party/superpowers-LICENSE`에 보존돼 있어.
Ballclub은 독립 프로젝트이며 원본 프로젝트 관리자와 제휴하거나 보증받은
프로젝트가 아니야.
