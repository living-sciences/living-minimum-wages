## ============================================================================
## Figure 6 / Figure A11 : TWFE-logMW employment elasticity decomposition
## port of Figure6_for_QJE.do
## ============================================================================
source("/workspace/output/replication/codebase/rport/qje_lib.R")
options(width=160); t0 <- Sys.time()

## ---- 1. annual state MW data with 4 leads/lags of log mean MW ----
vz <- as.data.table(read_dta(paste0(DATA,"VZmw_quarterly_lagsleads_1979_2016.dta"),
        col_select = tidyselect::all_of(c("statenum","quarterdate","logmw"))))
vz[, mw := exp(logmw)]
vz[, year := 1960 + quarterdate %/% 4]        # year(dofq(quarterdate))
mwa <- vz[, .(mw = mean(mw)), by = .(statenum, year)]
setorder(mwa, statenum, year)
mwa[, logmw := log(mw)]
for (k in 1:4) {
  mwa[, paste0("L",k,"logmw") := log(shift(mw, k, type="lag")),  by=statenum]
  mwa[, paste0("F",k,"logmw") := log(shift(mw, k, type="lead")), by=statenum]
}
mwa[, L0logmw := logmw]
mwa <- mwa[year>=1979 & year<=2015]

## ---- 2. employment panel: balanced counts, QCEW multiplier ----
sp <- as.data.table(read_dta(paste0(DATA,"state_panels_cents_balanced_add_QJE.dta"),
        col_select = tidyselect::all_of(c("statenum","quarterdate","year",
                                          "wagebins","count","countall","population"))))
mult <- as.data.table(read_dta(paste0(DATA,"qcew_multiplier.dta"),
        col_select = tidyselect::all_of(c("statenum","quarterdate","multiplier"))))
sp <- merge(sp, mult, by=c("statenum","quarterdate"), all.x=TRUE)
sp[, count    := count    * multiplier]
sp[, countall := countall * multiplier]
sp[, wdollar  := floor(wagebins/100)]         # dollar bins

## sum count within statenum x quarterdate x dollar-bin
csum <- sp[, .(count = sum(count)), by=.(statenum, quarterdate, year, wdollar)]
## state-quarter countall / population (constant across bins -> first)
sq <- unique(sp[, .(statenum, quarterdate, year, countall, population)])

## annual means
csum_a <- dcast(csum, statenum + year ~ wdollar, value.var="count",
                fun.aggregate=mean, fill=0)                    # count per dollar bin, annual mean
sq_a <- sq[, .(countall=mean(countall), totalpopulation=mean(population)),
           by=.(statenum, year)]
dat <- merge(csum_a, sq_a, by=c("statenum","year"))
dat <- merge(dat, mwa, by=c("statenum","year"))
dat[, epop := countall/totalpopulation]
dat[, avetotalpopulation := mean(totalpopulation), by=statenum]
dat[, cleansample := ifelse(year>=1994 & year<=1995, 0, 1)]
for (k in 1:30) {
  cn <- as.character(k)
  if (!cn %in% names(dat)) dat[, (cn):=0]
  dat[, paste0("percap",k) := get(cn)/totalpopulation]
}

## ---- 3. regressions ----
treat <- c("F2logmw","F1logmw","logmw","L1logmw","L2logmw","L3logmw","L4logmw")
lincom_w <- c(logmw=1, L1logmw=0.8, L2logmw=0.6, L3logmw=0.4, L4logmw=0.2)  # lincom12
run_elas <- function(dd, yvar, denom) {
  f <- as.formula(paste(yvar, "~", paste(treat, collapse="+"), "| statenum + year"))
  m <- feols(f, data=dd, weights=~avetotalpopulation, cluster=~statenum)
  b <- coef(m); V <- vcov(m)
  nm <- names(lincom_w)
  w  <- setNames(rep(0,length(b)), names(b)); w[nm] <- lincom_w[nm]
  est <- sum(w*b)/denom
  se  <- sqrt(as.numeric(t(w)%*%V%*%w))/denom
  dof <- length(unique(dd$statenum)) - 1
  list(est=est, se=se, lo=est-qt(.975,dof)*se, hi=est+qt(.975,dof)*se)
}

dd <- dat[year>=1979 & cleansample==1]
denom <- wmean(dd$epop, dd$avetotalpopulation)
cat(sprintf("denominator (mean epop) = %.5f\n", denom))

bins <- data.table(wagebin=1:30, est=NA_real_, lo=NA_real_, hi=NA_real_)
for (k in 1:30) {
  r <- run_elas(dd, paste0("percap",k), denom)
  bins[k, c("est","lo","hi") := .(r$est, r$lo, r$hi)]
}
agg <- run_elas(dd, "epop", denom)
cat(sprintf("\nAGGREGATE employment elasticity w.r.t. MW = %.3f (%.3f)  [95%% CI %.3f, %.3f]\n",
            agg$est, agg$se, agg$lo, agg$hi))
bins[, totest := cumsum(est)]
fwrite(bins, "/workspace/output/replication/logs/figure6_bins.csv")
saveRDS(list(bins=bins, agg=agg, denom=denom),
        "/workspace/output/replication/logs/figure6_results.rds")

## ---- 4. plot ----
for (nm in c("Figure6.pdf","FigureA11.pdf")) {
  pdf(paste0(FIG,nm), width=8, height=5); par(mar=c(4,4,1,1))
  ylim <- range(c(bins$lo,bins$hi,agg$est,0), na.rm=TRUE)
  bp <- barplot(bins$est, names.arg=bins$wagebin, col="lightblue", border=NA,
                ylim=ylim, xlab="Wage ($/hour bin)", ylab="Employment elasticity")
  arrows(bp, bins$lo, bp, bins$hi, angle=90, code=3, length=0.02, col="darkgreen")
  lines(bp, bins$totest, lty=3, lwd=2, col="purple")
  abline(h=0, col="gray50")
  points(max(bp)+1, agg$est, pch=15, col="purple", cex=1.5, xpd=TRUE)
  legend("bottomleft", bty="n",
         legend=sprintf("Aggregate emp. elasticity = %.3f (%.3f)", agg$est, agg$se))
  dev.off()
}
cat("Wrote", paste0(FIG,"Figure6.pdf"), "and FigureA11.pdf\n")
cat(sprintf("time %.1fs\n", as.numeric(difftime(Sys.time(),t0,units="secs"))))
