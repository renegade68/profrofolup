version 16.1
mata:
/* Two inputs, one output, VRS, output orientation. No external solver/plugin.
   Pareto pruning is exact under free disposal. Dual vertices enumerate three
   active constraints: 3 observations; 2 observations plus a zero input price;
   or 1 observation plus both zero prices. Evaluation checks input feasibility. */
struct ks_front {
    real rowvector scale
    real matrix planes, lower, reference
    real scalar n_original, n_pareto, max_relative_violation
}
real matrix ks_pareto(real matrix z)
{
    real matrix out
    real scalar i
    z=uniqrows(sort(z,(1,2,-3)))
    out=J(0,3,.)
    for(i=1;i<=rows(z);i++) {
        if(rows(out)) {
            if(any((out[,2]:<=z[i,2]):&(out[,3]:>=z[i,3]))) continue
        }
        out=out\z[i,.]
    }
    return(out)
}
real matrix ks_lower(real matrix z)
{
    real matrix a,h
    real scalar i,n,cross
    a=uniqrows(sort(z[,1..2],(1,2)));h=J(0,2,.)
    for(i=1;i<=rows(a);i++) {
        if(rows(h)) {
            if(a[i,1]==h[rows(h),1] | a[i,2]>=h[rows(h),2]) continue
        }
        while(rows(h)>=2) {
            n=rows(h)
            cross=(h[n,1]-h[n-1,1])*(a[i,2]-h[n-1,2])-(h[n,2]-h[n-1,2])*(a[i,1]-h[n-1,1])
            if(cross>0) break
            h=h[1..n-1,.]
        }
        h=h\a[i,.]
    }
    return(h)
}
struct ks_front scalar ks_build(real matrix raw)
{
    struct ks_front scalar f
    real matrix z,cand,c,b,rest,a,slack,denom,valid
    real colvector dx,dy,dv,det,b1,b2,b0,ok
    real scalar n,i,j,k,pos,m,v,c1,c2,c0,last
    assert(cols(raw)==3 & rows(raw)>0 & all(raw:>0) & !hasmissing(raw))
    f.n_original=rows(raw);f.scale=colmax(raw)
    z=ks_pareto(raw:/f.scale);f.n_pareto=rows(z)
    f.reference=z;f.lower=ks_lower(z);n=rows(z)
    cand=J(max((1,n*(n-1)*(n-2)/6+n*(n-1)+1)),3,.)
    pos=1;cand[1,.]=(0,0,max(z[,3]))
    for(i=1;i<=n-1;i++) {
        for(j=i+1;j<=n;j++) {
            /* Zero-price facets include free input disposal. */
            if(z[j,1]!=z[i,1]) {
                c1=(z[j,3]-z[i,3])/(z[j,1]-z[i,1])
                if(c1>=0) {
                    pos++
                    cand[pos,.]=(c1,0,z[i,3]-c1*z[i,1])
                }
            }
            if(z[j,2]!=z[i,2]) {
                c2=(z[j,3]-z[i,3])/(z[j,2]-z[i,2])
                if(c2>=0) {
                    pos++
                    cand[pos,.]=(0,c2,z[i,3]-c2*z[i,2])
                }
            }
            if(j==n) continue
            rest=z[j+1..n,.]
            dx=rest[,1]:-z[i,1];dy=rest[,2]:-z[i,2];dv=rest[,3]:-z[i,3]
            det=(z[j,1]-z[i,1]):*dy:-dx:*(z[j,2]-z[i,2])
            /* Only exact zero determinants are dropped; all candidates are
               subsequently certified against the entire Pareto reference. */
            b1=((z[j,3]-z[i,3]):*dy:-dv:*(z[j,2]-z[i,2])):/det
            b2=((z[j,1]-z[i,1]):*dv:-dx:*(z[j,3]-z[i,3])):/det
            b0=z[i,3]:-b1:*z[i,1]:-b2:*z[i,2]
            ok=(det:!=0):&(b1:>=0):&(b2:>=0):&(b1:<.):&(b2:<.):&(b0:<.)
            c=select((b1,b2,b0),ok)
            if(rows(c)) {
                cand[pos+1..pos+rows(c),.]=c
                pos=pos+rows(c)
            }
        }
    }
    cand=uniqrows(cand[1..pos,.]);a=(z[,1..2],J(n,1,1));b=J(0,3,.)
    for(i=1;i<=rows(cand);i=i+500) {
        last=min((rows(cand),i+499));c=cand[i..last,.]
        slack=c*a':-z[,3]'
        denom=abs(c)*abs(a)':+z[,3]'
        valid=select(c,rowmin(slack:/denom):>=-1e-12)
        b=b\valid
    }
    assert(rows(b)>0)
    f.planes=uniqrows(b)
    f.max_relative_violation=max((0,max((z[,3]':-f.planes*a'):/z[,3]')))
    assert(f.max_relative_violation<1e-7)
    return(f)
}
real colvector ks_score(struct ks_front scalar f, real matrix raw)
{
    real matrix x,h,chunk
    real colvector p,out
    real scalar i,j,need,last,n
    assert(cols(raw)==3 & all(raw:>0) & !hasmissing(raw))
    x=raw:/f.scale;h=f.lower;n=rows(h)
    for(i=1;i<=rows(x);i++) {
        if(x[i,1]<h[1,1]-1e-12*max((1,abs(h[1,1])))) _error(3498,"Evaluation input below feasible VRS domain")
        j=1
        while(j<n) {
            if(x[i,1]<h[j+1,1]) break
            j++
        }
        need=h[j,2]
        if(j<n) need=h[j,2]+(x[i,1]-h[j,1])*(h[j+1,2]-h[j,2])/(h[j+1,1]-h[j,1])
        if(x[i,2]<need-1e-12*max((1,abs(need)))) _error(3498,"Evaluation input below feasible VRS domain")
    }
    out=J(rows(x),1,.)
    for(i=1;i<=rows(x);i=i+2000) {
        last=min((rows(x),i+1999));chunk=x[i..last,.]
        p=rowmin((chunk[,1..2],J(rows(chunk),1,1))*f.planes')
        out[i..last]=p:/chunk[,3]
    }
    return(out)
}
/* Independent interior-point LP on the same safely dominance-reduced technology.
   No supporting planes are used by the LP solver. */
real matrix ks_lp(real matrix raw, real matrix evaluation)
{
    class LinearProgram scalar q
    real rowvector scale,beta
    real matrix z,x,a,out,p
    real colvector rhs
    real scalar i,val
    scale=colmax(raw);z=ks_pareto(raw:/scale);x=evaluation:/scale
    a=-(z[,1..2],J(rows(z),1,1));rhs=-z[,3];out=J(rows(x),4,.)
    for(i=1;i<=rows(x);i++) {
        q=LinearProgram();q.setMaxOrMin("min")
        q.setCoefficients((x[i,1..2],1));q.setInequality(a,rhs)
        q.setBounds((0,0,.),(.,.,.));q.setTol(1e-10);q.setMaxiter(1000)
        val=q.optimize();out[i,2]=q.converged()
        if(q.converged()) {
            beta=q.parameters();out[i,1]=val/x[i,3]
            out[i,3]=max((0\a*beta'-rhs))
            out[i,4]=1
        }
        else {
            /* Equivalent primal fallback on safely dominance-reduced reference.
               This bounds LP matrix size on the full 48,531-point reference. */
            p=ks_pareto(z)
            q=LinearProgram();q.setMaxOrMin("max")
            q.setCoefficients(p[,3]')
            q.setInequality(p[,1..2]',x[i,1..2]')
            q.setEquality(J(1,rows(p),1),1)
            q.setBounds(J(1,rows(p),0),J(1,rows(p),.))
            q.setTol(1e-10);q.setMaxiter(1000)
            val=q.optimize();out[i,2]=q.converged()
            if(q.converged()) {
                beta=q.parameters();out[i,1]=val/x[i,3]
                out[i,3]=max((0\p[,1..2]'*beta'-x[i,1..2]'\abs(sum(beta)-1)\-min(beta)))
                out[i,4]=2
            }
        }
    }
    return(out)
}
end
