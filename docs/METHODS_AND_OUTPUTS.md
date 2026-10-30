# 분석 단계와 원고 연결

| 단계 | 폴더 | 분석 및 원고 연결 |
|---|---|---|
| 1 | `run/KSOI_stata_migration_20261030` | 원자료·기업키 연결·실질변수·6개 기술전략, 표1–2 입력 |
| 2 | `run/KSOI_stata_global_20261030` | 글로벌 DEA 7사양·회귀·중첩가중 사건연구·KM, 표3–5·7, 그림2–3 |
| 3 | `run/KSOI_stata_frontier_20261030` | Mata 공통경계·집단경계 재추정, 표11, 분해 민감도 |
| 4 | `run/KSOI_stata_integration_20261030` | 부분표본/평활 부트스트랩·장기·매칭·조건부 구간, 표6·8–10, 그림4 |
| 5 | `run/KSOI_stata_industry_20261030` | 산업별 DEA·동일기간 선행연구 비교, 부록 표A1–A2 |
| 6 | `run/KSOI_stata_prices_20261030` | 가격 대응 후보, 부록A.3 |
| 7 | `run/KSOI_stata_assets_20261030` | 원자료 자산 항목 점검·참조집합 민감도·비실현가능성 검증, 부록A.3 |
| 8 | `exports.do`, `code/` | 표14개·그림4개 출력, 활용경로 집계(표12 및 부록A.4) |

## 핵심 해석

산출지향 DEA 점수는 1 이상이며 작을수록 비효율성이 낮습니다. 집단 내부 추격비(CU)가 1보다 크면 해당 집단 경계에 대한 격차 축소 방향입니다. 상대적 경계 변화비(FS)는 고정 공통 참조경계와 집단 경계 사이의 변화를 구분합니다. 사건별 분해 항등식과 평균점수의 비율 집계는 구별됩니다.

중첩가중 사건연구는 최초 관측 활용 이후의 중단·재진입을 포함하며, 실제 최초 투자일이나 지속 활용의 인과효과와 같지 않습니다. 편향보정 점수에 조건부인 추격비 구간과 경계를 재추정한 민감도 범위도 구분합니다. 전략 간 우열에는 직접 차이 검정이 필요합니다.

등록 범위의 수치 재현과 원저자 비공개 재표집 구현의 완전 동일성은 별개입니다. 가격·자산 대응 후보의 한계, 후기 표본 감소, 자료판 간 표본 차이는 논문의 해석 범위에 포함됩니다.

## 방법론·의존 소프트웨어

- Bogetoft et al. (2024), Innovation strategies and firm performance. DOI: https://doi.org/10.1007/s11123-024-00727-1
- Badunenko and Mozharovskyi (2016), Nonparametric frontier analysis using Stata. DOI: https://doi.org/10.1177/1536867X1601600302; 공식 패키지 `st0444`: https://www.stata-journal.com/software/sj16-3/
- Simar and Wilson (1998), Sensitivity analysis of efficiency scores: How to bootstrap in nonparametric frontier models. DOI: https://doi.org/10.1287/mnsc.44.1.49
- Li, Morgan and Zaslavsky (2018), Balancing covariates via propensity score weighting. DOI: https://doi.org/10.1080/01621459.2016.1260466

원고의 자료·측정범위와 분석별 표본 요건을 함께 확인하십시오.

## 재현 범위

검증 대상은 본 연구의 응용 사양입니다. 원저자의 비공개 재표집 구현과의 완전한 동일성을 뜻하지 않습니다. 기준 자료판의 분류가능 제조업 표본은 9,039개 기업·49,780개 기업-연도이며, 양수 DEA 완전사례는 48,531개입니다. 분석별 관측요건과 참조경계에 따라 표본 수가 달라집니다.

새 자료판의 표본·가격 개정은 결과에 영향을 줄 수 있습니다. 코드의 열 대응·표본 수 검사가 중단되면 자료판 차이를 확인하고 기록하십시오.
