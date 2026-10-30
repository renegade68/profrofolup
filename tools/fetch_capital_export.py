from pathlib import Path
import subprocess,json,csv
O=Path(__file__).resolve().parents[1]/'local_price_downloads'
(O/'sources').mkdir(parents=True,exist_ok=True)
(O/'results').mkdir(parents=True,exist_ok=True)
def get(service,code,start,end,suffix='',name=None):
 p=O/'sources'/(name or f'{service}_{code}_{start}.json')
 url=f'https://ecos.bok.or.kr/api/{service}/sample/json/kr/{start}/{end}/{code}/{suffix}'
 if not p.exists():subprocess.run(['curl','-s','-L','--retry','2','--max-time','25',url,'-o',str(p)],check=True)
 d=json.loads(p.read_text());assert service in d,(url,d)
 return d[service]['row']
for a,b in [(11,20),(21,30),(31,38)]:
 for r in get('StatisticItemList','200Y112',a,b):print('capital',r['ITEM_CODE'],r['ITEM_NAME'],r['CYCLE'])
for a,b in [(711,720),(721,725)]:
 for r in get('StatisticItemList','402Y014',a,b):print('export',r['GRP_CODE'],r['ITEM_CODE'],r['ITEM_NAME'],r['CYCLE'])
nom=get('StatisticSearch','200Y135',1,10,'A/2015/2024/1100103/',name='manufacturing_gfcf_nominal.json')
real=get('StatisticSearch','200Y136',1,10,'A/2015/2024/1100103/',name='manufacturing_gfcf_real.json')
x={r['TIME']:r for r in real};rows=[]
for r in nom:
 s=x[r['TIME']];rows.append(dict(year=r['TIME'],nominal=float(r['DATA_VALUE']),real=float(s['DATA_VALUE']),implicit_investment_deflator=100*float(r['DATA_VALUE'])/float(s['DATA_VALUE']),unit_nominal=r['UNIT_NAME'],unit_real=s['UNIT_NAME'],status='manufacturing_aggregate_candidate_not_author_confirmed'))
with (O/'results/capital_candidate.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
