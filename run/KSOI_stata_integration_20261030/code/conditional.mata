version 16.1
mata:
real scalar ci_find(real colvector p, real scalar a)
{
    while(p[a]!=a) {
        p[a]=p[p[a]]
        a=p[a]
    }
    return(a)
}
real colvector ci_components(real colvector t, real colvector c, real scalar n)
{
    real colvector p,out
    real scalar i
    p=1::n
    for(i=1;i<=rows(t);i++) p[ci_find(p,t[i])]=ci_find(p,c[i])
    out=J(rows(t),1,.)
    for(i=1;i<=rows(t);i++) out[i]=ci_find(p,t[i])
    return(out)
}
real scalar ci_quantile(real colvector x, real scalar p)
{
    real scalar z,lo,hi
    x=sort(x,1);z=(rows(x)-1)*p;lo=floor(z);hi=ceil(z)
    if(lo==hi) return(x[lo+1])
    return(x[lo+1]*(hi-z)+x[hi+1]*(z-lo))
}
real matrix ci_ratios(real matrix x, real matrix w)
{
    real matrix s,r
    assert(cols(w)==rows(x));assert(all(rowsum(w):==rows(x)))
    s=w*x;assert(!hasmissing(s));assert(all(s[,2]:>0))
    r=s[,1]:/s[,2]
    if(cols(x)==4) {
        assert(all(s[,4]:>0))
        r=(r,s[,3]:/s[,4],s[,3]:/s[,4]-r)
    }
    return(r)
}
end
