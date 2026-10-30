# 외부 소프트웨어와 통계자료

## 별도 설치 소프트웨어

| 소프트웨어 | 출처 | 이용 방법 |
|---|---|---|
| Stata | [StataCorp](https://www.stata.com/) | 이용자가 정식 라이선스를 확보하여 설치 |
| st0444: teradial, teradialbc | [Badunenko and Mozharovskyi (2016)](https://doi.org/10.1177/1536867X1601600302), [Stata Journal 배포처](https://www.stata-journal.com/software/sj16-3/) | `install_dependencies.do`로 설치하고 배포본의 고지·이용조건 확인 |
| moremata | [Ben Jann 배포처](https://github.com/benjann/moremata) | SSC에서 설치하고 설치 판본의 라이선스 확인 |
| kdens | [Ben Jann, SSC](https://ideas.repec.org/c/boc/bocode/s456410.html) | SSC에서 설치하고 설치 판본의 라이선스 확인 |
| Python, NumPy, pandas, R | [Python](https://www.python.org/), [NumPy](https://numpy.org/), [pandas](https://pandas.pydata.org/), [R](https://www.r-project.org/) | 공식 배포처에서 별도 설치 |

이 저장소는 위 소프트웨어의 소스·도움말·바이너리를 재배포하지 않습니다. 설치 파일은 로컬 `vendor/`에 보관하며 Git에서 제외됩니다. 사용한 패키지 버전을 기록하고 배포본의 저작권·라이선스 고지를 함께 보존하십시오.

## 통계자료

기업활동조사는 [MDIS](https://mdis.kostat.go.kr/), 가격자료는 [한국은행 ECOS](https://ecos.bok.or.kr/)와 한국은행 공표자료에서 이용자가 직접 확보합니다. 기관별 신청·이용·재배포 조건을 따릅니다. 저장소의 변수 대응표는 코드 실행에 필요한 열 위치와 항목명이며, 조사표·코드북 전문이나 관측자료를 포함하지 않습니다.

## 방법론 문헌

방법론 출처는 [분석 단계 안내](METHODS_AND_OUTPUTS.md)에 기재했습니다. 논문 원문·출판사 PDF·원문 표와 그림은 포함하지 않습니다.
