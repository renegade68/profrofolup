# AI 활용기업의 생산 프런티어 추격: Stata 재현 코드

논문 「AI 활용기업은 생산 프런티어를 추격하는가? — 기술결합, 초기 생산성 위치와 활용 후 성과 변화」의 분석 코드입니다. 저자: 이춘주, 국방대학교 국방AI/로봇학과.

원자료에서 분석 패널을 구성하고 본문 표 1–12, 부록 표 A1–A2, 그림 1–4를 생성합니다. 데이터는 포함하지 않습니다. [데이터 준비 안내](docs/DATA_ACCESS.md)에 따라 MDIS와 한국은행에서 직접 확보하십시오.

## 실행 환경

검증 환경: macOS, Stata/MP 16.1, zsh, ripgrep(`rg`), Python 3, NumPy 2.3.5, pandas 2.2.3, R 4.6.0. Windows/Linux 통합 실행은 검증하지 않았습니다.

분석은 Stata/Mata로 실행합니다. Python/R은 자료 준비와 재표집 추출 순서를 생성하는 데 사용합니다. Stata 패키지 `st0444`, `moremata`, `kdens`는 아래 설치 명령으로 확보합니다. `st0444`의 Intel용 macOS 플러그인을 사용하므로 Apple Silicon에서는 Rosetta와 Intel 실행이 가능한 Stata가 필요합니다.

## 설치

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

`STATA_BIN`은 자신의 Stata 설치 경로로 바꿉니다. Stata의 작업 폴더를 저장소 루트로 설정한 뒤 다음을 실행합니다. 인터넷 연결이 필요합니다.

```stata
do install_dependencies.do
```

## 자료 준비와 실행

MDIS 기업활동조사 2006–2024년 자료와 가격 CSV 4개를 준비합니다. 본문 분석기간은 2017–2024년이며, 이전 연도는 기업키 연결과 시차 구성에 사용합니다. 파일 형식과 가격자료 확보 방법은 [데이터 준비 안내](docs/DATA_ACCESS.md)에 있습니다.

아래 두 자료 경로를 자신의 폴더로 바꿔 실행합니다.

```sh
"$PYTHON_BIN" tools/prepare.py init \
  --raw-dir "/path/to/mdis_downloads" \
  --price-dir "/path/to/price_csvs" \
  --vendor-dir "$PWD/vendor/st0444"
"$PYTHON_BIN" tools/prepare.py check
zsh run_all.zsh > execution.log 2>&1
```

전체 경계 재추정과 재표집으로 실행에 시간이 걸립니다. 정상 완료 시 `execution.log` 끝에 `KSOI_FULL_RUN_COMPLETE`가 표시됩니다. 재실행하면 같은 폴더의 결과를 덮어씁니다.

## 결과 확인

- `exports/tables/`: 표 14개의 수치 CSV
- `exports/figures/`: 그림 4개의 PNG/GPH와 입력 수치
- `run/KSOI_stata_*/results/`, `run/KSOI_stata_*/analysis/results/`: 중간·최종 결과

표 CSV는 수치 확인용이며, 그림 디자인은 원고와 다를 수 있습니다. 실행 오류나 표본 수 차이가 발생하면 자료판·열 대응을 먼저 확인하십시오. [분석 단계와 해석 범위](docs/METHODS_AND_OUTPUTS.md)를 함께 참고하십시오.

## 출처와 이용조건

자료 추출일·제공 유형과 사용한 커밋 SHA를 기록하십시오. 논문 기준 MDIS 추출일은 2026-08-01입니다. 외부 소프트웨어와 통계자료의 출처·이용조건은 [외부 자료 안내](docs/THIRD_PARTY.md)에 정리했습니다.

이 저장소에는 별도의 재사용 라이선스가 지정되어 있지 않습니다.
