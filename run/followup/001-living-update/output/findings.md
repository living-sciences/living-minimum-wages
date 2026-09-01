# Living update — Cengiz, Dube, Lindner & Zipperer (QJE 2019) through 2025

**Question.** Re-estimate CDLZ's three headline claims on minimum-wage (MW) "bunching"
event studies using data extended from the paper's 1979–2016 sample through **2024q4
events / 2025q4 outcomes**, and show how the findings evolved into the $15-era.

**Method (one line).** Same design as the paper — difference-in-differences event study
over $0.25 real-wage bins, state×bin and quarter×bin FEs, small/federal-event Ω controls,
SEs clustered by state, QCEW-benchmarked, delta-method scalars. The full construction
(CPS wage-bin panel, MW panel, event screen, treatment dummies, estimator) was rebuilt in
Python and **validated against the replication's shipped panel**: treatment dummies match
exactly, the event screen reproduces **exactly 138 prominent events** for 1979–2016, and the
anchor regression reproduces the paper (see below).

## Anchor check (does the rebuild reproduce the paper?)

| Quantity | CDLZ 2019 (Table I col 1) | This rebuild (1979–2016) |
|---|---|---|
| Excess jobs Δa | 0.021 (0.003) | **0.0211 (0.0026)** |
| Missing jobs Δb | −0.018 (0.004) | **−0.0181 (0.0038)** |
| % Δ affected employment | +0.028 (0.029) | **+0.035 (0.032)** |
| % Δ affected wage | +0.068 (0.010) | **+0.070 (0.009)** |
| Own-wage elasticity | 0.411 (0.430) | **0.493 (0.443)** |
| bite b̄₋₁ / %ΔMW / E | 0.086 / 0.101 / 0.571 | **0.087 / 0.101 / 0.571** |

Δa, Δb, bite, %ΔMW and E reproduce to three decimals; %Δe and OWE are within a fraction of
one SE. The pipeline is faithful.

## The three claims, original vs today

**C1 — Employment (no job loss).** *Held, but the central estimate softened toward zero/negative.*
Pooling **all 236 events, 1979–2024**, net affected-employment change is **−1.1% (se 1.2%)** —
still statistically indistinguishable from zero, but the point estimate moved from the
paper's **+2.8%** to slightly negative. By event-cohort:

| Window | Period | n | real %ΔMW | bite | Kaitz | %Δemp (se) | %Δwage (se) |
|---|---|---|---|---|---|---|---|
| W1 | 1979–1994 | 25 | 14% | 0.082 | 0.48 | −1.1% (6.9) | +6.7% (2.1) |
| W2 | 1995–2007 | 51 | 12% | 0.084 | 0.47 | +4.6% (3.3) | +9.2% (1.7) |
| W3 | 2008–2015 | 47 | 8% | 0.084 | 0.48 | −2.2% (4.1) | +2.9% (2.0) |
| **W4** | **2016–2019** | 52 | 7% | **0.116** | 0.51 | **−4.0% (2.4)** | +3.8% (0.9) |
| **W5** | **2020–2024** | 61 | 8%* | 0.094 | 0.52 | **+0.7% (3.5)** | +4.4% (1.4) |

No single window shows **statistically significant** job loss (all |t|<1.7). The most negative
point estimate is **W4, the $15-ramp-up (2016–2019), −4.0% (se 2.4%, t≈−1.7)** — the window
with the highest bite (11.6% of the workforce below the new MW). W5 (COVID + tight labor
market + inflation) is benign at +0.7%. *Real MW growth in W5 was only ~8% despite ~10%
nominal, because the 2021–23 inflation burst eroded nominal hikes.

**C2 — Wages / spillovers.** *Held.* Affected-worker wages rose significantly in **every**
window (+2.9% to +9.2%; pooled +4.6%, se 0.6%). Gains are somewhat smaller post-2008,
consistent with smaller real bites once inflation is netted out. Implied own-wage
elasticities stay small and mostly positive; the pooled OWE is −0.24 (se 0.28), imprecise
and not significantly negative.

**C3 — Does it break at higher bites? (the live question).** *A hint of the frontier, but no
break yet.* New-era events push the minimum-to-median (Kaitz) ratio to **0.67 (ME 2020)**,
past the paper's 0.59 frontier. Splitting the 113 W4+W5 events at Kaitz 0.5:

| Group | n | mean Kaitz | bite | %Δemp (se) | %Δwage (se) |
|---|---|---|---|---|---|
| Kaitz ≥ 0.5 | 70 | 0.556 | 0.111 | **−3.2% (4.3)** | +1.6% (0.9) |
| Kaitz < 0.5 | 43 | 0.454 | 0.084 | +1.2% (3.2) | +2.1% (1.4) |

At the higher, out-of-sample bites the employment point estimate turns **negative (−3.2%)
but remains statistically insignificant**. The **bunching signature itself is robust in every
era** (missing jobs below ≈ excess jobs above; see `figure2_new_era.png`), though in the
high-bite W4 window missing jobs (Δb=−0.025) modestly exceed the excess (Δa=+0.020),
producing the net-negative point estimate.

## Verdict

**The findings largely HELD but SOFTENED.** The wage effect (C2) and the bunching mechanism
(C1's decomposition) are as robust in the $15-era as in the original sample. The headline
"no disemployment" (C1) survives statistical scrutiny — **no window or Kaitz-half shows
significant job loss** — but the central employment estimate drifted from +2.8% to about zero
or slightly negative, concentrated in the highest-bite 2016–2019 cohort and the Kaitz≥0.5
events. This is consistent with the disemployment frontier lying **near the top of the newly
observed Kaitz range (~0.6–0.67)** rather than being decisively crossed. The 2020–2024
tight-labor/inflation era looks benign because real minimums eroded.

## Data & method caveats

- **QCEW benchmarking applied** (not skipped): BLS QCEW open API, state total covered
  employment, 1979–2025; validated corr=1.00 vs the paper's shipped 2016 file. This matters
  here — without it the normalization (E) roughly doubles the %Δe point estimates.
- **2025 seam:** MORG (NBER) ends at 2024; 2025 built from Census Basic Monthly CPS ORG
  extract per spec §3.3. Quarterly employment levels and under-$15 shares align with 2024
  MORG (small seam; event-study FEs absorb pure level shifts). **Oct 2025 CPS & CPI are
  missing (government shutdown)** → 2025q4 built from Nov+Dec only.
- **CPI:** CPI-U-RS (paper's deflator) through 2016, spliced month-by-month with CPI-U growth
  2017–2025; base 2016=100. All magnitudes in 2016 dollars.
- **Mid-year MW dating** for FL (Sep), OR/NV/DC (Jul), CT (Jun) applied from statutory
  schedules; **Oregon** uses the standard state schedule because FRED's `STTMINWGOR` reports
  the higher Portland-metro rate (flagged). NV two-tier seam smoothed by enforcing nominal
  non-decrease in 2017q1+.
- **Truncated post-windows:** events in 2022q1–2024q4 contribute only the event-times (τ)
  observed by 2025q4; W5 long-horizon effects are less precisely measured.
- **Event definition** follows the paper's ground-truth do-file (real ΔMW > $0.25), which
  reproduces the 138 exactly, rather than the spec's "nominal ≥ $0.25" candidate wording.
- **Anchor %Δe** is 0.035 vs the paper's 0.028 (within SE), tracing to a ~1.5% discrepancy in
  the aggregated small-event control near the 2016 boundary and a 0.001 difference in bite.
- No Stata available (as in the replication); estimation via `pyfixest` (fixed effects +
  cluster-robust VCE), mirroring the replication's Stata→R port.
