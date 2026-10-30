# AI 활용기업의 생산 프런티어 추격: Stata 재현 코드

논문 **「AI 활용기업은 생산 프런티어를 추격하는가? — 기술결합, 초기 생산성 위치와 활용 후 성과 변화」**의 Stata/Mata 재현 코드와 사용 안내입니다. 저자: 이춘주, 국방대학교 국방AI/로봇학과.

이 저장소에는 **코드·변수 대응 정의·실행 안내**를 제공합니다. 원자료, 가공 패널, 기업·사건 식별자, 가격 관측값, 재표집 입력, 분석 결과와 원고 파일은 포함하지 않습니다. 이용자는 [MDIS](https://mdis.kostat.go.kr/)와 [한국은행 ECOS](https://ecos.bok.or.kr/)에서 자료를 직접 확보합니다. [데이터 접근·준비 절차](docs/DATA_ACCESS.md)를 먼저 확인하십시오.

## 범위

- 기업활동조사 원자료 → 기업 패널·기술전략·실질 성과변수
- 글로벌 DEA 7사양, 조건부 회귀, 중첩가중 사건연구, 최초통과기간
- 공통 참조경계 분해, 부분표본 편향보정, 장기·매칭 추격비와 재표집 구간
- 산업별 DEA, 국내 선행연구 비교, 가격·자산 민감도
- 본문 표 1–12, 부록 표 A1–A2, 그림 1–4의 수치/그림 출력

계산은 Stata/Mata에서 수행합니다. Python과 R은 원자료 파일명 정규화 및 기존 분석과 동일한 **재표집 추출 순서**를 생성하는 준비 도구입니다. Python/R의 추정 결과를 Stata 분석의 입력으로 사용하지 않습니다. 원저자의 비공개 재표집 구현을 그대로 복제했다는 의미는 아닙니다.

## 실행 환경

검증 환경은 macOS, **Stata/MP 16.1**, zsh, ripgrep(`rg`), Python 3, NumPy 2.3.5, pandas 2.2.3, R 4.6.0입니다. R은 기본 패키지만 사용합니다. `st0444`의 macOS 플러그인은 Intel용이므로 Apple Silicon에서는 Rosetta와 Intel 실행이 가능한 Stata가 필요합니다. Windows/Linux의 통합 실행은 검증하지 않았습니다.

Stata에는 `st0444`(Badunenko and Mozharovskyi, 2016), `kdens`, `moremata`가 필요합니다. 해당 소프트웨어는 공식 배포처에서 별도 설치하며 이 저장소에 재배포하지 않습니다. 일반적인 `dea` 명령으로 대체하면 편향보정·기준경계·점수 정의가 달라질 수 있습니다.

## 빠른 시작

```sh
git clone https://github.com/renegade68/profrofolup.git
cd profrofolup
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
export PYTHON_BIN="$PWD/.venv/bin/python"
export RSCRIPT_BIN="Rscript"
export STATA_BIN="/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp"
"$PYTHON_BIN" tools/prepare.py init
```

Stata의 작업 폴더를 저장소 루트로 설정한 뒤 다음을 실행합니다. 인터넷 연결이 필요하며 의존 소프트웨어를 로컬 `vendor/st0444/`에 설치합니다.

```stata
do install_dependencies.do
```

[데이터 안내](docs/DATA_ACCESS.md)에 따라 준비한 MDIS 다운로드 폴더와 가격 CSV 폴더를 지정합니다. 아래 두 경로는 자신의 실제 경로로 바꿉니다.

```sh
"$PYTHON_BIN" tools/prepare.py init \
  --raw-dir "/path/to/mdis_downloads" \
  --price-dir "/path/to/price_csvs" \
  --vendor-dir "$PWD/vendor/st0444"
"$PYTHON_BIN" tools/prepare.py check
zsh run_all.zsh > execution.log 2>&1
```

정상 종료 시 `execution.log` 마지막에 `KSOI_FULL_RUN_COMPLETE`가 표시됩니다. 전체 경계 재추정·재표집을 포함하므로 장시간 실행될 수 있습니다. 각 작업의 로그에서 Stata 오류와 완료 표지를 확인합니다. 동일 실행 폴더를 다시 실행하면 로컬 결과를 덮어쓰므로 별도의 작업 사본을 사용하십시오.

## 출력과 재현 범위

- `exports/tables/`: 표 14개의 수치 CSV
- `exports/figures/`: 그림 4개의 Stata PNG/GPH 및 입력 수치
- `run/KSOI_stata_*/results/`, `analysis/results/`: 중간·최종 결과
- `run/KSOI_stata_*/validation/`: 로컬에서 생성한 재표집 추출 순서와 비교 자료

출력은 모두 Git에서 제외됩니다. 표 CSV는 수치 검토용이며 HWP 조판표가 아닙니다. Stata 그림은 원고의 R 그림과 디자인이 다를 수 있습니다. [분석 단계와 원고 연결](docs/METHODS_AND_OUTPUTS.md), [검증 범위](docs/VALIDATION.md)를 함께 읽으십시오.

표본 수와 주요 구조에는 기준 자료판에 대한 `assert` 검사를 두었습니다. 새 다운로드의 열 구조나 표본 수가 달라지면 원인을 확인하고 자료판 차이를 기록하십시오. 기준 표본에 맞추기 위한 임의 삭제나 무조건적인 assertion 해제는 재현 절차가 아닙니다.

## 자료와 버전 관리

원자료의 논문 기준 추출일은 2026-08-01입니다. 본 분석기간은 2017–2024년이며, 기업키 연결·시차 구성에는 2006–2024년 원자료를 사용합니다. 가격자료의 추출일·기준연도·자료 개정 여부도 기록하십시오. 코드를 인용하거나 수정 분석에 사용할 때에는 저장소 URL과 **사용한 커밋 SHA**를 함께 남기는 것을 권장합니다.

이 저장소는 논문 등록 범위의 재현 패키지입니다. 기존 연구 폴더의 모든 탐색적 분석을 포함하지 않습니다. 소프트웨어 재사용 허가의 범위가 별도로 필요한 경우 저자에게 확인하십시오. 제3자 패키지와 통계자료에는 각 배포처의 이용조건이 적용됩니다.
