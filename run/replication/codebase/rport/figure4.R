## ============================================================================
## Figure 4 : matched CPS -- missing/excess jobs for incumbents vs new entrants
## port of Figure4_for_QJE.do (core -4..+4 window; supplies Table4 m1/m2 rows)
## ============================================================================
source("/workspace/output/replication/codebase/rport/qje_lib.R")
options(width=160); t0 <- Sys.time()

bins_after  <- c("m4","m3","m2","m1","p0","p1","p2","p3","p4")
times_after <- c("", "L4", "L8", "L12", "L16")
treatafter  <- as.vector(outer(times_after, bins_after, function(a,b) paste0(a,"treat_",b)))
times_before<- c("F12","F8")
treatbefore <- as.vector(outer(times_before, bins_after, function(a,b) paste0(a,"treat_",b)))
window_vars <- paste0("window_", bins_after)
control_cat <- c("postcont_m","precont_m","earlycont_m","postcont_p","precont_p","earlycont_p")
controlf_cat<- c("postcontf_m","precontf_m","earlycontf_m","postcontf_p","precontf_p","earlycontf_p")
below_names <- as.vector(outer(times_after, c("m1","m2","m3","m4"), function(a,b) paste0(a,"treat_",b)))
above_names <- as.vector(outer(times_after, c("p0","p1","p2","p3","p4"), function(a,b) paste0(a,"treat_",b)))

need <- unique(c("statenum","quarterdate","wagebinstateprev","wagequarterdate","year","wagebins",
  "cleansample","population","fedincrease","overallcountgroup","wtoverall1979",
  "m_count","m_countall","m_overallcountpc","m_overallcountpcall",
  "mt_countall","mt_overallcountpcall","emp_prev","MW_realM25",
  "F1MW_realM25","F2MW_realM25","F3MW_realM25","F4MW_realM25","treat_p0",
  treatafter, treatbefore, window_vars, control_cat, controlf_cat))

cat("Reading matched panel (1.5GB) ...\n")
dt <- as.data.table(read_dta(paste0(DATA,"state_panels_with3quant1979_matched.dta"),
                             col_select = tidyselect::all_of(need)))
setnames(dt, "wagebinstateprev", "wagebinstate")
qcew <- as.data.table(read_dta(paste0(DATA,"qcew_state_overall_counts_2016.dta")))
setnames(qcew,"statefips","statenum"); qcew[, quarterdate := yq(year,quarter)]
dt <- merge(dt, qcew[,.(statenum,quarterdate,emp)], by=c("statenum","quarterdate"), all.x=TRUE)
dt[, multiplier := emp/mt_countall][is.na(multiplier)|multiplier==0, multiplier:=1]
for (v in c("m_count","m_overallcountpc","m_overallcountpcall","m_countall")) dt[, (v):=get(v)*multiplier]
dt[, mt_overallcountpcall := mt_overallcountpcall*multiplier]

sq <- unique(dt[,.(statenum,quarterdate,fedincrease,overallcountgroup)])
for (k in 1:4){ tmp<-copy(sq); tmp[,quarterdate:=quarterdate-k]
  setnames(tmp,c("fedincrease","overallcountgroup"),c(paste0("F",k,"fed"),paste0("F",k,"grp")))
  dt<-merge(dt,tmp,by=c("statenum","quarterdate"),all.x=TRUE)}
condk<-function(fed,grp) st_ne(fed,1)&st_nm(fed)&st_gt(grp,0)&st_nm(grp)
denom<-1/(1+16/4); fac<-4*denom; W<-dt$wtoverall1979

# E uses mt_overallcountpcall (total), same for both groups
selE<-(condk(dt$F1fed,dt$F1grp)|condk(dt$F2fed,dt$F2grp)|condk(dt$F3fed,dt$F3grp)|condk(dt$F4fed,dt$F4grp))&
      dt$year>=1979&st_eq(dt$cleansample,1)
E<-wmean(dt$mt_overallcountpcall[selE],W[selE])
cat(sprintf("E(matched)=%.5f\n", E))

fe_cat<-paste(sprintf("factor(%s)",c(control_cat,controlf_cat)),collapse=" + ")
fe1<-paste("wagebinstate + wagequarterdate +",fe_cat)
rhs<-paste(c(treatafter, window_vars, treatbefore), collapse=" + ")

analyze <- function(gval, gname) {
  # cumulative sums within (emp_prev, state, quarter)
  ord<-order(dt$emp_prev, dt$statenum, dt$quarterdate, dt$wagebins)
  D<-data.table(ep=dt$emp_prev,sn=dt$statenum,qd=dt$quarterdate,
                pc=dt$m_overallcountpc, wbpc=dt$wagebins*dt$m_count/(100*dt$population))[ord]
  D[,pcrsum:=cumsum(pc),by=.(ep,sn,qd)]; D[,wbrsum:=cumsum(wbpc),by=.(ep,sn,qd)]
  pcr<-numeric(nrow(dt)); pcr[ord]<-D$pcrsum; wbr<-numeric(nrow(dt)); wbr[ord]<-D$wbrsum
  gsel <- dt$emp_prev==gval
  selB<-((condk(dt$F1fed,dt$F1grp)&st_eq((dt$wagebins+25)/100,dt$F1MW_realM25))|
         (condk(dt$F2fed,dt$F2grp)&st_eq((dt$wagebins+25)/100,dt$F2MW_realM25))|
         (condk(dt$F3fed,dt$F3grp)&st_eq((dt$wagebins+25)/100,dt$F3MW_realM25))|
         (condk(dt$F4fed,dt$F4grp)&st_eq((dt$wagebins+25)/100,dt$F4MW_realM25)))&
        dt$year>=1979&st_eq(dt$cleansample,1)&gsel
  B<-wmean(pcr[selB],W[selB])/E; EWB<-wmean(wbr[selB],W[selB])
  selWM<-st_eq(dt$treat_p0,1)&dt$year>=1979&st_eq(dt$cleansample,1)
  wagemult<-wmean(dt$wagebins[selWM],W[selWM])/100

  DD<-cbind(dt,Y=dt$m_overallcountpc,w=W)[dt$emp_prev==gval & dt$year>=1979 &
      st_eq(dt$cleansample,1) & !is.na(dt$m_overallcountpc) & !is.na(W) & W>0]
  m<-feols(as.formula(paste("Y ~",rhs,"|",fe1)), data=DD, weights=~w, cluster=~statenum)
  b<-coef(m); V<-vcov(m); beta<-b[treatafter]; beta[is.na(beta)]<-0
  Vf<-matrix(0,length(treatafter),length(treatafter),dimnames=list(treatafter,treatafter))
  ex<-intersect(treatafter,colnames(V)); Vf[ex,ex]<-V[ex,ex]; dof<-length(unique(DD$statenum))-1
  sb<-as.numeric(treatafter%in%below_names); sa<-as.numeric(treatafter%in%above_names); sba<-sb+sa
  wbw<-setNames(numeric(length(treatafter)),treatafter)
  for(tt in times_after){for(j in 1:4)wbw[paste0(tt,"treat_m",j)]<-wagemult-j
                         for(j in 0:4)wbw[paste0(tt,"treat_p",j)]<-wagemult+j}
  below_E<-lincom_wt(sb*fac/E,beta,Vf,dof); above_E<-lincom_wt(sa*fac/E,beta,Vf,dof)
  bunching_E<-lincom_wt(sba*fac/E/B,beta,Vf,dof)
  f_bunch<-function(bb)sum(sba*bb)*fac/E/B; f_wbterm<-function(bb)sum(wbw*bb)*fac/EWB
  f_WBtot<-function(bb)(f_wbterm(bb)-f_bunch(bb))/(1+f_bunch(bb))
  WB_E<-nlcom_fun(f_WBtot,beta,Vf,dof)
  wbY<-setNames(numeric(length(treatafter)),treatafter)
  for(tt in times_after) for(j in 1:4) wbY[paste0(tt,"treat_m",j)]<- -j
  WB_nospill<-lincom_wt(wbY*fac/EWB,beta,Vf,dof)
  f_nospill<-function(bb)sum(wbY*bb)*fac/EWB
  f_spill<-function(bb)1-f_nospill(bb)/f_WBtot(bb)
  spill<-nlcom_fun(f_spill,beta,Vf,dof)
  # per-bin t=0 estimate for the figure
  binest<-data.table(bin=-4:4, est=NA_real_, lo=NA_real_, hi=NA_real_)
  allb<-c("m4","m3","m2","m1","p0","p1","p2","p3","p4")
  for(i in seq_along(allb)){ nm<-paste0("treat_",allb[i])
    if(nm%in%names(b)){bh<-b[nm]*4/E; bs<-sqrt(V[nm,nm])*4/E
      set(binest,i,c("est","lo","hi"),list(bh,bh-1.96*bs,bh+1.96*bs))}}
  binest[,totest:=cumsum(est)]
  list(E=E,B=B,EWB=EWB,below_E=below_E,above_E=above_E,bunching_E=bunching_E,
       WB_E=WB_E,WB_nospill=WB_nospill,spill=spill,binest=binest,nobs=nobs(m))
}

inc <- analyze(1,"incumbent"); new <- analyze(0,"newentrant")
for(nm in c("incumbent","newentrant")){ r<-if(nm=="incumbent")inc else new
  cat(sprintf("\n%s: Db=%.3f(%.3f) Da=%.3f(%.3f) %%dEmp=%.3f(%.3f) %%dWage=%.3f(%.3f) spillover=%.3f(%.3f)\n",
    nm,r$below_E$est,r$below_E$se,r$above_E$est,r$above_E$se,
    r$bunching_E$est,r$bunching_E$se,r$WB_E$est,r$WB_E$se,r$spill$est,r$spill$se)) }
saveRDS(list(incumbent=inc,newentrant=new),"/workspace/output/replication/logs/figure4_results.rds")

for(nm in c("incumbent","newentrant")){ r<-if(nm=="incumbent")inc else new
  pdf(paste0(FIG,"Figure4",nm,"_firstyear.pdf"),width=7,height=5); par(mar=c(4.5,4.5,1,1))
  be<-r$binest
  bp<-barplot(be$est,names.arg=be$bin,col=if(nm=="incumbent")"darkseagreen"else"lightblue",
      border=NA,ylim=range(c(be$lo,be$hi,be$totest)),
      xlab="Wage bins in $ relative to new MW",ylab=paste(nm,"emp. count / pretreat total"))
  arrows(bp,be$lo,bp,be$hi,angle=90,code=3,length=0.03,col="steelblue")
  lines(bp,be$totest,col="red",lwd=2); abline(h=0,col="gray60")
  legend("topright",bty="n",sprintf("Da=%.3f Db=%.3f %%dW=%.3f",r$above_E$est,r$below_E$est,r$WB_E$est))
  dev.off() }
cat("Wrote Figure4incumbent_firstyear.pdf and Figure4newentrant_firstyear.pdf\n")
cat(sprintf("time %.1f min\n", as.numeric(difftime(Sys.time(),t0,units="mins"))))
