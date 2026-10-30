"""Validation fixture: reproduce original Python draw identities, not Stata estimates."""
from pathlib import Path
import csv, random, collections, json, hashlib
B=Path(__file__).resolve().parent.parent;D=B/'run/KSOI_stata_global_20261030'
path=D/'results/enterprise_activity_ai_frontier_gap_duration_spells.csv'
with path.open(encoding='utf-8-sig',newline='') as f:spells=list(csv.DictReader(f))
rng=random.Random(1985);references=[];files=[]
def km(ss,weights):
    s=1.;out=[]
    for h in range(7):
        risk=sum(w for x,w in zip(ss,weights) if int(x['duration'])>=h)
        fail=sum(w for x,w in zip(ss,weights) if int(x['duration'])==h and int(x['event'])==1)
        if risk:s*=1-fail/risk
        out.append(1-s)
    return out
for q in [.25,.5,1.]:
    ss=sorted([x for x in spells if float(x['threshold'])==q],key=lambda x:x['firm_id'])
    firms=[x['firm_id'] for x in ss];assert len(firms)==len(set(firms))==484
    label=int(q*100)
    p=D/f'validation/shared_weights_{label}.csv';files.append(p)
    with p.open('w',newline='') as f:
        w=csv.writer(f);w.writerow([f'w{i+1}' for i in range(len(firms))])
        for rep in range(1,1001):
            # Exactly the original choice sequence, thresholds share the RNG stream.
            draw=[rng.choice(firms) for _ in firms];counts=collections.Counter(draw)
            weights=[counts[x] for x in firms];w.writerow(weights)
            references.extend((q,rep,h,v) for h,v in enumerate(km(ss,weights)))
    (D/f'validation/shared_firms_{label}.csv').write_text('firm_id\n'+'\n'.join(firms)+'\n')
with (D/'validation/python_km_bootstrap_reference.csv').open('w',newline='') as f:
    w=csv.writer(f);w.writerow(['threshold','replication','horizon','probability']);w.writerows(references)
(D/'validation/SHARED_DRAWS.json').write_text(json.dumps(dict(seed=1985,rng='Python random.Random; choice; stream continues across thresholds',ordering='lexicographically sorted unique firm IDs',replications_per_threshold=1000,source=str(path.relative_to(B)),source_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),weights_sha256={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in files}),indent=2)+'\n')
print('Saved shared firm weights and independent Python replication references.')
