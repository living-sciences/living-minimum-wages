# Follow-up study report — Living update of Cengiz, Dube, Lindner & Zipperer (QJE 2019)

## Question

CDLZ (2019), "The Effect of Minimum Wages on Low-Wage Jobs," estimated a difference-in-
differences bunching event study over 138 prominent state minimum-wage (MW) increases,
1979q1–2016q4, and found: **(C1)** the jobs that go missing just below a new MW are offset by
excess jobs at/just above it, so net affected employment is unchanged (+2.8%, se 2.9%);
**(C2)** affected wages rise +6.8% (se 1.0%), implied own-wage elasticity +0.41; **(C3)** no
negative relationship between the employment estimate and the MW/median (Kaitz) ratio up to
~0.59. This follow-up re-estimates all three claims on data **extended through 2024q4 events
/ 2025q4 outcomes** — spanning the post-2016 "$15+ era," when CA/NY/WA/NJ/IL/FL and ~30 other
states ratcheted to $12–$18 while the federal floor stayed at $7.25 — and shows how the
findings evolved.

## Approach

**Reused from the replication** (`/workspace/eval/replication/`): the shipped 1979–2016
CPS wage-bin count panel (`state_panels_cents_QJE.dta`), the paper's cleaned Vaghul–Zipperer
MW series, the CPI-U-RS deflator, the shipped `eventclassification.dta` and treatment-dummy
panel (used **only for validation**), the QCEW 2016 benchmark file (for validation), and the
estimation logic from the replication's R port (`rport/table1.R`, `qje_lib.R`) which I
re-implemented in Python.

**Built new** (the replication never rebuilt the panel from raw microdata — it used
pre-computed `.dta`; the follow-up requires the whole construction on extended data):

1. **CPI** 1979–2025, base 2016: CPI-U-RS through 2016 spliced with BLS CPI-U growth
   (keyless API) 2017–2025. Oct-2025 missing (shutdown) → 2025q4 = Nov+Dec.
2. **MW panel** 1979q1–2025q4: VZ cleaned series ≤2016q4, VZ v1.4.0 quarterly 2017q1–2022q4,
   FRED `STTMINWG{state}` Jan-1 rates 2023–2025 + statutory mid-year schedule for FL/OR/NV/DC/CT.
   Sanity checks passed (no nominal decreases in the extension era; federal-floor states flat;
   clean 2016 seam). OR uses the standard-rate schedule (FRED reports Portland-metro).
3. **CPS wage-bin panel** 1979q1–2025q4: reused shipped 1979–2016 counts; built 2017–2024 from
   NBER MORG and 2025 from Census Basic Monthly CPS, porting `state_panels_cents_new_QJE.do`.
   **Validated**: rebuilding 2016 from `morg16.dta` reproduces the shipped panel with
   correlation 1.00000 and ~0 relative error.
4. **Event screen & treatment dummies**: ported `state_panels_tercile1979_QJE.do`
   (alltreat = real ΔMW>$0.25; belowshare bite; toosmall<2%; federal-event flags; the
   I(τ,k) treatment/window/Ω-control dummies for τ=−3..+4 × k=−4..+4). **Validated**: my
   `belowshare` correlates 1.00 (max diff 8e-9) with the shipped classification, `toosmall`/
   `fedincrease` agree 100%, I reproduce **exactly 138 prominent events** for 1979–2016, and my
   `treat_p0/m1/p4` dummies match the shipped columns **exactly** (100%).
5. **QCEW benchmarking** 1979–2025: BLS QCEW open API (state total covered employment),
   validated corr=1.00 against the paper's shipped 2016 file, applied throughout (the paper
   benchmarks CPS counts to QCEW; skipping it here would roughly double the %Δe point).
6. **Estimation**: `pyfixest.feols` (fixed effects + state-clustered VCE) with the paper's
   TWFE spec; Δa/Δb/%Δe/%Δw/OWE via the exact lincom/delta-method scalar machinery ported
   from `table1.R`. Cohorts W1–W5 estimated in **one joint regression** (shared FEs/controls),
   with per-window normalization scalars (E, bite, EWB, wagemult).

## Results

### Anchor reproduction (validation gate)
Rebuilding the paper on 1979–2016 with my pipeline gives Δa=0.021 (paper 0.021), Δb=−0.018
(−0.018), bite=0.087 (0.086), %ΔMW=0.101 (0.101), E=0.571 (0.571), %Δwage=0.070 (0.068),
%Δemp=+0.035 (0.028, within SE), OWE=0.49 (0.41). **The rebuild reproduces the paper**, so the
extension is trustworthy.

### How the findings evolved (per event-cohort)

| Window | Period | n | real %ΔMW | bite | Kaitz | Δa | Δb | %Δemp (se) | %Δwage (se) | OWE |
|---|---|---|---|---|---|---|---|---|---|---|
| Anchor | 1979–2016 | 138 | 10.3% | 0.087 | 0.48 | 0.021 | −0.018 | **+3.5% (3.2)** | +7.0% (0.9) | 0.49 |
| **Pooled** | **1979–2024** | **236** | 8.7% | 0.094 | 0.50 | 0.017 | −0.018 | **−1.1% (1.2)** | +4.6% (0.6) | −0.24 |
| W1 | 1979–1994 | 25 | 14.3% | 0.082 | 0.48 | 0.013 | −0.013 | −1.1% (6.9) | +6.7% (2.1) | −0.17 |
| W2 | 1995–2007 | 51 | 12.4% | 0.084 | 0.47 | 0.024 | −0.020 | +4.6% (3.3) | +9.2% (1.7) | +0.50 |
| W3 | 2008–2015 | 47 | 7.5% | 0.084 | 0.48 | 0.013 | −0.015 | −2.2% (4.1) | +2.9% (2.0) | −0.77 |
| W4 | 2016–2019 | 52 | 7.2% | **0.116** | 0.51 | 0.020 | −0.025 | **−4.0% (2.4)** | +3.8% (0.9) | −1.06 |
| W5 | 2020–2024 | 61 | 7.7% | 0.094 | 0.52 | 0.014 | −0.013 | +0.7% (3.5) | +4.4% (1.4) | +0.15 |

**Kaitz split (C3), W4+W5 events, split at 0.5:** Kaitz≥0.5 (n=70, mean 0.556, up to 0.67):
%Δemp = **−3.2% (se 4.3%)**; Kaitz<0.5 (n=43): +1.2% (se 3.2%). Higher bites → more negative
point estimate, still insignificant.

Figures: `results/living_estimate.png/.pdf` (3-panel flagship: %Δemp, %Δwage, and the Δa/Δb
bunching signature per cohort against the CDLZ reference bands); `results/figure2_new_era.png`
(bin-by-bin employment change, original vs new-era events — the bunching signature holds in
both). Tables: `results/estimates_by_window.csv`, `results/kaitz_split.csv`,
`results/new_events.csv` (236 events: 138 original + 98 new, 37 in W4 + 61 in W5).

### Comparison to the original replication values

| Quantity | Original (source) | This follow-up | Note |
|---|---|---|---|
| Δa (excess) | 0.021 (Table1.tex / verdicts.json C5) | 0.021 anchor; 0.017 pooled 1979–2024 | reproduced; stable |
| Δb (missing) | −0.018 (verdicts.json C4) | −0.018 anchor; −0.018 pooled | reproduced; stable |
| %Δ employment | +0.028 (verdicts.json C1) | +0.035 anchor → **−0.011 pooled 1979–2024** | softened toward/below 0, still insignificant |
| %Δ affected wage | +0.068 (verdicts.json C2) | +0.070 anchor → +0.046 pooled | held; smaller recently |
| Own-wage elasticity | +0.411 (verdicts.json C3) | +0.49 anchor → −0.24 pooled | held at anchor; imprecise pooled |
| # prominent events | 138 | 138 original + 98 new (236 total) | screen reproduced exactly |
| Kaitz frontier | ~0.59 (paper C3) | events now reach 0.67; −3.2% (ns) at Kaitz≥0.5 | frontier approached, not crossed |

Original values are read from `/workspace/eval/verify/verdicts.json` and the replication's
`replication_log.json` / `codebase/tables/tables/Table1.tex`.

## Deviations & limitations

- **QCEW was applied, not skipped** (spec marked it optional). It materially affects the
  normalization, and the paper uses it, so applying it is the faithful choice; the BLS open
  API reproduces the shipped 2016 benchmark exactly.
- **2025 from Census monthly CPS** (MORG ends 2024): validated to align with 2024 MORG at the
  quarterly level; a modest level seam is absorbed by the quarter×bin FEs but reported.
  **Oct 2025 CPS/CPI unavailable (shutdown)** → 2025q4 from Nov+Dec.
- **Event definition** uses the paper's real ΔMW>$0.25 do-file rule (reproduces 138 exactly),
  not the spec's looser "nominal ≥$0.25" candidate wording.
- **MW mid-year dating** for FL/OR/NV/DC/CT is schedule-based; Oregon uses the standard rate
  (FRED's series is the Portland-metro rate); NV two-tier seam smoothed. Any single-state MW
  error affects only that state's few events; the Ω controls absorb non-prominent moves.
- **Truncated post-windows** for 2022q1–2024q4 events (they contribute observed τ's only),
  so W5's longer-horizon effects are less precise.
- **Anchor %Δe = 0.035 vs paper 0.028** (within one SE): traces to a ~1.5% mismatch in the
  aggregated small-event control near the 2016 boundary and a 0.001 bite difference; Δa, Δb,
  E, bite and %ΔMW reproduce to three decimals.
- Demographic/sector subgroups, the placebo tail (k=+5..+17) and the matched-CPS
  incumbent/entrant split were out of scope (the three headline claims are overall estimates).

**Bottom line:** rebuilt from raw microdata and validated against the replication, the CDLZ
findings **held but softened**. Wage gains and the bunching mechanism are as robust in the
$15-era as in 1979–2016; the "no job loss" result survives statistical testing in every
window and Kaitz-half, but the central employment estimate drifted from +2.8% to roughly
zero/slightly negative, concentrated in the highest-bite 2016–2019 cohort and Kaitz≥0.5
events — suggesting the disemployment frontier sits near the top of the newly observed Kaitz
range (~0.6–0.67), not decisively crossed.
