version 16.1
mata:
/* Explicit feasible-domain classification. Numerical tolerance is the same
   normalized 1e-12 used by the existing strict ks_score routine. */
real colvector asset_feasible(struct ks_front scalar f, real matrix raw)
{
    real matrix x,h
    real colvector ok
    real scalar i,j,n,need
    assert(cols(raw)==3 & all(raw:>0) & !hasmissing(raw))
    x=raw:/f.scale;h=f.lower;n=rows(h);ok=J(rows(x),1,1)
    for(i=1;i<=rows(x);i++) {
        if(x[i,1]<h[1,1]-1e-12*max((1,abs(h[1,1])))) {
            ok[i]=0
            continue
        }
        j=1
        while(j<n) {
            if(x[i,1]<h[j+1,1]) break
            j++
        }
        need=h[j,2]
        if(j<n) need=h[j,2]+(x[i,1]-h[j,1])*(h[j+1,2]-h[j,2])/(h[j+1,1]-h[j,1])
        if(x[i,2]<need-1e-12*max((1,abs(need)))) ok[i]=0
    }
    return(ok)
}
real matrix asset_score(struct ks_front scalar f, real matrix raw)
{
    real colvector ok,ix,s
    ok=asset_feasible(f,raw);ix=selectindex(ok);s=J(rows(raw),1,.)
    if(rows(ix)) s[ix]=ks_score(f,raw[ix,.])
    return((s,ok))
}
/* Analytic domain probes: each input alone can be affordable while their
   combination is infeasible. Missing scores must accompany explicit flags. */
zz=(1,2,2\2,1,2)
ff=ks_build(zz)
xx=(1.5,1.5,1\1,1,1\.5,3,1\3,.5,1\3,3,1\1,2,1)
ss=asset_score(ff,xx)
assert(all(ss[,2]:==(1\0\0\0\1\1)))
assert(all(ss[(1\5\6),1]:==2))
assert(all(ss[(2\3\4),1]:==.))
printf("Explicit feasible-domain analytic checks passed\n")
end
