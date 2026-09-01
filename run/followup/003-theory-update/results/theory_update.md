# Theory, updated to 2026

### A minimum-wage bunching model with a bite-dependent labor-demand elasticity

*Living update of Cengiz, Dube, Lindner & Zipperer (CDLZ), "The Effect of Minimum
Wages on Low-Wage Jobs," QJE 2019. This section recalibrates the paper's own
structural objects on data through the $15 era and proposes the minimal amendment
that reconciles the 1979–2016 evidence with the 2016–2024 evidence produced in
follow-up 001.*

Every quantitative claim is tagged **[ESTIMATED]** (recovered from data),
**[CALIBRATED]** (a parameter set to match a moment), or **[PROPOSED]** (a
theoretical statement consistent with the evidence but not itself tested).

---

## 1. The original model (recap)

CDLZ do not write down a structural labor-market model; their framework is a
**bunching accounting identity** on the wage distribution plus a competitive/
monopsony reduced form for its elasticity. For each of 138 prominent state
minimum-wage events they measure

- **missing jobs** below the new minimum, `b = Emp₁[w<MW] − Emp₀[w<MW] < 0`;
- **excess jobs** at/just above it, `a = Emp₁[MW≤w<W] − Emp₀[MW≤w<W] > 0`;
- **net affected employment**, `%ΔE = e = (a+b)/E_pop`;
- the **own-wage employment elasticity** (which they call "the labor-demand
  elasticity in a competitive market"), `η = %ΔE / %ΔWage = (1/%w)·(a+b)/(b₋₁)`.

The paper's three structural facts, taken from the replication artifacts on disk
(`/workspace/eval/verify/verdicts.json`, `codebase/.../Table1.tex`):

| object | paper value | meaning |
|---|---|---|
| net `%ΔE` | **+2.8 % (se 2.9)** | excess ≈ −missing; jobs reshuffle, none lost |
| `%ΔWage` | +6.8 % (se 1.0) | affected wages rise |
| own-wage `η` | **+0.411 (se 0.43)** | ≥ 0: mild monopsony, not competitive-negative |
| slope `dE/dKaitz` | **+0.006 (se 0.048)** | *flat*: no job loss up to Kaitz ≈ 0.59 |

The last row is the paper's key theoretical object (its Figure V-B). Missing jobs
grow steeply with the Kaitz index (min/median) — coefficient −0.133 (se 0.034) —
but excess jobs grow **equally** — +0.139 (se 0.057) — so the net slope is
statistically zero. The bunching offset (**retention** `ρ ≡ a/(−b) ≈ 1`) is what
delivers "no disemployment," and it is assumed constant across the observed range
Kaitz ∈ [0.37, 0.59]. The paper is explicit that this is a *local* result: minimum
wages "have yet to reach a point where the job losses become sizable … the
employment consequences of a minimum wage that surpass the ones studied here
remain an open question."

**In one equation, the CDLZ model is** `e(K) = c₀`, with `c₀ ≈ 0` (in fact
+0.028) and slope `γ = dE/dK = 0`, over `K ≤ 0.59`.

---

## 2. What the new evidence demands

Follow-up 001 rebuilt the entire pipeline from raw microdata, validated it
against the shipped panel (138 events reproduced exactly; anchor `Δa=0.021`,
`Δb=−0.018` reproduce the paper), and extended it to **236 events through 2024**,
a sample in which CA/NY/WA/NJ and ~30 other states ratcheted toward $15–$18 and
the Kaitz frontier moved from 0.59 to **0.67**. Reading 001's
`estimates_by_window.csv` and `kaitz_split.csv`, three facts break the flat model:

1. **The central estimate drifted to zero/negative.** Pooled 1979–2024
   `%ΔE = −1.1 % (se 1.2)` vs the paper's +2.8 % **[ESTIMATED]**. The own-wage
   elasticity fell from +0.49 (anchor) to −0.24 (pooled).
2. **The drift is concentrated in the highest-bite recent cohort.** The 2016–2019
   ramp-up window (W4) has `%ΔE = −4.0 % (se 2.4)`, `t ≈ −1.7`, `η = −1.06` —
   the single most negative cohort, and the one with the largest **bite**
   (missing-jobs share `b̄ = 0.116` vs ~0.084 historically) **[ESTIMATED]**.
3. **The operative state variable is bite, not Kaitz alone.** W4 (2016–2019) and
   W5 (2020–2024) have *nearly identical Kaitz* (0.513 vs 0.520) but *different
   bite* (0.116 vs 0.094) and *opposite* employment effects (−4.0 % vs +0.7 %).
   The negative response tracks how deep the increase cuts into the distribution,
   not the min/median ratio per se.

Crucially, **nothing is statistically significant**: no window or Kaitz-half
shows job loss that rejects zero (the tightest, W4, is 1.7σ). The flat model is
not *rejected*; its *central prediction* is contradicted by a ~2.8σ residual at
the one cohort that pushed past the paper's frontier (Section 4). This is what a
2026 revision must accommodate: **a small, still-imprecise negative tilt that
switches on only at high bite / high Kaitz**, while leaving the 1979–2016 result
intact.

---

## 3. The updated model (the minimal amendment)

**One change, one new state-dependence.** Keep the entire CDLZ bunching apparatus
and let the retention rate `ρ` — equivalently the own-wage/labor-demand
elasticity `η` — decline once the increase's bite crosses a threshold:

> **e(b̄) = c₀** for `b̄ ≤ b̄*`  (paper regime; ρ ≈ 1, η ≈ +0.4)
> **e(b̄) = c₀ − s·(b̄ − b̄*)** for `b̄ > b̄*`  (retention falls; η turns negative)

Indexed by the Kaitz ratio the structural driver reads `e(K) = c₀ − s_K·(K−K*)₊`.
This **nests CDLZ exactly** (recover the paper at `s=0`, or `b̄*→∞`): it adds a
single kink, not a new functional form. It is the smallest modification that fits
both eras, because below the threshold it *is* the old model.

**Micro-foundation [PROPOSED].** The kink is what a monopsony model with a finite
labor-supply elasticity to the firm predicts. Raising a binding minimum from below
the competitive wage `w_c` moves employers *up* their upward-sloping supply curve,
so employment rises (or is flat) and `η ≥ 0` — the paper's regime. Employment peaks
where `MW = w_c` and turns negative beyond, as firms are pushed onto the
downward-sloping labor-demand / plant-exit margin and a growing share of "missing"
jobs are destroyed rather than bunched up (`ρ < 1`). The turning point maps to a
critical bite `b̄*` — equivalently a critical Kaitz ratio `K*` — for the marginal
low-wage employer. In this reading the labor-demand elasticity is not a constant
but a **function of bite**: `η(b̄) = η₀ − λ·(b̄ − b̄*)₊`, sliding from mild-monopsony
positive to competitive-negative as the floor climbs the wage distribution.

**Alternative considered and rejected.** A *heterogeneous-firm exit margin* (a
Melitz-style productivity cutoff, where each increment of the minimum knocks out
the least-productive firms) also generates "≈0 at moderate bite, negative at high
bite." I reject it as the *primary* amendment for three reasons: (i) it needs a
full firm-productivity distribution — several new parameters, violating minimality;
(ii) it predicts an *accelerating, convex* decline in employment, whereas the data,
if anything, *flatten* at the very top Kaitz bin (the 5-group function's highest
bin, `K=0.58`, is +1 %, not the most negative); (iii) it does not naturally
reproduce the paper's **positive** own-wage elasticity (+0.41) at moderate bite,
whereas monopsony does. I also rejected a *pure linear* Kaitz slope (no kink):
it would force strongly positive effects at very low Kaitz (0.37), which the flat,
mildly-positive paper-era data do not show. The threshold form is both more
parsimonious in spirit (it collapses to CDLZ) and a better shape match.

---

## 4. Calibration and validation

### 4.1 Side-by-side calibration (paper era vs 2026)

Full detail in `calibration_table.csv`. Headline parameters, same estimation
machinery (001's QCEW-benchmarked TWFE bunching event study) applied to both eras:

| structural object | paper era (source) | 2026 | label |
|---|---|---|---|
| slope `dE/dKaitz` | +0.006 (se .048) — Fig V-B | −0.11 (se .31) grouped; −0.97 (se .79) window | [ESTIMATED] |
| net `%ΔE` pooled | +0.028 | −0.011 (se .012) | [ESTIMATED] |
| own-wage `η`, low bite | +0.411 (se .43) | +0.49 (anchor) | [ESTIMATED] |
| own-wage `η`, high bite | *(one value only)* | −1.06 (W4) | [ESTIMATED] |
| bite threshold `b̄*` | none (flat) | **0.094** (CI ~0.08–0.12) | [CALIBRATED] |
| Kaitz threshold `K*` | untested > 0.59 | **≈ 0.50** (CI ~0.45–0.60) | [CALIBRATED] |
| slope `s` above `b̄*` | 0 | **1.74** per unit bite (se 1.02) | [CALIBRATED] |
| observed Kaitz frontier | 0.59 | 0.67 | [ESTIMATED] |

The two new parameters are **calibrated to one moment**: the zero-crossing and
slope of net employment on bite across the five calendar cohorts (window-level WLS,
`%ΔE = 0.163 − 1.744·b̄`, so `b̄* = 0.094`). Because I recalibrate to moments 001
already produced rather than re-estimating a structural monopsony model in-session
(item 6 of the brief), the threshold parameters are **[CALIBRATED], not
[ESTIMATED]**, and their uncertainty is wide: `s = 1.74 (se 1.02, t=−1.7)`.

### 4.2 Validation 1 — the paper era reproduces the flat model

Re-estimating the Kaitz slope with the *same* machinery on 1979–2016 gives
**−0.065 (se 0.48)** — statistically indistinguishable from the published +0.006,
and from zero. The anchor net `%ΔE = +3.5 %` reproduces the paper's +2.8 %. Below
the threshold the amendment is invisible, as required: the update does not disturb
what CDLZ got right **[ESTIMATED]**.

### 4.3 Validation 2 — an episode the original model cannot explain

The 2016–2019 $15 ramp-up (W4) is the natural out-of-sample episode: it is the
first cohort to push bite (0.116) clearly past `b̄*` and Kaitz to the frontier.
Comparing the two models across all five cohorts (weighted by precision):

| cohort | bite | observed `%ΔE` (se) | CDLZ flat pred. | updated pred. |
|---|---|---|---|---|
| W1 1979–1994 | 0.082 | −1.1 % (6.9) | +3.5 % | +3.5 % |
| W2 1995–2007 | 0.084 | +4.6 % (3.3) | +3.5 % | +3.5 % |
| W3 2008–2015 | 0.084 | −2.2 % (4.1) | +3.5 % | +3.5 % |
| **W4 2016–2019** | **0.116** | **−4.0 % (2.4)** | **+3.5 %** | **−0.4 %** |
| W5 2020–2024 | 0.094 | +0.7 % (3.5) | +3.5 % | +3.4 % |

The flat model misses W4 by **−7.5 pp = −3.2σ**; the threshold model cuts that to
**−3.6 pp = −1.5σ**, and the precision-weighted RMSE across cohorts falls **36 %**
(0.055 → 0.035). The updated model buys this almost entirely at W4 — exactly the
cohort past the frontier — while matching the flat model everywhere the flat model
already worked, including W5, whose lower bite the flat model happened to fit but
whose *difference* from W4 (same Kaitz, lower bite → no job loss) only the
bite-threshold model rationalizes **[ESTIMATED]** comparison, **[CALIBRATED]**
model.

### 4.4 Honest limits of the validation

A strict *temporal* hold-out (calibrate pre-2015, forecast post-2015) **cannot**
test this amendment, and I do not claim it does: the high-bite regime is *only*
observed after 2016, so pre-2015 data are all sub-threshold and identify none of
the new parameters. What I show instead is (a) reproduction of the flat model in
the paper era and (b) reconciliation of the one post-frontier episode — the
evidence the brief's item 3 explicitly points to. The cross-sectional Kaitz slope
on the *pooled* 1979–2024 sample is flat and noisy (−0.11, se 0.31): mixing eras
washes out the signal because moderate-Kaitz events in the 1990s–2000s lost no
jobs. The negative tilt lives in the **bite × recent-era** interaction, not in
cross-sectional Kaitz — which is itself a finding, and the reason the model is
indexed by bite.

---

## 5. What the update implies going forward

- **[PROPOSED] A detectable-disemployment frontier near Kaitz ≈ 0.5–0.6 / bite ≈
  0.10–0.12.** The central calibration puts the sign-change of net employment at
  `K* ≈ 0.50` and `b̄* ≈ 0.094`, with the first *statistically* significant job
  loss expected only once several states sit well above it. At `K ≈ 0.60` the
  model's central prediction is `%ΔE ≈ −s_K·(0.60−0.50) ≈ −5 % to −10 %`, but the
  ±1-SE fan (Figure, Panel A) spans roughly −2 % to −19 % — the threshold's
  *location* is far better identified than its *slope*.
- **[PROPOSED] Watch bite, report η(b̄).** A 2026 revision should stop reporting a
  single own-wage elasticity and instead report `η` as a function of bite: ≈ +0.4
  below `b̄*`, turning negative (−1.06 at W4) above it. The paper's +0.411 is best
  read as the *sub-threshold* value, not a global constant.
- **[ESTIMATED, cautionary] The result still "holds."** Even at the frontier the
  data cannot reject zero. The honest 2026 statement is not "minimum wages now
  cost jobs" but "the reshuffling-without-loss result is a **sub-threshold**
  phenomenon; as the U.S. crosses into a Kaitz range it had never occupied, the
  central estimate has tipped negative and the model that best organizes both eras
  is one whose labor-demand elasticity declines with bite — a hypothesis the next
  five years of $15-era data will actually be able to test."

---

*Artifacts:* `calibration_table.csv` (all parameters + sources),
`fig1_bite_kaitz_threshold.png/.pdf` (the two-panel function + threshold),
`employment_by_kaitz_{orig,all,full3}.csv` (the recalibrated Kaitz functions),
`calibration_numbers.json` (machine-readable). Moments reused from
`followup/001-living-update/results/` (window & Kaitz-split estimates) and
`followup/002-theory-update/results/employment_by_bite.csv` (bite function). No
microdata were re-fetched; the Kaitz-binned joint regressions were the compute
run this session.
