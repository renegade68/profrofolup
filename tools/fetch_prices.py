from pathlib import Path
import subprocess,json,csv,concurrent.futures
O=Path(__file__).resolve().parents[1]/'local_price_downloads'
(O/'sources').mkdir(parents=True,exist_ok=True)
(O/'results').mkdir(parents=True,exist_ok=True)
# Explicit provisional product-to-industry matching. No automatic fallback for other industries.
mapping={10:'3011AA',11:'3012AA',12:'3013AA',15:'3022AA',16:'3031AA',17:'3032AA',19:'3041AA',21:'3054AA',23:'306AA',24:'307AA',25:'308AA',28:'310AA',29:'311AA',30:'3121AA',31:'3122AA'}

def fetch(code):
 url=f'https://ecos.bok.or.kr/api/StatisticSearch/sample/json/kr/1/10/404Y014/A/2015/2024/{code}/'
 p=O/'sources'/f'ppi_values_{code}.json'
 if not p.exists():subprocess.run(['curl','-s','-L','--retry','2','--max-time','25',url,'-o',str(p)],check=True)
 d=json.loads(p.read_text());assert 'StatisticSearch' in d,(code,d)
 rr=d['StatisticSearch']['row'];assert len(rr)==10
 return code,rr,url
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as ex:series=dict((a,(b,c)) for a,b,c in ex.map(fetch,list(mapping.values())+['3AA']))
rows=[]
for ind,code in mapping.items():
 for r in series[code][0]:
  assert r['UNIT_NAME']=='2020=100' and float(r['DATA_VALUE'])>0
  rows.append(dict(industry_mid_num=ind,year=r['TIME'],ppi=float(r['DATA_VALUE']),item_code=code,item_name=r['ITEM_NAME1'],mapping_status='provisional_product_to_KSIC_not_author_verified',source_url=series[code][1]))
with (O/'results/partial_industry_ppi.csv').open('w',encoding='utf-8-sig',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
print('Fetched',len(rows),'industry-year price values; 15 industries; mapping provisional')
