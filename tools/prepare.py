"""Prepare private local inputs; never download or publish MDIS microdata."""
from pathlib import Path
import argparse, csv, io, json, re, shutil, zipfile

ROOT = Path(__file__).resolve().parents[1]
STAGES = ['migration', 'frontier', 'integration', 'global', 'industry', 'prices', 'assets']
def stage(name): return ROOT / 'run' / f'KSOI_stata_{name}_20261030'
PRICES = {
 'bok_annual_deflators_2020_100.csv': ['fiscal_year','output_manufacturing_ppi','intermediate_goods_dspi','capital_final_goods_dspi'],
 'partial_industry_ppi.csv': ['industry_mid_num','year','ppi'],
 'capital_candidate.csv': ['year','implicit_investment_deflator'],
 'export_candidate.csv': ['industry','year','export_price'],
}
def directories():
 for name in STAGES:
  for sub in ['data/raw','data/processed','data/external','results','logs','validation','analysis/results/bogetoft_rebuild']:
   (stage(name)/sub).mkdir(parents=True,exist_ok=True)
 for sub in ['results/output_price','results/capital_price']:(stage('prices')/sub).mkdir(parents=True,exist_ok=True)
 for sub in ['results/audit','results/frontiers']:(stage('assets')/sub).mkdir(parents=True,exist_ok=True)
 for sub in ['exports/tables','exports/figures','vendor/st0444']:(ROOT/sub).mkdir(parents=True,exist_ok=True)

def normalize(rawdir):
 meta={r['year']:r for r in json.loads((stage('migration')/'code/metadata/RAW_METADATA.json').read_text())}
 found={}
 def accept(name, data):
  match=re.match(r'(20\d\d)',Path(name).name)
  if not match or not name.lower().endswith('.csv'):return
  y=int(match.group(1))
  if y not in meta:return
  if y in found and found[y]!=data:raise ValueError(f'{y}: conflicting source files; use one download vintage')
  header=next(csv.reader(io.StringIO(data.decode('cp949'))))
  m=meta[y]
  if len(header)!=m['column_count']:raise ValueError(f'{y}: expected {m["column_count"]} columns, got {len(header)}; update and review column mapping first')
  for field,info in m['fields'].items():
   pos=info['position']
   if pos and header[pos-1].strip()!=info['label'].strip():raise ValueError(f'{y}: header mismatch for {field} at column {pos}')
  found[y]=data
 for p in sorted(rawdir.rglob('*')):
  if p.suffix.lower()=='.zip':
   with zipfile.ZipFile(p) as z:
    for n in z.namelist():
     if n.lower().endswith('.csv'):accept(n,z.read(n))
  elif p.suffix.lower()=='.csv':accept(p.name,p.read_bytes())
 if set(found)!=set(meta):raise ValueError(f'Missing years: {sorted(set(meta)-set(found))}')
 for zid in [75764,86378,43412,82803]:
  out=stage('migration')/'data/raw'/f'normalized_{zid}.zip'
  with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
   for y,m in sorted(meta.items()):
    if m['zip_id']==zid:z.writestr(f'{y}.csv',found[y])
 print('MDIS headers checked; 19 CSV byte streams preserved in local ASCII-name ZIPs.')

def prices(folder):
 for name,cols in PRICES.items():
  src=folder/name
  with src.open(encoding='utf-8-sig',newline='') as f:
   reader=csv.DictReader(f)
   if not set(cols)<=set(reader.fieldnames or []):raise ValueError(f'{name}: required columns {cols}')
   rows=list(reader)
   if not rows:raise ValueError(f'{name}: empty file')
  shutil.copy2(src,stage('prices')/'data/external'/name)
  if name.startswith('bok_'):shutil.copy2(src,stage('migration')/'data/external'/name)

def vendor(folder):
 # Install third-party software separately, then stage it in ignored local folders.
 files=[p for p in folder.rglob('*') if p.is_file() and p.suffix in ['.ado','.mlib','.plugin','.sthlp']]
 for name in ['integration','global','industry']:
  dest=stage(name)/'analysis/vendor/st0444';dest.mkdir(parents=True,exist_ok=True)
  for p in files:shutil.copy2(p,dest/p.name)

def check():
 required=[stage('migration')/'data/raw'/f'normalized_{z}.zip' for z in [75764,86378,43412,82803]]
 required+=[stage('migration')/'data/external/bok_annual_deflators_2020_100.csv']
 required+=[stage('prices')/'data/external'/n for n in PRICES]
 for name in ['global','industry','integration']:
  required+=[stage(name)/'analysis/vendor/st0444'/f for f in ['teradial.ado','teradialbc.ado','te_radial.plugin','lnpsf.mlib','lkdens.mlib','lmoremata.mlib']]
 missing=[str(p.relative_to(ROOT)) for p in required if not p.is_file()]
 if missing:raise SystemExit('Missing local inputs/dependencies:\n'+'\n'.join(missing)+'\nSee docs/DATA_ACCESS.md and README.md.')
 print('INPUTS_AND_DEPENDENCIES_READY')

if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('action',choices=['init','check']);p.add_argument('--raw-dir',type=Path);p.add_argument('--price-dir',type=Path);p.add_argument('--vendor-dir',type=Path)
 a=p.parse_args()
 if a.action=='check':check()
 else:
  directories()
  if a.raw_dir:normalize(a.raw_dir.resolve())
  if a.price_dir:prices(a.price_dir.resolve())
  if a.vendor_dir:vendor(a.vendor_dir.resolve())
  print('Local preparation finished. Run check after all inputs are installed.')
