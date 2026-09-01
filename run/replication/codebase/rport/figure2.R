## ============================================================================
## Figure 2 : event-study of employment change by $ wage bin relative to new MW
## port of Figure2_for_QJE.do (core bins -4..+7; see notes on placebo tail)
## ============================================================================
source("/workspace/output/replication/codebase/rport/qje_lib.R")
options(width=160); t0 <- Sys.time()

## bins to plot: m4..m1, p0..p7  (all shipped as columns)
mbins <- c("m4","m3","m2","m1"); pbins <- paste0("p",0:7)
allbins <- c(mbins, pbins)
times_after <- c("", "L4", "L8", "L12", "L16")
treatvars <- as.vector(outer(times_after, allbins, function(a,b) paste0(a,"treat_",b)))
window_vars <- paste0("window_", allbins)               # window_m4..window_p7
times_before<- c("F12","F8")
treatbefore <- as.vector(outer(times_before, allbins, function(a,b) paste0(a,"treat_",b)))
control_cat <- c("postcont_m","precont_m","earlycont_m","postcont_p","precont_p","earlycont_p")
controlf_cat<- c("postcontf_m","precontf_m","earlycontf_m","postcontf_p","precontf_p","earlycontf_p")

need <- unique(c("statenum","quarterdate","wagebinstate","wagequarterdate","year","wagebins",
  "cleansample","overallcountpc","overallcountpcall","population",
  "fedincrease","overallcountgroup","F1MW_realM25","F2MW_realM25","F3MW_realM25","F4MW_realM25",
  "wtoverall1979","MW_realM25",
  treatvars, treatbefore, window_vars, control_cat, controlf_cat))

cat("Reading main panel ...\n")
dt <- as.data.table(read_dta(paste0(DATA,"state_panels_with3quant1979.dta"),
                             col_select = tidyselect::all_of(need)))
mult <- as.data.table(read_dta(paste0(DATA,"qcew_multiplier.dta"),
        col_select=tidyselect::all_of(c("statenum","quarterdate","multiplier"))))
dt <- merge(dt, mult, by=c("statenum","quarterdate"), all.x=TRUE)   # assert(3)
dt[, overallcountpc    := overallcountpc*multiplier]
dt[, overallcountpcall := overallcountpcall*multiplier]

## leads for E
sq <- unique(dt[,.(statenum,quarterdate,fedincrease,overallcountgroup)])
for (k in 1:4){ tmp<-copy(sq); tmp[,quarterdate:=quarterdate-k]
  setnames(tmp,c("fedincrease","overallcountgroup"),c(paste0("F",k,"fed"),paste0("F",k,"grp")))
  dt<-merge(dt,tmp,by=c("statenum","quarterdate"),all.x=TRUE)}
condk<-function(fed,grp) st_ne(fed,1)&st_nm(fed)&st_gt(grp,0)&st_nm(grp)
W<-dt$wtoverall1979
selE<-(condk(dt$F1fed,dt$F1grp)|condk(dt$F2fed,dt$F2grp)|condk(dt$F3fed,dt$F3grp)|condk(dt$F4fed,dt$F4grp))&
      dt$year>=1979&st_eq(dt$cleansample,1)
E<-wmean(dt$overallcountpcall[selE],W[selE])
cat(sprintf("E (multiplier-corrected) = %.5f\n", E))

## regression: all bins as treatment, spec 1 FE + controls
fe_cat<-paste(sprintf("factor(%s)",c(control_cat,controlf_cat)),collapse=" + ")
fe1<-paste("wagebinstate + wagequarterdate +",fe_cat)
rhs<-paste(c(treatvars, window_vars, treatbefore), collapse=" + ")
DD<-dt[year>=1979 & st_eq(cleansample,1) & !is.na(overallcountpc) & !is.na(wtoverall1979) & wtoverall1979>0]
f<-as.formula(paste("overallcountpc ~",rhs,"|",fe1))
cat("Running regression ...\n")
m<-feols(f, data=DD, weights=~wtoverall1979, cluster=~statenum)
b<-coef(m); V<-vcov(m); dof<-length(unique(DD$statenum))-1
denom<-1/(1+16/4)   # 0.2

## per-bin annualized estimate: (1/5)*sum_t coef(Lt.treat_binj)*4/E
binest<-data.table(bin=seq(-4,7), est=NA_real_, lo=NA_real_, hi=NA_real_)
for (i in seq_along(allbins)) {
  nm<-paste0(times_after,"treat_",allbins[i]); nm<-intersect(nm,names(b))
  w<-setNames(rep(denom*4/E,length(nm)),nm)
  bhat<-sum(w*b[nm]); bse<-sqrt(as.numeric(t(w)%*%V[nm,nm]%*%w))
  set(binest, i=i, j=c("est","lo","hi"), value=list(bhat, bhat-1.96*bse, bhat+1.96*bse))
}
binest[, totest:=cumsum(est)]
fwrite(binest, "/workspace/output/replication/logs/figure2_data.csv")
cat("\n--- Figure 2 bin estimates ($ rel. to new MW) ---\n"); print(binest)

pdf(paste0(FIG,"Figure2.pdf"), width=8, height=5); par(mar=c(4.5,4.5,1,1))
bp<-barplot(binest$est, names.arg=binest$bin, col="lightblue", border=NA,
            ylim=range(c(binest$lo,binest$hi,binest$totest)),
            xlab="Wage bins in $ relative to new MW", ylab="Employment estimate")
arrows(bp, binest$lo, bp, binest$hi, angle=90, code=3, length=0.03, col="steelblue")
lines(bp, binest$totest, col="red", lwd=2)
abline(h=0, col="gray60")
legend("topright", bty="n", c("Per-bin estimate","Cumulative sum"),
       fill=c("lightblue",NA), border=NA, lty=c(NA,1), col=c(NA,"red"), lwd=c(NA,2))
dev.off()
cat("Wrote", paste0(FIG,"Figure2.pdf"), "\n")
cat(sprintf("time %.1f min\n", as.numeric(difftime(Sys.time(),t0,units="mins"))))
