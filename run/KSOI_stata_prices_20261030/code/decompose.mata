version 16.1
mata:
struct ks_cell {
    real matrix A,B
    real colvector firm,indices
    string colvector events
}
string colvector ks_events(struct ks_cell rowvector cc, real scalar g)
{
    return(cc[g].events)
}
struct ks_cell rowvector ks_cells(real matrix z, real colvector gr, real colvector horizon, real colvector fid, string colvector event)
{
    struct ks_cell rowvector cc
    real scalar g
    real colvector a,b
    cc=ks_cell(1,3)
    for(g=1;g<=3;g++) {
        a=selectindex((gr:==g):&(horizon:==0));b=selectindex((gr:==g):&(horizon:==3))
        assert(all(event[a]:==event[b]));assert(all(fid[a]:==fid[b]))
        cc[g].A=z[a,.];cc[g].B=z[b,.];cc[g].firm=fid[a];cc[g].indices=a;cc[g].events=event[a]
    }
    return(cc)
}
real matrix ks_event_scores(struct ks_cell rowvector cc, struct ks_front scalar globalf)
{
    real matrix out,one
    real colvector f0,f3,h0,h3,g0,g3
    struct ks_front scalar fa,fb
    real scalar g
    out=J(0,11,.)
    for(g=1;g<=3;g++) {
        fa=ks_build(cc[g].A);fb=ks_build(cc[g].B)
        printf("CELL %g: n=%g pareto=%g/%g planes=%g/%g\n",g,rows(cc[g].A),fa.n_pareto,fb.n_pareto,rows(fa.planes),rows(fb.planes))
        f0=ks_score(fa,cc[g].A);f3=ks_score(fb,cc[g].B)
        h0=ks_score(globalf,cc[g].A);h3=ks_score(globalf,cc[g].B)
        g0=h0:/f0;g3=h3:/f3
        one=(cc[g].indices,J(rows(f0),1,g),f0,f3,h0,h3,g0,g3,f0:/f3,g0:/g3,h0:/h3)
        out=out\one
    }
    return(out)
}
real rowvector ks_summary(real matrix z)
{
    return((mean(z[,3])/mean(z[,4]),mean(z[,7])/mean(z[,8]),mean(z[,5])/mean(z[,6]),exp(mean(ln(z[,9]))),exp(mean(ln(z[,10]))),exp(mean(ln(z[,11])))))
}
real matrix ks_points(struct ks_cell rowvector cc, real matrix es)
{
    real matrix p
    real scalar g
    p=J(3,9,.)
    for(g=1;g<=3;g++) p[g,.]=(g,rows(cc[g].A),rows(uniqrows(cc[g].firm)),ks_summary(select(es,es[,2]:==g)))
    return(p)
}
real scalar ks_quantile(real colvector x, real scalar p)
{
    real scalar z,lo,hi
    x=sort(x,1);z=(rows(x)-1)*p;lo=floor(z);hi=ceil(z)
    if(lo==hi) return(x[lo+1])
    return(x[lo+1]*(hi-z)+x[hi+1]*(z-lo))
}
real matrix ks_intervals(real matrix jd)
{
    real matrix a,out
    real scalar g
    out=J(3,4,.)
    for(g=1;g<=3;g++) {
        a=select(jd,jd[,2]:==g)
        out[g,.]=(ks_quantile(a[,3],.025),ks_quantile(a[,3],.975),ks_quantile(a[,4],.025),ks_quantile(a[,4],.975))
    }
    return(out)
}
real rowvector ks_resampled(struct ks_cell scalar cell, struct ks_front scalar rf, real colvector weights)
{
    struct ks_front scalar fa,fb
    real matrix a,b
    real colvector take,w,f0,f3,h0,h3
    take=selectindex(weights:>0);w=weights[take]
    a=cell.A[take,.];b=cell.B[take,.]
    fa=ks_build(a);fb=ks_build(b)
    f0=ks_score(fa,a);f3=ks_score(fb,b);h0=ks_score(rf,a);h3=ks_score(rf,b)
    return((quadcross(w,f0)/quadcross(w,f3),quadcross(w,h0:/f0)/quadcross(w,h3:/f3)))
}
real matrix ks_joint(real matrix ref, real colvector fid, struct ks_cell rowvector cc, real matrix weights, real scalar reps)
{
    struct ks_front scalar rf
    real matrix out
    real colvector w
    real scalar k,g
    out=J(reps*3,4,.)
    for(k=1;k<=reps;k++) {
        w=weights[,k];rf=ks_build(select(ref,w[fid]:>0))
        for(g=1;g<=3;g++) out[(k-1)*3+g,.]=(k,g,ks_resampled(cc[g],rf,w[cc[g].firm]))
        if(mod(k,25)==0 | k==reps) printf("Joint %g/%g\n",k,reps)
    }
    return(out)
}
real matrix ks_equal(struct ks_front scalar rf, struct ks_cell rowvector cc, real matrix eq1, real matrix eq2, real matrix eq3, real scalar reps)
{
    struct ks_cell scalar z
    real matrix out,eq
    real colvector j,w
    real scalar k,g
    out=J(reps*3,5,.)
    for(k=1;k<=reps;k++) {
        for(g=1;g<=3;g++) {
            if(g==1) eq=eq1
            else if(g==2) eq=eq2
            else eq=eq3
            j=eq[,k];z.A=cc[g].A[j,.];z.B=cc[g].B[j,.]
            w=J(rows(j),1,1)
            out[(k-1)*3+g,.]=(k,g,rows(j),ks_resampled(z,rf,w))
        }
        if(mod(k,100)==0 | k==reps) printf("Equal-size %g/%g\n",k,reps)
    }
    return(out)
}
end
