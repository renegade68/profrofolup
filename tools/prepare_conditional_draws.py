"""Freeze NumPy multinomial draw identities and independent conditional references."""
from pathlib import Path
import pandas as pd,numpy as np,json,hashlib
B=Path(__file__).resolve().parent.parent;D=B/'run/KSOI_stata_integration_20261030'
OLD=D/'analysis/results';M=OLD/'bogetoft_rebuild'
register=[]
def emit(key,frame,groups,seed):
    x=frame.assign(cluster=np.asarray(groups)).groupby('cluster').sum()
    rng=np.random.default_rng(seed);w=rng.multinomial(len(x),np.full(len(x),1/len(x)),size=10000)
    np.savetxt(D/f'validation/weights_{key}.csv',w,delimiter=',',fmt='%d',header=','.join(f'w{i+1}' for i in range(len(x))),comments='')
    pd.DataFrame({'cluster':x.index}).to_csv(D/f'validation/clusters_{key}.csv',index=False)
    sums=w@x.to_numpy()
    a=sums[:,0]/sums[:,1]
    ref=pd.DataFrame({'rep':np.arange(1,10001),'ratio':a})
    if sums.shape[1]==4:
        ref['control']=sums[:,2]/sums[:,3];ref['difference']=ref.control-ref.ratio
    ref.to_csv(D/f'validation/reference_draws_{key}.csv',index=False)
    x.to_csv(D/f'validation/reference_aggregates_{key}.csv')
    register.append(dict(key=key,seed=seed,clusters=len(x),events=len(frame),replications=10000,values=frame.columns.tolist(),numpy_version=np.__version__))
for j,g in enumerate(['ai_only','ai_digital_bundle','ai_physical_bundle','ai_cross_bundle']):
    z=[pd.read_csv(OLD/f'strategy_frontier_bootstrap_{g}_h{h}_scores.csv').dropna(subset=['global_score','within_score','within_score_bc','within_ci_low','within_ci_high']) for h in [0,2]]
    q=z[0][['event_id','firm_id','within_score_bc']].merge(z[1][['event_id','within_score_bc']],on='event_id',suffixes=('_0','_2'),validate='one_to_one')
    emit('short_'+g,q[['within_score_bc_0','within_score_bc_2']],q.firm_id,20261007+j)
for g in ['ai_pure','ai_combined']:
    for h in [3,4,5]:
        z=[pd.read_csv(M/f'validated_long_{g}_h{h}_t{t}_scores.csv') for t in [0,h]]
        q=z[0][['event_id','firm_id','farrell_bc']].merge(z[1][['event_id','farrell_bc']],on='event_id',suffixes=('_0','_h'),validate='one_to_one')
        emit(f'long_{g}_{h}',q[['farrell_bc_0','farrell_bc_h']],q.firm_id,20261006+h)
    c=pd.read_csv(M/f'match_{g}_crosswalk.csv')
    c['tf']=c.treated_event_id.str.rsplit('|',n=1).str[0];c['cf']=c.matched_control_event_id.str.rsplit('|',n=1).str[0]
    parent={x:x for x in set(c.tf)|set(c.cf)}
    def find(x):
        while parent[x]!=x:parent[x]=parent[parent[x]];x=parent[x]
        return x
    for t,k in zip(c.tf,c.cf):parent[find(t)]=find(k)
    c['component']=[find(x) for x in c.tf]
    c[['treated_event_id','matched_control_event_id','tf','cf','component']].to_csv(D/f'validation/reference_components_{g}.csv',index=False)
    for role,prefix,key in [('treatment','t','treated_event_id'),('control','c','matched_control_event_id')]:
        for h in [0,3]:
            z=pd.read_csv(M/f'matched_{g}_{role}_h{h}_scores.csv').set_index('event_id');c[prefix+str(h)]=c[key].map(z.farrell_bc)
    assert c[['t0','t3','c0','c3']].notna().all().all()
    emit('matched_'+g,c[['t0','t3','c0','c3']],c.component,20261006)
(D/'validation/SHARED_DRAW_REGISTER.json').write_text(json.dumps(register,indent=2)+'\n')
print('Prepared shared 10,000-replication weights for 12 conditional analyses.')
