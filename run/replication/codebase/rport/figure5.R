## ============================================================================
## Figure 5 : employment change vs minimum-to-median (Kaitz) wage ratio
## port of Figure5_for_QJE.do
## ============================================================================
source("/workspace/output/replication/codebase/rport/qje_lib.R")
options(width=160)

unemp <- as.data.table(read_dta(paste0(DATA,"state_level_quarterly_unemp_rate.dta")))[,.(statenum,quarterdate,unemp_rate)]
pres  <- as.data.table(read_dta(paste0(DATA,"presidential_elections_from 1976_2016.dta")))
votes <- pres[year>1990, .(dem=sum(dem_vote), rep=sum(rep_vote)), by=.(statenum)]
votes[, republican := as.integer(rep>dem)]
urban <- as.data.table(read_dta(paste0(DATA,"Urbanshare_ver13.dta")))[,.(statenum, urbanshare=pop2010/100)]
vz    <- as.data.table(read_dta(paste0(DATA,"VZmw_quarterly_lagsleads_1979_2016.dta")))[,.(statenum,quarterdate,logmw)]
medw  <- as.data.table(read_dta(paste0(DATA,"median_wage_state_quarter_QJE.dta")))[,.(statenum,quarterdate,year,med_wage)]
evc   <- as.data.table(read_dta(paste0(DATA,"eventclassification.dta")))[,.(statenum,quarterdate,fedincrease,overallcountgroup)]

nc <- merge(medw, vz, by=c("statenum","quarterdate"))
nc[, MW := exp(logmw)][, MWtomed := MW/med_wage]
nc <- merge(nc, votes[,.(statenum,republican)], by="statenum", all.x=TRUE)
nc <- merge(nc, unemp, by=c("statenum","quarterdate"), all.x=TRUE)
nc <- merge(nc, evc,   by=c("statenum","quarterdate"))            # keep(3)
nc <- merge(nc, urban, by="statenum")                            # keep(3)
nc <- nc[st_gt(overallcountgroup,0) & !is.na(overallcountgroup) & st_ne(fedincrease,1)]

## event-specific estimates (stacked)
es <- as.data.table(read_dta(paste0(DATA,"stacked_events_new_event_specific_estimates_clean_controls.dta")))
setnames(es, paste0("ests",1:10),
  c("event_estimate_post","event_estimate_pre","eventno","placebono","cat",
    "statenum","quarterdate","placebo_statenum","E_all","avetotalpopulation"))
es[, category := c("_above","_below","_upper","_all","_bunching")[cat]]
es <- es[category %in% c("_above","_below")]
w <- dcast(es, statenum+quarterdate ~ category,
           value.var=c("event_estimate_post","E_all","avetotalpopulation"))
w[, above_estimate := event_estimate_post__above / E_all__above]
w[, below_estimate := event_estimate_post__below / E_all__above]
w[, emp_estimate   := above_estimate + below_estimate]
setnames(w, "avetotalpopulation__above", "avetotalpopulation_above")
dat <- merge(w, nc, by=c("statenum","quarterdate"))              # keep(3)
dat[, year := 1960 + quarterdate %/% 4]
for (d in c(1990,2000,2010)) dat[, paste0("decade_",d) := as.integer(year>=d & year<=d+9)]
dat <- dat[statenum!=11]                                          # drop DC

ctrl <- c("unemp_rate","urbanshare","decade_1990","decade_2000","decade_2010","republican")
slope <- function(yv) {
  f <- as.formula(paste(yv,"~ MWtomed +", paste(ctrl,collapse="+")))
  m <- lm(f, data=dat, weights=avetotalpopulation_above)
  s <- summary(m)$coefficients["MWtomed",]
  list(b=s[1], se=s[2], m=m)
}
emp <- slope("emp_estimate"); bel <- slope("below_estimate"); abv <- slope("above_estimate")
cat(sprintf("Figure5 slopes vs MW-to-median ratio (robust OLS, weighted, ex-DC):\n"))
cat(sprintf("  Total employment: %.3f (%.3f)\n", emp$b, emp$se))
cat(sprintf("  Missing jobs    : %.3f (%.3f)\n", bel$b, bel$se))
cat(sprintf("  Excess jobs     : %.3f (%.3f)\n", abv$b, abv$se))

## binscatter helper: residualize y & x on controls, add back means, decile-bin
binsc <- function(yv) {
  ry <- resid(lm(as.formula(paste(yv,"~",paste(ctrl,collapse="+"))), data=dat, weights=dat$avetotalpopulation_above)) + mean(dat[[yv]])
  rx <- resid(lm(as.formula(paste("MWtomed ~",paste(ctrl,collapse="+"))), data=dat, weights=dat$avetotalpopulation_above)) + mean(dat$MWtomed)
  q <- cut(rx, quantile(rx, probs=seq(0,1,.1), na.rm=TRUE), include.lowest=TRUE)
  data.table(x=tapply(rx,q,mean), y=tapply(ry,q,mean))
}
fwrite(data.table(outcome=c("total_emp","missing","excess"),
                  slope=c(emp$b,bel$b,abv$b), se=c(emp$se,bel$se,abv$se)),
       "/workspace/output/replication/logs/figure5_slopes.csv")

## Figure5_a : total employment
pdf(paste0(FIG,"Figure5_a.pdf"), width=6.5, height=5); par(mar=c(4.5,4.5,1,1))
be <- binsc("emp_estimate")
plot(be$x, be$y, pch=19, col="darkgreen", xlab="Minimum-to-median wage ratio",
     ylab="Change in employment / pre-treatment total emp.", ylim=c(-0.04,0.04))
abline(lm(y~x,be), col="darkgreen", lwd=2); abline(h=0, col="gray70")
legend("topright", bty="n", sprintf("Emp. change slope = %.3f (%.3f)", emp$b, emp$se))
dev.off()
## Figure5_b : missing + excess
pdf(paste0(FIG,"Figure5_b.pdf"), width=6.5, height=5); par(mar=c(4.5,4.5,1,1))
bb <- binsc("below_estimate"); ba <- binsc("above_estimate")
plot(ba$x, ba$y, pch=19, col="steelblue", xlab="Minimum-to-median wage ratio",
     ylab="Change in employment / pre-treatment total emp.", ylim=c(-0.05,0.05))
points(bb$x, bb$y, pch=17, col="red")
abline(lm(y~x,ba), col="steelblue", lwd=2); abline(lm(y~x,bb), col="red", lwd=2)
abline(h=0, col="gray70")
legend("topright", bty="n", c(sprintf("Excess slope = %.3f (%.3f)", abv$b, abv$se),
                              sprintf("Missing slope = %.3f (%.3f)", bel$b, bel$se)),
       col=c("steelblue","red"), pch=c(19,17))
dev.off()
cat("Wrote Figure5_a.pdf and Figure5_b.pdf\n")
