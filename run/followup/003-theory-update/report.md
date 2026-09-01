# Follow-up report — Calibrated theory update for CDLZ (2019)

## Question

CDLZ (2019) model minimum-wage effects with a **bunching identity**: missing jobs
`b` below the new minimum, excess jobs `a` at/above it, net affected employment
`e = a+b`, and an own-wage (labor-demand) elasticity `η = %ΔE/%ΔWage`. Their key
theoretical object — the net-employment-vs-Kaitz relationship (Figure V-B) — is
**flat** (slope +0.006, se .048) over Kaitz ∈ [0.37, 0.59], with `η = +0.411`.
Follow-up 001 re-estimated the paper on 236 events through 2024 and found the
result *held but softened*: no significant job loss anywhere, but the central
estimate drifted from +2.8 % toward 0/negative, most negative in the high-bite
2016–2019 window (−4.0 %, se 2.4). **This follow-up produces the calibrated,
updated theory a 2026 revision would carry**: recalibrate the paper's structural
objects on the latest data, propose the *minimal* model amendment that reconciles
both eras, and validate it. The deliverable is `results/theory_update.md` (the
"Theory, updated to 2026" section); this file is the execution log behind it.

## Approach

**Reused (no recomputation):** 001's downloaded data and validated estimation
machinery — the 1979–2025 CPS wage-bin panel, MW panel, QCEW benchmark, and the
`analysis.py` bunching-event-study functions (`load`/`run_reg`/`scalars`/
`extract`); 001's `estimates_by_window.csv` and `kaitz_split.csv` (era-level
moments); and 002's `employment_by_bite.csv` (the bite-binned employment function
that a prior, killed session had completed).

**Ran this session (the compute):** the **Kaitz-binned employment-effect
function** — the exact step 002 was killed on. Using 002's `bite_function.py`
(which generalizes 001's `kaitz_split.py` from 2 to N quantile groups over all 236
events in one joint TWFE regression), I ran, in the foreground to completion:
- `kaitz 5 1979 2024` → `employment_by_kaitz_all.csv` (2026, 5 Kaitz bins; ~3 min);
- `kaitz 3 1979 2024` → `employment_by_kaitz_full3.csv` (coarser, more power/bin);
- `kaitz 5 1979 2016` → `employment_by_kaitz_orig.csv` (paper-era, side-by-side).

**Built new:** `analyze_theory.py` — recovers the reduced-form slopes (paper's
Fig V-B object) for both eras, calibrates the threshold model, runs the two
validation checks, and writes `calibration_table.csv`, the figure, and
`calibration_numbers.json`. The environment (`/workspace/.venv`) was rebuilt from
scratch (the replication venv was gone): pandas/numpy/scipy/pyfixest 0.60/matplotlib.

## Results

**The employment-effect-by-Kaitz function is flat and noisy when pooled across
eras** (5-bin slope −0.11, se 0.31; 3-bin non-monotone), so the paper's flat
result is *not* overturned cross-sectionally. **The negative signal is a bite ×
recent-era phenomenon.** The cleanest estimates are at the cohort level (001):
net employment on **bite** has slope **−1.74 (se 1.02, t≈−1.7)**, zero-crossing at
bite ≈ 0.094; on **Kaitz**, −0.97 (se 0.79), zero-crossing ≈ 0.49. W4 and W5 pin
this down: same Kaitz (0.513 vs 0.520), different bite (0.116 vs 0.094), opposite
effect (−4.0 % vs +0.7 %) → **bite is the operative variable**.

**Minimal amendment (nests CDLZ):** let the retention rate / own-wage elasticity
decline once bite crosses a threshold — `e(b̄) = c₀` for `b̄ ≤ b̄*`, `e(b̄) = c₀ −
s(b̄−b̄*)` above. Micro-founded [PROPOSED] as **monopsony with a bite-dependent
labor-demand elasticity**: `η(b̄)` slides from +0.4 (mild monopsony) to negative
as the floor climbs the distribution and the marginal firm exits. Rejected
alternatives: heterogeneous-firm exit (needs a productivity distribution; predicts
convex acceleration the data don't show; can't reproduce `η>0` at moderate bite)
and a pure linear Kaitz slope (would force large positive effects at Kaitz 0.37).

### Calibration (paper era vs 2026), from `calibration_table.csv`

| object | paper era | 2026 | label |
|---|---|---|---|
| slope dE/dKaitz | +0.006 (se .048) | −0.11 (se .31) grouped / −0.97 (se .79) window | [ESTIMATED] |
| net %ΔE pooled | +0.028 | −0.011 (se .012) | [ESTIMATED] |
| own-wage η (low bite) | +0.411 (se .43) | +0.49 | [ESTIMATED] |
| own-wage η (high bite W4) | — | −1.06 | [ESTIMATED] |
| **bite threshold b̄\*** | none | **0.094** (CI .08–.12) | [CALIBRATED] |
| **Kaitz threshold K\*** | untested >.59 | **≈0.50** (CI .45–.60) | [CALIBRATED] |
| slope s above threshold | 0 | **−1.74 / unit bite** | [CALIBRATED] |
| observed Kaitz frontier | 0.59 | 0.67 | [ESTIMATED] |

### Validation

1. **Reproduces the paper era.** Kaitz slope on 1979–2016 with the same machinery
   = −0.065 (se 0.48) ≈ published +0.006; both flat. Anchor net +3.5 % ≈ paper
   +2.8 %. The amendment is invisible below threshold, as required.
2. **Explains an episode the flat model cannot (2016–2019, W4).** The CDLZ flat
   model misses W4 by −7.5 pp = **−3.2σ**; the threshold model cuts the residual
   to −3.6 pp = **−1.5σ**, and precision-weighted RMSE across the five cohorts
   falls **36 %** (0.055→0.035) — bought almost entirely at the one post-frontier
   cohort, while matching the flat model everywhere else (incl. W5).

Figure `results/fig1_bite_kaitz_threshold.png`: (A) the recalibrated
employment-by-Kaitz function, paper-era vs 2026, with the flat model and the
threshold amendment (K*≈0.50) and a ±1-slope-SE fan; (B) the cohort-level
employment-by-bite view showing the bite threshold and the W4 flat-model miss.

### Comparison to original replication values

| quantity | original (source) | this follow-up | note |
|---|---|---|---|
| slope dE/dKaitz | +0.006 (paper Sec IV / Fig V-B) | −0.11 (se .31) grouped; −0.97 window | tilts negative, still insignificant |
| net %ΔE | +0.028 (verdicts.json C1) | −0.011 pooled; −0.040 at W4 | softened / negative at frontier |
| own-wage η | +0.411 (verdicts.json C3) | +0.49 low-bite → −1.06 high-bite | now a *function of bite* |
| Kaitz frontier | 0.59 (paper) | 0.67 (001 new events) | frontier crossed the untested range |

Original values read from `/workspace/eval/verify/verdicts.json` (C1, C3), the
paper's Section IV / Figure V-B text (`workspace/paper.txt`), and 001's
`results/estimates_by_window.csv` / `kaitz_split.csv`.

## Deviations & limitations

- **Nothing is statistically significant.** The flat model is not *rejected*; its
  central *prediction* is contradicted by a ~2.8–3.2σ residual at W4. The update is
  a shift in central tendency, honestly reported as such (labels throughout).
- **Threshold parameters are [CALIBRATED], not [ESTIMATED].** Per brief item 6, a
  full structural monopsony estimation was not run in-session; the two new
  parameters are calibrated to the bite-slope zero-crossing/slope that 001 already
  produced. The slope SE is large (t≈−1.7): the threshold's *location* (≈0.5) is
  better identified than its *magnitude*.
- **No strict temporal hold-out is possible** and I do not claim one: the
  high-bite regime is only observed post-2016, so pre-2015 data identify none of
  the new parameters. Validation is by paper-era reproduction + post-frontier
  episode fit, exactly the options the brief lists.
- **Bite, not Kaitz, is the operative index** (W4 vs W5). I present Kaitz as the
  correlated structural driver (for comparability with the paper's "0.5+" frontier
  language) but calibrate the model on bite.
- Group-level `%ΔE` estimates across Kaitz bins are treated as independent when
  computing WLS slopes (the joint-regression cross-bin covariance was not
  extracted); reasonable because bins use disjoint events, but it makes the slope
  SEs mild lower bounds.

**Bottom line.** The 2016–2024 data do not overturn CDLZ but do outgrow its flat
model at the frontier. The minimal, era-reconciling revision is a bunching model
whose labor-demand elasticity **declines with bite** past a threshold near
**Kaitz ≈ 0.50 / bite ≈ 0.094** — mild-monopsony-positive below, competitive-
negative above. It reproduces the paper where the paper worked and resolves the
2016–2019 anomaly it cannot, while remaining honest that the effect is not yet
statistically decisive.
