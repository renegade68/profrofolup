"""Check the code-only publication boundary and source syntax (no data needed)."""
from pathlib import Path
import json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
files=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard'],cwd=ROOT,text=True).splitlines()
files=sorted(set(files));assert files,'No source files found'
allowed={'.do','.mata','.zsh','.py','.R','.md','.json','.txt'}
for name in files:
 p=Path(name)
 assert not set(p.parts)&{'data','results','validation','logs','vendor','exports','local_inputs','local_price_downloads'},name
 assert p.suffix in allowed or name=='.gitignore',name
 s=(ROOT/p).read_text(encoding='utf-8')
 assert not re.search(r'[BP]:\d{8,}',s),f'Embedded observation identifier: {name}'
 assert ('/'+'Users'+'/') not in s and ('/'+'private'+'/tmp/') not in s,f'Author-specific path: {name}'
 assert not re.search(r'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)',s),f'Credential-like content: {name}'
 if p.suffix=='.py':compile(s,name,'exec')
 if p.suffix=='.json':json.loads(s)
 if p.suffix=='.zsh':subprocess.run(['zsh','-o','NO_BG_NICE','-n',str(ROOT/p)],check=True)
meta=json.loads((ROOT/'run/KSOI_stata_migration_20261030/code/metadata/RAW_METADATA.json').read_text())
assert [r['year'] for r in meta]==list(range(2006,2025))
for r in meta:
 assert set(r)=={'year','zip_id','encoding','column_count','fields'}
 assert all(v['position'] is None or 1<=v['position']<=r['column_count'] for v in r['fields'].values())
print(f'PASS: {len(files)} code/document/metadata files; no data/output/binary paths or embedded observation IDs; syntax and variable metadata checked.')
