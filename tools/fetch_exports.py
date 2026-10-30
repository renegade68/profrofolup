from pathlib import Path
import csv,json,subprocess,concurrent.futures
O=Path(__file__).resolve().parents[1]/'local_price_downloads'
(O/'sources').mkdir(parents=True,exist_ok=True)
(O/'results').mkdir(parents=True,exist_ok=True)
with (O/'results/partial_industry_ppi.csv').open(encoding='utf-8-sig') as f:m={r['industry_mid_num']:r['item_code'] for r in csv.DictReader(f)}
def get(pair):
 ind,code=pair;p=O/'sources'/f'export_{ind}.json';url=f'https://ecos.bok.or.kr/api/StatisticSearch/sample/json/kr/1/10/402Y014/A/2015/2024/{code}/W/'
 if not p.exists():subprocess.run(['curl','-s','-L','--retry','2','--max-time','25',url,'-o',str(p)],check=True)
 d=json.loads(p.read_text())
 return ind,code,url,d
rows=[];status=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as ex:
 for ind,code,url,d in ex.map(get,list(m.items())+[('total','*AA'),('manufacturing','3AA')]):
  rr=d.get('StatisticSearch',{}).get('row',[]);status.append(dict(industry=ind,code=code,rows=len(rr),status='retrieved_not_author_mapping' if rr else json.dumps(d,ensure_ascii=False)))
  for r in rr:rows.append(dict(industry=ind,year=r['TIME'],export_price=float(r['DATA_VALUE']),item_code=r['ITEM_CODE1'],item_name=r['ITEM_NAME1'],currency=r['ITEM_NAME2'],unit=r['UNIT_NAME'],source_url=url))
for name,rs in [('export_candidate.csv',rows),('export_fetch_status.csv',status)]:
 with (O/'results'/name).open('w',newline='',encoding='utf-8-sig') as f:
  w=csv.DictWriter(f,fieldnames=list(rs[0]));w.writeheader();w.writerows(rs)
print(status)
