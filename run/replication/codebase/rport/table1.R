## ============================================================================
## Table 1 (and Figure 3) : port of Table1_for_QJE.do
## Cengiz, Dube, Lindner, Zipperer (2019 QJE)
## ============================================================================
source("/workspace/output/replication/codebase/rport/qje_lib.R")
options(width = 160)
t0 <- Sys.time()

## ---------------------------------------------------------------------------
## 1. Column lists (event time x wage bin structure)
## ---------------------------------------------------------------------------
bins_after <- c("m4","m3","m2","m1","p0","p1","p2","p3","p4")   # wmin=4,wmax=4
times_after <- c("", "L4", "L8", "L12", "L16")                  # k=0,4,8,12,16
treatafter <- as.vector(outer(times_after, bins_after,
                              function(a,b) paste0(a,"treat_",b)))
times_before <- c("F12","F8")                                   # k=-12,-8
treatbefore <- as.vector(outer(times_before, bins_after,
                               function(a,b) paste0(a,"treat_",b)))
window_vars  <- paste0("window_", bins_after)                    # window_m4..p4
control_cat  <- c("postcont_m","precont_m","earlycont_m",
                  "postcont_p","precont_p","earlycont_p")        # categorical
controlf_cat <- c("postcontf_m","precontf_m","earlycontf_m",
                  "postcontf_p","precontf_p","earlycontf_p")     # categorical

id_vars <- c("statenum","quarterdate","wagebinstate","wagequarterdate",
             "division","quarterdatesq","year","wagebins","cleansample")
scal_vars <- c("count","countall","population","overallcountpcall",
               "wtoverall1979","DMW_real","MW_real","fedincrease",
               "overallcountgroup","MW_realM25",
               "F1MW_realM25","F2MW_realM25","F3MW_realM25","F4MW_realM25",
               "treat_p0")

need <- unique(c(id_vars, scal_vars, treatafter, treatbefore,
                 window_vars, control_cat, controlf_cat))

cat("Reading main panel (needed columns) ...\n")
dt <- as.data.table(read_dta(paste0(DATA,"state_panels_with3quant1979.dta"),
                             col_select = tidyselect::all_of(need)))
cat(sprintf("  rows=%d cols=%d  (%.1fs)\n", nrow(dt), ncol(dt),
            as.numeric(difftime(Sys.time(),t0,units="secs"))))

## ---------------------------------------------------------------------------
## 2. QCEW merge + correction  (Table1_for_QJE.do lines 42-56)
## ---------------------------------------------------------------------------
qcew <- as.data.table(read_dta(paste0(DATA,"qcew_state_overall_counts_2016.dta")))
setnames(qcew, "statefips", "statenum")
qcew[, quarterdate := yq(year, quarter)]
qcew <- qcew[, .(statenum, quarterdate, emp)]
dt <- merge(dt, qcew, by = c("statenum","quarterdate"), all.x = TRUE)
cat(sprintf("  QCEW merged: unmatched emp = %d\n", sum(is.na(dt$emp))))

# replace count = count*emp/countall if emp!=0 ; overallcountpc=count/population
dt[st_ne(emp,0) & !is.na(emp), count := count * emp / countall]
dt[, overallcountpc := count / population]
dt[st_ne(emp,0) & !is.na(emp), overallcountpcall := emp / population]

## ---------------------------------------------------------------------------
## 3. Leads of fedincrease / overallcountgroup (F1..F4) via state-quarter table
##    (Stata F. operator on xtset ... quarterdate)
## ---------------------------------------------------------------------------
sq <- unique(dt[, .(statenum, quarterdate, fedincrease, overallcountgroup)])
for (k in 1:4) {
  tmp <- copy(sq)
  tmp[, quarterdate := quarterdate - k]        # value at t+k keyed to t
  setnames(tmp, c("fedincrease","overallcountgroup"),
           c(paste0("F",k,"fed"), paste0("F",k,"grp")))
  dt <- merge(dt, tmp, by = c("statenum","quarterdate"), all.x = TRUE)
}

## ---------------------------------------------------------------------------
## 4. Cumulative (ascending wagebins) sums within state-quarter
##    overallcountpcrsum, overallWBpcrsumFH  (lines 143-154)
## ---------------------------------------------------------------------------
setorder(dt, statenum, quarterdate, wagebins)
dt[, overallWBpcFH := wagebins * count / (100 * population)]
dt[, overallcountpcrsum := cumsum(overallcountpc), by = .(statenum, quarterdate)]
dt[, overallWBpcrsumFH  := cumsum(overallWBpcFH),  by = .(statenum, quarterdate)]

## ---------------------------------------------------------------------------
## 5. Scalars: mwpc (E is epop), B, EWB, wagemult, C   (lines 164-234)
## ---------------------------------------------------------------------------
W <- dt$wtoverall1979
base <- st_ne(dt$fedincrease,1) & st_gt(dt$overallcountgroup,0) &
        dt$year>=1979 & st_eq(dt$cleansample,1)
mwc <- wmean(dt$DMW_real[base], W[base])

sel_mw <- st_ne(dt$F1fed,1) & st_gt(dt$F1grp,0) & dt$year>=1979 & st_eq(dt$cleansample,1)
mw <- wmean(dt$MW_real[sel_mw], W[sel_mw])
mwpc <- mwc / mw

# E = epop : F1..F4 all non-missing & valid
condk <- function(fed, grp) st_ne(fed,1) & st_nm(fed) & st_gt(grp,0) & st_nm(grp)
selE <- (condk(dt$F1fed,dt$F1grp) | condk(dt$F2fed,dt$F2grp) |
         condk(dt$F3fed,dt$F3grp) | condk(dt$F4fed,dt$F4grp)) &
        dt$year>=1979 & st_eq(dt$cleansample,1)
E <- wmean(dt$overallcountpcall[selE], W[selE])
Cc <- 1/(E*mwpc)

# B (below share) : bin where (wagebins+25)/100 == FkMW_realM25
selB <- ((condk(dt$F1fed,dt$F1grp) & st_eq((dt$wagebins+25)/100, dt$F1MW_realM25)) |
         (condk(dt$F2fed,dt$F2grp) & st_eq((dt$wagebins+25)/100, dt$F2MW_realM25)) |
         (condk(dt$F3fed,dt$F3grp) & st_eq((dt$wagebins+25)/100, dt$F3MW_realM25)) |
         (condk(dt$F4fed,dt$F4grp) & st_eq((dt$wagebins+25)/100, dt$F4MW_realM25))) &
        dt$year>=1979 & st_eq(dt$cleansample,1)
B <- wmean(dt$overallcountpcrsum[selB], W[selB]) / E

# EWB (wage bill below share) : same selection
EWB <- wmean(dt$overallWBpcrsumFH[selB], W[selB])
CWB <- 1/(EWB*mwpc)

# wagemult : mean wagebins where treat_p0==1
selWM <- st_eq(dt$treat_p0,1) & dt$year>=1979 & st_eq(dt$cleansample,1)
wagemult <- wmean(dt$wagebins[selWM], W[selWM]) / 100

cat(sprintf("\nScalars: mwpc=%.4f  E=%.5f  B=%.4f  EWB=%.5f  wagemult=%.4f  C=%.4f\n",
            mwpc, E, B, EWB, wagemult, Cc))

denom <- 1/(1 + 16/4)          # = 0.2
fac   <- 4 * denom             # = 0.8

## ---------------------------------------------------------------------------
## 6. Combination weight vectors over the 45 treatafter coefficients
## ---------------------------------------------------------------------------
below_names <- as.vector(outer(times_after, c("m1","m2","m3","m4"),
                               function(a,b) paste0(a,"treat_",b)))
above_names <- as.vector(outer(times_after, c("p0","p1","p2","p3","p4"),
                               function(a,b) paste0(a,"treat_",b)))
# WB weights: treat_m_j -> (wagemult - j); treat_p_j -> (wagemult + j)
wb_weight <- setNames(numeric(length(treatafter)), treatafter)
for (tt in times_after) {
  for (j in 1:4) wb_weight[paste0(tt,"treat_m",j)] <- (wagemult - j)
  for (j in 0:4) wb_weight[paste0(tt,"treat_p",j)] <- (wagemult + j)
}

## ---------------------------------------------------------------------------
## 7. FE specifications (fixest) + estimation sample
## ---------------------------------------------------------------------------
fe_cat <- paste(sprintf("factor(%s)", c(control_cat, controlf_cat)), collapse=" + ")
fe_spec <- list(
  "1"  = paste("wagebinstate + wagequarterdate", "+", fe_cat),                         # TWFE
  "4"  = paste("wagebinstate[quarterdate] + wagequarterdate", "+", fe_cat),            # ST
  "5"  = paste("wagebinstate + wagequarterdate^division", "+", fe_cat),                # DP
  "6"  = paste("wagebinstate[quarterdate] + wagequarterdate^division", "+", fe_cat),   # ST_DP
  "10" = paste("wagebinstate[quarterdate, quarterdatesq] + wagequarterdate","+",fe_cat), # STQ
  "11" = paste("wagebinstate[quarterdate, quarterdatesq] + wagequarterdate^division","+",fe_cat) # STQ_DP
)
spec_label <- c("1"="TWFE","4"="ST","5"="DP","6"="ST_DP","10"="STQ","11"="STQ_DP")

rhs_after  <- paste(c(treatafter, window_vars, treatbefore), collapse=" + ")
rhs_before <- paste(c(treatbefore, window_vars, treatafter), collapse=" + ")

# estimation subset
dd <- dt[year>=1979 & st_eq(cleansample,1) & !is.na(overallcountpc) &
         !is.na(wtoverall1979) & wtoverall1979>0]
cat(sprintf("Estimation rows: %d ; events (fedincrease!=1 & grp>0 & wagebins==300): ", nrow(dd)))
numevent <- dd[st_ne(fedincrease,1) & st_gt(overallcountgroup,0) & wagebins==300, .N]
cat(numevent, "\n")
Gclust <- length(unique(dd$statenum)); dof <- Gclust - 1

## ---------------------------------------------------------------------------
## 8. Run the 6 "after" regressions and compute all scalars
## ---------------------------------------------------------------------------
res <- list()
for (s in c("1","4","5","6","10","11")) {
  cat(sprintf("\n=== spec %s (%s) ===\n", s, spec_label[s]))
  f <- as.formula(paste("overallcountpc ~", rhs_after, "|", fe_spec[[s]]))
  m <- feols(f, data = dd, weights = ~wtoverall1979, cluster = ~statenum)
  b <- coef(m); V <- vcov(m)
  keep <- intersect(treatafter, names(b))
  if (length(keep) < length(treatafter))
    cat("  WARN dropped coefs:", setdiff(treatafter, names(b)), "\n")
  beta <- b[treatafter]; beta[is.na(beta)] <- 0
  Vf <- matrix(0, length(treatafter), length(treatafter),
               dimnames=list(treatafter,treatafter))
  ex <- intersect(treatafter, colnames(V))
  Vf[ex,ex] <- V[ex,ex]

  sel_below <- as.numeric(treatafter %in% below_names)
  sel_above <- as.numeric(treatafter %in% above_names)
  sel_ba    <- sel_below + sel_above
  wbw       <- wb_weight[treatafter]

  # linear combos
  below_E <- lincom_wt(sel_below * fac/E,          beta, Vf, dof)
  above_E <- lincom_wt(sel_above * fac/E,          beta, Vf, dof)
  bunching_E <- lincom_wt(sel_ba * fac/E/B,        beta, Vf, dof)
  bunchelas_E<- lincom_wt(sel_ba * fac*Cc,         beta, Vf, dof)

  # nonlinear combos (WB_E, labordem_E)
  f_bunch <- function(bb) sum(sel_ba*bb) * fac/E/B
  f_wbterm<- function(bb) sum(wbw*bb)    * fac/EWB
  f_WB    <- function(bb) (f_wbterm(bb) - f_bunch(bb))/(1 + f_bunch(bb))
  f_labd  <- function(bb) f_bunch(bb) / f_WB(bb)
  WB_E     <- nlcom_fun(f_WB,   beta, Vf, dof)
  labordem_E <- nlcom_fun(f_labd, beta, Vf, dof)

  res[[s]] <- list(label=spec_label[s], m=m, beta=beta, V=Vf,
                   below_E=below_E, above_E=above_E, bunching_E=bunching_E,
                   bunchelas_E=bunchelas_E, WB_E=WB_E, labordem_E=labordem_E,
                   nobs=nobs(m))
  cat(sprintf("  below_E(Db)=%.3f(%.3f)  above_E(Da)=%.3f(%.3f)\n",
              below_E$est,below_E$se,above_E$est,above_E$se))
  cat(sprintf("  bunching_E(%%dEmp)=%.3f(%.3f)  WB_E(%%dWage)=%.3f(%.3f)\n",
              bunching_E$est,bunching_E$se,WB_E$est,WB_E$se))
  cat(sprintf("  bunchelas_E(elas wrt MW)=%.3f(%.3f)  labordem_E(elas wrt wage)=%.3f(%.3f)\n",
              bunchelas_E$est,bunchelas_E$se,labordem_E$est,labordem_E$se))
}

saveRDS(list(res=res, scalars=list(mwpc=mwpc,E=E,B=B,EWB=EWB,wagemult=wagemult,
             Cc=Cc,denom=denom,fac=fac,numevent=numevent,dof=dof),
             below_names=below_names, above_names=above_names,
             treatafter=treatafter, wb_weight=wb_weight),
        "/workspace/output/replication/logs/table1_results.rds")

## ---------------------------------------------------------------------------
## 9. Emit Table1.tex
## ---------------------------------------------------------------------------
cell <- function(x) paste0(fmt3(x$est), stars(x$p))
se_c <- function(x) paste0("(", fmt3(x$se), ")")
specs <- c("1","4","5","6","10","11")
lab <- sapply(specs, function(s) spec_label[s])
row_bd <- function(field, name) {
  vals <- sapply(specs, function(s) cell(res[[s]][[field]]))
  ses  <- sapply(specs, function(s) se_c(res[[s]][[field]]))
  c(paste(name, "&", paste(vals, collapse=" & "), "\\\\"),
    paste("      &", paste(ses,  collapse=" & "), "\\\\"))
}
lines <- c(
  paste("Specification &", paste(lab, collapse=" & "), "\\\\ \\midrule"),
  row_bd("below_E","Missing jobs below new MW ($\\Delta b$)"),
  row_bd("above_E","Excess jobs above new MW ($\\Delta a$)"),
  row_bd("WB_E","\\%$\\Delta$ affected wages"),
  row_bd("bunching_E","\\%$\\Delta$ affected employment"),
  row_bd("bunchelas_E","Employment elasticity w.r.t. MW"),
  row_bd("labordem_E","Emp. elasticity w.r.t. affected wage"),
  paste("$\\bar b_{-1}$ &", paste(rep(fmt3(B), length(specs)), collapse=" & "), "\\\\"),
  paste("\\%$\\Delta$ MW &", paste(rep(fmt3(mwpc), length(specs)), collapse=" & "), "\\\\"),
  paste("\\# Events &", paste(rep(numevent, length(specs)), collapse=" & "), "\\\\"),
  paste("N &", paste(sapply(specs,function(s) res[[s]]$nobs), collapse=" & "), "\\\\")
)
writeLines(lines, paste0(TAB, "Table1.tex"))
cat("\nWrote", paste0(TAB,"Table1.tex"),"\n")

## ---------------------------------------------------------------------------
## 10. Figure 3 : missing/excess jobs over event time  (spec 1)
##     before-regression -> event times -12,-8 ; after -> 0..16
## ---------------------------------------------------------------------------
cat("\nFigure 3: running before-regression (spec 1) ...\n")
fb <- as.formula(paste("overallcountpc ~", rhs_before, "|", fe_spec[["1"]]))
mb <- feols(fb, data = dd, weights = ~wtoverall1979, cluster = ~statenum)
bb <- coef(mb); Vb <- vcov(mb)

# sum of coefs (above=treat_p0..p4, below=treat_m1..m4) at a given prefix, scaled by 4/E
mass <- function(coefs, vc, prefix, kind) {
  bins <- if (kind=="above") paste0("p",0:4) else paste0("m",1:4)
  nm <- paste0(prefix, "treat_", bins)
  nm <- intersect(nm, names(coefs))
  w <- setNames(rep(1,length(nm)), nm)
  est <- sum(coefs[nm]) * 4 / E
  se  <- sqrt(as.numeric(t(w) %*% vc[nm,nm] %*% w)) * 4 / E
  c(est=est, lo=est-1.96*se, hi=est+1.96*se)
}
ev <- data.table(time=integer(), estA=double(),loA=double(),hiA=double(),
                 estB=double(),loB=double(),hiB=double())
# before: t=-12,-8 (prefix F12,F8) ; t=-4 reference (0)
for (pr in list(c(-12,"F12"), c(-8,"F8"))) {
  t <- as.integer(pr[1]); prefix <- pr[2]
  a <- mass(bb,Vb,prefix,"above"); b <- mass(bb,Vb,prefix,"below")
  ev <- rbind(ev, data.table(time=t,estA=a["est"],loA=a["lo"],hiA=a["hi"],
                             estB=b["est"],loB=b["lo"],hiB=b["hi"]))
}
ev <- rbind(ev, data.table(time=-4,estA=0,loA=0,hiA=0,estB=0,loB=0,hiB=0))
# after: t=0,4,8,12,16 from after regression (res[[1]]$m)
ba <- coef(res[["1"]]$m); Va <- vcov(res[["1"]]$m)
for (pr in list(c(0,""),c(4,"L4"),c(8,"L8"),c(12,"L12"),c(16,"L16"))) {
  t <- as.integer(pr[1]); prefix <- pr[2]
  a <- mass(ba,Va,prefix,"above"); b <- mass(ba,Va,prefix,"below")
  ev <- rbind(ev, data.table(time=t,estA=a["est"],loA=a["lo"],hiA=a["hi"],
                             estB=b["est"],loB=b["lo"],hiB=b["hi"]))
}
setorder(ev, time)
fwrite(ev, "/workspace/output/replication/logs/figure3_data.csv")

pdf(paste0(FIG,"Figure3.pdf"), width=7, height=5)
par(mar=c(4,4,1,1))
yr <- range(c(ev$loA,ev$hiA,ev$loB,ev$hiB))
plot(ev$time, ev$estA, type="o", pch=19, col="steelblue", lwd=2, ylim=yr,
     xlab="Annualized event time (quarters)", ylab="Employment change (per capita, /E)",
     xaxt="n")
axis(1, at=seq(-12,16,4), labels=c("-3","-2","-1","0","1","2","3","4"))
arrows(ev$time, ev$loA, ev$time, ev$hiA, angle=90, code=3, length=0.03, col="steelblue")
lines(ev$time, ev$estB, type="o", pch=17, col="red", lwd=2)
arrows(ev$time, ev$loB, ev$time, ev$hiB, angle=90, code=3, length=0.03, col="red")
abline(h=0, col="gray70"); abline(v=0, lty=2)
legend("topleft", c("Excess (above new MW)","Missing (below new MW)"),
       col=c("steelblue","red"), pch=c(19,17), lwd=2, bty="n")
dev.off()
cat("Wrote", paste0(FIG,"Figure3.pdf"),"\n")

cat(sprintf("\nTOTAL time: %.1f min\n", as.numeric(difftime(Sys.time(),t0,units="mins"))))
