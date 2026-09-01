## ============================================================================
## Table 3 : sectoral heterogeneity (1992-2016 industry panel)
## port of Table3_for_QJE.do  (spec 1 / TWFE bunching estimator per sector)
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

sectors <- list(
  all=list(t="Overall"),        mstrad=list(t="Tradable"),
  msnontrad=list(t="Nontradable"), msother=list(t="Other"),
  mscon=list(t="Construction"), retail=list(t="Retail"),
  rest=list(t="Restaurant"),    manuf=list(t="Manufacturing"))
seccnt <- unlist(lapply(names(sectors), function(s) c(
  paste0("ind_",s,"_overallcount"), paste0("ind_",s,"_overallcountall"))))

need <- unique(c("statenum","quarterdate","wagebinstate","wagequarterdate","division",
  "quarterdatesq","year","wagebins","cleansample","countall","population","overallpop",
  "DMW_real","MW_real","fedincrease","overallcountgroup","MW_realM25",
  "F1MW_realM25","F2MW_realM25","F3MW_realM25","F4MW_realM25","treat_p0",
  seccnt, treatafter, treatbefore, window_vars, control_cat, controlf_cat))

cat("Reading industry panel ...\n")
dt <- as.data.table(read_dta(paste0(DATA,"state_panels_with3quant_ind_1992_2016.dta"),
                             col_select = tidyselect::all_of(need)))
qcew <- as.data.table(read_dta(paste0(DATA,"qcew_state_sector_counts_2016.dta")))
setnames(qcew,"statefips","statenum"); qcew[, quarterdate := yq(year,quarter)]
qsel <- c("statenum","quarterdate", paste0("ind_",names(sectors)))
qcew <- qcew[, ..qsel]
setnames(qcew, paste0("ind_",names(sectors)), paste0("emp_",names(sectors)))
dt <- merge(dt, qcew, by=c("statenum","quarterdate"))   # keep(3)
cat(sprintf("  rows=%d\n", nrow(dt)))

sq <- unique(dt[,.(statenum,quarterdate,fedincrease,overallcountgroup)])
for (k in 1:4){ tmp<-copy(sq); tmp[,quarterdate:=quarterdate-k]
  setnames(tmp,c("fedincrease","overallcountgroup"),c(paste0("F",k,"fed"),paste0("F",k,"grp")))
  dt<-merge(dt,tmp,by=c("statenum","quarterdate"),all.x=TRUE)}
condk<-function(fed,grp) st_ne(fed,1)&st_nm(fed)&st_gt(grp,0)&st_nm(grp)
denom<-1/(1+16/4); fac<-4*denom; B_year<-1992

fe_cat <- paste(sprintf("factor(%s)", c(control_cat, controlf_cat)), collapse=" + ")
fe1 <- paste("wagebinstate + wagequarterdate +", fe_cat)
rhs_after <- paste(c(treatafter, window_vars, treatbefore), collapse=" + ")

analyze <- function(sec) {
  cnt<-paste0("ind_",sec,"_overallcount"); allc_n<-paste0("ind_",sec,"_overallcountall")
  empc<-paste0("emp_",sec)
  W <- dt$overallpop; pop<-dt$population; allc<-dt[[allc_n]]; emp<-dt[[empc]]
  Ycount<-dt[[cnt]]; okc<-st_ne(dt$countall,0)&!is.na(dt$countall)
  Ycount <- Ycount*emp/dt$countall
  Ycountpc<-Ycount/pop
  Ycountpcall<-allc*(emp/dt$countall)/pop
  ord<-order(dt$statenum,dt$quarterdate,dt$wagebins)
  D<-data.table(sn=dt$statenum,qd=dt$quarterdate,pc=Ycountpc,
                wbpc=dt$wagebins*Ycount/(100*pop))[ord]
  D[,pcrsum:=cumsum(pc),by=.(sn,qd)]; D[,wbrsum:=cumsum(wbpc),by=.(sn,qd)]
  pcrsum<-numeric(nrow(dt)); pcrsum[ord]<-D$pcrsum
  wbrsum<-numeric(nrow(dt)); wbrsum[ord]<-D$wbrsum
  base<-st_ne(dt$fedincrease,1)&st_gt(dt$overallcountgroup,0)&dt$year>=B_year&st_eq(dt$cleansample,1)
  mwc<-wmean(dt$DMW_real[base],W[base])
  smw<-st_ne(dt$F1fed,1)&st_gt(dt$F1grp,0)&dt$year>=B_year&st_eq(dt$cleansample,1)
  mw<-wmean(dt$MW_real[smw],W[smw]); mwpc<-mwc/mw
  selE<-(condk(dt$F1fed,dt$F1grp)|condk(dt$F2fed,dt$F2grp)|condk(dt$F3fed,dt$F3grp)|condk(dt$F4fed,dt$F4grp))&
        dt$year>=B_year&st_eq(dt$cleansample,1)
  E<-wmean(Ycountpcall[selE],W[selE]); Cc<-1/(E*mwpc)
  selB<-((condk(dt$F1fed,dt$F1grp)&st_eq((dt$wagebins+25)/100,dt$F1MW_realM25))|
         (condk(dt$F2fed,dt$F2grp)&st_eq((dt$wagebins+25)/100,dt$F2MW_realM25))|
         (condk(dt$F3fed,dt$F3grp)&st_eq((dt$wagebins+25)/100,dt$F3MW_realM25))|
         (condk(dt$F4fed,dt$F4grp)&st_eq((dt$wagebins+25)/100,dt$F4MW_realM25)))&
        dt$year>=B_year&st_eq(dt$cleansample,1)
  B<-wmean(pcrsum[selB],W[selB])/E; EWB<-wmean(wbrsum[selB],W[selB])
  selWM<-st_eq(dt$treat_p0,1)&dt$year>=B_year&st_eq(dt$cleansample,1)
  wagemult<-wmean(dt$wagebins[selWM],W[selWM])/100

  DD<-cbind(dt,Y=Ycountpc,w=W)[dt$year>=B_year&st_eq(dt$cleansample,1)&!is.na(Ycountpc)&!is.na(W)&W>0]
  f<-as.formula(paste("Y ~",rhs_after,"|",fe1))
  m<-feols(f,data=DD,weights=~w,cluster=~statenum)
  b<-coef(m); V<-vcov(m); beta<-b[treatafter]; beta[is.na(beta)]<-0
  Vf<-matrix(0,length(treatafter),length(treatafter),dimnames=list(treatafter,treatafter))
  ex<-intersect(treatafter,colnames(V)); Vf[ex,ex]<-V[ex,ex]; dof<-length(unique(DD$statenum))-1
  sb<-as.numeric(treatafter%in%below_names); sa<-as.numeric(treatafter%in%above_names); sba<-sb+sa
  wbw<-setNames(numeric(length(treatafter)),treatafter)
  for(tt in times_after){for(j in 1:4)wbw[paste0(tt,"treat_m",j)]<-wagemult-j
                         for(j in 0:4)wbw[paste0(tt,"treat_p",j)]<-wagemult+j}
  below_E<-lincom_wt(sb*fac/E,beta,Vf,dof); above_E<-lincom_wt(sa*fac/E,beta,Vf,dof)
  bunching_E<-lincom_wt(sba*fac/E/B,beta,Vf,dof); bunchelas_E<-lincom_wt(sba*fac*Cc,beta,Vf,dof)
  f_bunch<-function(bb)sum(sba*bb)*fac/E/B; f_wbterm<-function(bb)sum(wbw*bb)*fac/EWB
  f_WBtot<-function(bb)(f_wbterm(bb)-f_bunch(bb))/(1+f_bunch(bb))
  f_labd<-function(bb)f_bunch(bb)/f_WBtot(bb)
  WB_E<-nlcom_fun(f_WBtot,beta,Vf,dof); labordem_E<-nlcom_fun(f_labd,beta,Vf,dof)
  list(mwpc=mwpc,E=E,B=B,EWB=EWB,wagemult=wagemult,below_E=below_E,above_E=above_E,
       bunching_E=bunching_E,bunchelas_E=bunchelas_E,WB_E=WB_E,labordem_E=labordem_E,nobs=nobs(m))
}

R<-list()
for(sec in names(sectors)){
  cat(sprintf("\n=== sector %s (%s) ===\n", sec, sectors[[sec]]$t))
  R[[sec]]<-analyze(sec); r<-R[[sec]]
  cat(sprintf("  Missing Db=%.3f(%.3f)  Excess Da=%.3f(%.3f)  own-wage elas=%.3f(%.3f)  %%dW=%.3f\n",
      r$below_E$est,r$below_E$se,r$above_E$est,r$above_E$se,
      r$labordem_E$est,r$labordem_E$se,r$WB_E$est))
}
saveRDS(R,"/workspace/output/replication/logs/table3_results.rds")

t3<-data.table(sector=sapply(names(sectors),function(s)sectors[[s]]$t),
  Missing_Db=sapply(names(sectors),function(s)sprintf("%.3f%s",R[[s]]$below_E$est,stars(R[[s]]$below_E$p))),
  Missing_se=sapply(names(sectors),function(s)sprintf("(%.3f)",R[[s]]$below_E$se)),
  Excess_Da=sapply(names(sectors),function(s)sprintf("%.3f%s",R[[s]]$above_E$est,stars(R[[s]]$above_E$p))),
  ownwage_elas=sapply(names(sectors),function(s)sprintf("%.3f%s",R[[s]]$labordem_E$est,stars(R[[s]]$labordem_E$p))),
  ownwage_se=sapply(names(sectors),function(s)sprintf("(%.3f)",R[[s]]$labordem_E$se)))
fwrite(t3,"/workspace/output/replication/logs/table3_sectors.csv")
cat("\n--- Table 3 (sectoral) ---\n"); print(t3)

## emit Table3.tex (missing/excess/own-wage rows per sector column)
cell<-function(x)sprintf("%.3f%s",x$est,stars(x$p)); sec<-function(x)sprintf("(%.3f)",x$se)
sn<-names(sectors)
row<-function(field,nm){v<-sapply(sn,function(s)cell(R[[s]][[field]]));e<-sapply(sn,function(s)sec(R[[s]][[field]]))
  c(paste(nm,"&",paste(v,collapse=" & "),"\\\\"),paste("  &",paste(e,collapse=" & "),"\\\\"))}
writeLines(c(paste("Sector &",paste(sapply(sn,function(s)sectors[[s]]$t),collapse=" & "),"\\\\ \\midrule"),
  row("below_E","Missing jobs below MW ($\\Delta b$)"),
  row("above_E","Excess jobs above MW ($\\Delta a$)"),
  row("WB_E","\\%$\\Delta$ affected wages"),
  row("bunching_E","\\%$\\Delta$ affected employment"),
  row("labordem_E","Emp. elasticity w.r.t. affected wage")),
  paste0(TAB,"Table3.tex"))
cat("Wrote",paste0(TAB,"Table3.tex"),"\n")
cat(sprintf("time %.1f min\n", as.numeric(difftime(Sys.time(),t0,units="mins"))))
