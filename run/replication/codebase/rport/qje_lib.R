# Shared helpers for the R port of Cengiz-Dube-Lindner-Zipperer (QJE 2019)
# Replaces Stata reghdfe / lincom / nlcom infrastructure.
suppressMessages({
  library(haven); library(data.table); library(fixest); library(numDeriv)
})

DATA <- "/workspace/output/replication/codebase/data/"
FIG  <- "/workspace/output/replication/codebase/figures/dofiles/"
TAB  <- "/workspace/output/replication/codebase/tables/dofiles/"
EST  <- "/workspace/output/replication/codebase/estimates/dofiles/"
for (d in c(FIG, TAB, EST)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

## ---- Stata missing-value comparison semantics (. behaves as +Inf) ----
# x != v  -> TRUE when x is missing
st_ne <- function(x, v) is.na(x) | x != v
# x > v   -> TRUE when x is missing
st_gt <- function(x, v) is.na(x) | x > v
# x != .  -> TRUE only when x is NOT missing
st_nm <- function(x) !is.na(x)
# x == v  -> FALSE when x missing
st_eq <- function(x, v) !is.na(x) & x == v

## Stata yq(year,quarter): quarters since 1960q1 (=0)
yq <- function(year, quarter) (year - 1960) * 4 + (quarter - 1)

## Weighted mean (aweight semantics); na.rm on x
wmean <- function(x, w) {
  ok <- !is.na(x) & !is.na(w)
  sum(x[ok] * w[ok]) / sum(w[ok])
}

## Linear combination b = w'beta with (clustered) vcov V.
## Returns estimate, se, p (two-sided t with given dof).
lincom_wt <- function(w, beta, V, dof) {
  est <- sum(w * beta)
  se  <- sqrt(as.numeric(t(w) %*% V %*% w))
  p   <- 2 * pt(-abs(est / se), df = dof)
  list(est = est, se = se, p = p)
}

## Nonlinear combination via delta method (numerical gradient), matching nlcom.
nlcom_fun <- function(fun, beta, V, dof) {
  est <- fun(beta)
  g   <- numDeriv::grad(fun, beta)
  se  <- sqrt(as.numeric(t(g) %*% V %*% g))
  p   <- 2 * pt(-abs(est / se), df = dof)
  list(est = est, se = se, p = p)
}

## format like Stata %04.3f with significance stars
fmt3 <- function(x) sprintf("%.3f", x)
stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
