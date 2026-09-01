## ============================================================================
## Tables 2 & 4 (demographic groups) : port of Table2_for_QJE.do +
##   wage_estimate_base.do / wage_estimate_demog_groups.do (Table4 rows).
## Reuses the spec-1 (TWFE) bunching estimator per group.
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

need <- unique(c("statenum","quarterdate","wagebinstate","wagequarterdate","division",
  "quarterdatesq","year","wagebins","cleansample","count","countall","population",
  "DMW_real","MW_real","fedincrease","overallcountgroup","MW_realM25",
  "F1MW_realM25","F2MW_realM25","F3MW_realM25","F4MW_realM25","treat_p0",
  "teencount","teencountall","teenpop","wtteen1979",
  "HSLcount","HSLcountall","HSLpop","wtHSL1979",
  "HSDcount","HSDcountall","HSDpop","wtHSD1979",
  "gendercount","gendercountall","femalepop","wtfemale1979",
  "blackcount","blackcountall","hispaniccount","hispaniccountall","BHpop","wtBH1979",
  "wtoverall1979",
  treatafter, treatbefore, window_vars, control_cat, controlf_cat))

cat("Reading main panel ...\n")
dt <- as.data.table(read_dta(paste0(DATA,"state_panels_with3quant1979.dta"),
                             col_select = tidyselect::all_of(need)))
qcew <- as.data.table(read_dta(paste0(DATA,"qcew_state_overall_counts_2016.dta")))
setnames(qcew,"statefips","statenum"); qcew[, quarterdate := yq(year,quarter)]
dt <- merge(dt, qcew[,.(statenum,quarterdate,emp)], by=c("statenum","quarterdate"), all.x=TRUE)

# derived group counts
dt[, femalecount := count - gendercount]
dt[, femalecountall := countall - gendercountall]
dt[, BHcount := blackcount + hispaniccount]
dt[, BHcountall := blackcountall + hispaniccountall]

# leads of fedincrease / overallcountgroup
sq <- unique(dt[,.(statenum,quarterdate,fedincrease,overallcountgroup)])
for (k in 1:4) { tmp<-copy(sq); tmp[,quarterdate:=quarterdate-k]
  setnames(tmp,c("fedincrease","overallcountgroup"),c(paste0("F",k,"fed"),paste0("F",k,"grp")))
  dt <- merge(dt,tmp,by=c("statenum","quarterdate"),all.x=TRUE) }

condk <- function(fed,grp) st_ne(fed,1) & st_nm(fed) & st_gt(grp,0) & st_nm(grp)
denom <- 1/(1+16/4); fac <- 4*denom

# group specification: name -> (count, countall, pop, weight)
groups <- list(
  overall=list(cnt="count",     all="countall",     pop="population",wt="wtoverall1979"),
  HSD    =list(cnt="HSDcount",  all="HSDcountall",  pop="HSDpop",   wt="wtHSD1979"),
  HSL    =list(cnt="HSLcount",  all="HSLcountall",  pop="HSLpop",   wt="wtHSL1979"),
  teen   =list(cnt="teencount", all="teencountall", pop="teenpop",  wt="wtteen1979"),
  female =list(cnt="femalecount",all="femalecountall",pop="femalepop",wt="wtfemale1979"),
  BH     =list(cnt="BHcount",   all="BHcountall",   pop="BHpop",    wt="wtBH1979"))

fe_cat <- paste(sprintf("factor(%s)", c(control_cat, controlf_cat)), collapse=" + ")
fe1 <- paste("wagebinstate + wagequarterdate +", fe_cat)
rhs_after <- paste(c(treatafter, window_vars, treatbefore), collapse=" + ")

analyze <- function(g) {
  cnt<-g$cnt; W <- dt[[g$wt]]; pop<-dt[[g$pop]]; allc<-dt[[g$all]]
  emp<-dt$emp
  # QCEW correction + per-capita
  Ycount <- dt[[cnt]]; ok <- st_ne(emp,0) & !is.na(emp)
  Ycount[ok] <- Ycount[ok]*emp[ok]/dt$countall[ok]
  Ycountpc <- Ycount/pop
  Ycountpcall <- rep(NA_real_, nrow(dt))
  Ycountpcall[ok] <- allc[ok]*(emp[ok]/dt$countall[ok])/pop[ok]
  # cumulative sums (ascending wagebins within state-quarter)
  ord <- order(dt$statenum, dt$quarterdate, dt$wagebins)
  D <- data.table(sn=dt$statenum, qd=dt$quarterdate, wb=dt$wagebins,
                  pc=Ycountpc, wbpc=dt$wagebins*Ycount/(100*pop))[ord]
  D[, pcrsum := cumsum(pc), by=.(sn,qd)]
  D[, wbrsum := cumsum(wbpc), by=.(sn,qd)]
  pcrsum <- numeric(nrow(dt)); pcrsum[ord] <- D$pcrsum
  wbrsum <- numeric(nrow(dt)); wbrsum[ord] <- D$wbrsum
  # scalars
  base <- st_ne(dt$fedincrease,1)&st_gt(dt$overallcountgroup,0)&dt$year>=1979&st_eq(dt$cleansample,1)
  mwc <- wmean(dt$DMW_real[base],W[base])
  smw <- st_ne(dt$F1fed,1)&st_gt(dt$F1grp,0)&dt$year>=1979&st_eq(dt$cleansample,1)
  mw  <- wmean(dt$MW_real[smw],W[smw]); mwpc<-mwc/mw
  selE <- (condk(dt$F1fed,dt$F1grp)|condk(dt$F2fed,dt$F2grp)|condk(dt$F3fed,dt$F3grp)|condk(dt$F4fed,dt$F4grp)) &
          dt$year>=1979 & st_eq(dt$cleansample,1)
  E <- wmean(Ycountpcall[selE],W[selE]); Cc<-1/(E*mwpc)
  selB <- ((condk(dt$F1fed,dt$F1grp)&st_eq((dt$wagebins+25)/100,dt$F1MW_realM25))|
           (condk(dt$F2fed,dt$F2grp)&st_eq((dt$wagebins+25)/100,dt$F2MW_realM25))|
           (condk(dt$F3fed,dt$F3grp)&st_eq((dt$wagebins+25)/100,dt$F3MW_realM25))|
           (condk(dt$F4fed,dt$F4grp)&st_eq((dt$wagebins+25)/100,dt$F4MW_realM25))) &
          dt$year>=1979 & st_eq(dt$cleansample,1)
  B   <- wmean(pcrsum[selB],W[selB])/E
  EWB <- wmean(wbrsum[selB],W[selB])
  selWM <- st_eq(dt$treat_p0,1)&dt$year>=1979&st_eq(dt$cleansample,1)
  wagemult <- wmean(dt$wagebins[selWM],W[selWM])/100

  # regression (spec 1) on this outcome
  dd <- data.table(Y=Ycountpc, w=W)[, keep:=(dt$year>=1979 & st_eq(dt$cleansample,1) &
        !is.na(Ycountpc) & !is.na(W) & W>0)]
  DD <- cbind(dt, Y=Ycountpc, w=W)[dt$year>=1979 & st_eq(dt$cleansample,1) &
        !is.na(Ycountpc) & !is.na(W) & W>0]
  f <- as.formula(paste("Y ~", rhs_after, "|", fe1))
  m <- feols(f, data=DD, weights=~w, cluster=~statenum)
  b<-coef(m); V<-vcov(m)
  beta<-b[treatafter]; beta[is.na(beta)]<-0
  Vf<-matrix(0,length(treatafter),length(treatafter),dimnames=list(treatafter,treatafter))
  ex<-intersect(treatafter,colnames(V)); Vf[ex,ex]<-V[ex,ex]
  dof <- length(unique(DD$statenum))-1

  sb<-as.numeric(treatafter%in%below_names); sa<-as.numeric(treatafter%in%above_names); sba<-sb+sa
  wbw<-setNames(numeric(length(treatafter)),treatafter)
  for(tt in times_after){for(j in 1:4)wbw[paste0(tt,"treat_m",j)]<-wagemult-j
                         for(j in 0:4)wbw[paste0(tt,"treat_p",j)]<-wagemult+j}
  # linear combos
  below_E <- lincom_wt(sb*fac/E, beta,Vf,dof)
  above_E <- lincom_wt(sa*fac/E, beta,Vf,dof)
  bunching_E <- lincom_wt(sba*fac/E/B, beta,Vf,dof)
  bunchelas_E<- lincom_wt(sba*fac*Cc, beta,Vf,dof)
  # WB total (nonlinear), no-spillover (linear), spillover, labordem
  f_bunch <- function(bb) sum(sba*bb)*fac/E/B
  f_wbterm<- function(bb) sum(wbw*bb)*fac/EWB
  f_WBtot <- function(bb) (f_wbterm(bb)-f_bunch(bb))/(1+f_bunch(bb))
  # no-spillover: aboveWB_fullY = -sum_j j*b[treat_m_j]; WB=*fac/EWB
  wbY <- setNames(numeric(length(treatafter)),treatafter)
  for(tt in times_after) for(j in 1:4) wbY[paste0(tt,"treat_m",j)] <- -j
  WB_nospill <- lincom_wt(wbY*fac/EWB, beta,Vf,dof)
  f_nospill<-function(bb) sum(wbY*bb)*fac/EWB
  f_spill  <-function(bb) 1 - f_nospill(bb)/f_WBtot(bb)
  f_labd   <-function(bb) f_bunch(bb)/f_WBtot(bb)
  WB_E <- nlcom_fun(f_WBtot, beta,Vf,dof)
  spill<- nlcom_fun(f_spill, beta,Vf,dof)
  labordem_E <- nlcom_fun(f_labd, beta,Vf,dof)

  list(mwpc=mwpc,E=E,B=B,EWB=EWB,wagemult=wagemult,
       below_E=below_E,above_E=above_E,bunching_E=bunching_E,bunchelas_E=bunchelas_E,
       WB_E=WB_E,WB_nospill=WB_nospill,spill=spill,labordem_E=labordem_E,nobs=nobs(m))
}

R <- list()
for (nm in names(groups)) {
  cat(sprintf("\n=== group %s ===\n", nm))
  R[[nm]] <- analyze(groups[[nm]])
  r<-R[[nm]]
  cat(sprintf("  Db(below_E)=%.3f(%.3f)  labordem_E=%.3f(%.3f)\n",
      r$below_E$est,r$below_E$se,r$labordem_E$est,r$labordem_E$se))
  cat(sprintf("  WB_E(tot)=%.3f(%.3f)  WB_nospill=%.3f(%.3f)  spillover=%.3f(%.3f)\n",
      r$WB_E$est,r$WB_E$se,r$WB_nospill$est,r$WB_nospill$se,r$spill$est,r$spill$se))
}
saveRDS(R,"/workspace/output/replication/logs/groups_results.rds")

## ---- Table 2 : Db and own-wage elasticity per group (demog part) ----
g2 <- c("HSD","HSL","teen","female","BH")
t2 <- data.table(group=g2,
  Delta_b=sapply(g2,function(g)sprintf("%.3f%s",R[[g]]$below_E$est,stars(R[[g]]$below_E$p))),
  Delta_b_se=sapply(g2,function(g)sprintf("(%.3f)",R[[g]]$below_E$se)),
  ownwage_elas=sapply(g2,function(g)sprintf("%.3f%s",R[[g]]$labordem_E$est,stars(R[[g]]$labordem_E$p))),
  ownwage_se=sapply(g2,function(g)sprintf("(%.3f)",R[[g]]$labordem_E$se)))
fwrite(t2,"/workspace/output/replication/logs/table2_demog.csv")
cat("\n--- Table 2 (demographic groups) ---\n"); print(t2)

## ---- Table 4 : total %dW, no-spillover %dW, spillover share ----
g4 <- c("overall","HSD","teen","HSL","female","BH")
t4 <- data.table(group=g4,
  pct_dW=sapply(g4,function(g)sprintf("%.3f%s",R[[g]]$WB_E$est,stars(R[[g]]$WB_E$p))),
  pct_dW_se=sapply(g4,function(g)sprintf("(%.3f)",R[[g]]$WB_E$se)),
  pct_dW_nospill=sapply(g4,function(g)sprintf("%.3f%s",R[[g]]$WB_nospill$est,stars(R[[g]]$WB_nospill$p))),
  spillover=sapply(g4,function(g)sprintf("%.3f%s",R[[g]]$spill$est,stars(R[[g]]$spill$p))))
fwrite(t4,"/workspace/output/replication/logs/table4_groups.csv")
cat("\n--- Table 4 (groups; overall + demographic) ---\n"); print(t4)
cat(sprintf("\ntime %.1f min\n", as.numeric(difftime(Sys.time(),t0,units="mins"))))
