# Living-version followup spec — Cengiz, Dube, Lindner & Zipperer (QJE 2019), "The Effect of Minimum Wages on Low-Wage Jobs"

You are the followup agent. You are seeded from a completed replication of this paper
(the ported codebase from the original Stata package lives in your working tree; the
original dofiles are in `codebase/dofiles/`, original inputs in `codebase/data/`).
Your job: re-estimate the paper's main claims on data extended through 2025, and show
how the findings evolved from the paper's 1979–2016 sample to today.

Container: Python 3.12 + R 4.x + Octave, full internet. Keys available as env vars:
`FRED_API_KEY`, `DATAVERSE_API_TOKEN`. No Stata — reuse the ported (Python/R)
panel-construction and estimation code from the replication wherever it exists;
the original dofiles are the ground-truth reference for construction rules
(`state_panels_cents_new_QJE.do`, `state_panels_cents_balanced_QJE.do`,
`clean_VZmwdata_QJE.do`, `state_panels_tercile1979_QJE.do`, `create_programs.do`).

## 1. The claims you are updating

Original design: difference-in-differences event study over 138 prominent state-level
minimum wage (MW) increases, 1979q1–2016q4 (excluding 1994q1–1995q3). Outcome:
employment counts per capita in $0.25 real-wage bins (2016 dollars, CPI-U-RS), by
state × quarter, built from the NBER CPS Merged Outgoing Rotation Group (MORG).
Treatment dummies I(τ,k) for event time τ = −3..+4 (years) and wage bin k = −4..+17
dollars relative to the new MW; state×bin and quarter×bin fixed effects; controls for
small and federal MW events; SEs clustered by state. Events require a MW increase
≥ $0.25 and ≥ 2% of the state workforce earning below the new minimum.

- **C1 (employment):** Missing jobs below the new MW, Δb = −0.018 (se 0.004) of
  pre-treatment employment, are offset by excess jobs at/just above it,
  Δa = +0.021 (se 0.003). Net change in affected (low-wage) employment
  %Δe = (Δa+Δb)/b̄₋₁ = **+2.8% (se 2.9%)** — no job loss. (Paper Fig. II–III, Table I col 1;
  b̄₋₁ = 8.6%.)
- **C2 (wages / own-wage elasticity):** Average wage of affected workers rose
  **+6.8% (se 1.0%)**; implied own-wage employment elasticity **+0.411 (se 0.430)**,
  ruling out elasticities below −0.45 at 95%. Wage spillovers extend ~$3 above the
  new MW (~40% of the wage gain).
- **C3 (does it break at higher bites?):** Employment elasticity w.r.t. the MW
  +0.024 (se 0.025); across events, no negative relationship between the employment
  estimate and the MW/median-wage (Kaitz) ratio **up to ~0.59**. This is the claim the
  post-2016 "$15+ era" stress-tests hardest — it is the economically live question today.

Why an update is honest and interesting: after 2016 the federal minimum froze at $7.25
while CA, NY, WA, NJ, IL, FL and ~30 other states ratcheted to $12–$17, so cross-state
variation and bite (Kaitz) are *larger* than anything in the original sample; the
2021–2023 inflation burst also eroded real minimums, making some nominal events small
in real terms. Report real %ΔMW per window so readers can see this.

## 2. Data sources (all verified 2026-08-23; see sources.json)

1. **NBER CPS MORG, 1979–2024** (public, verified):
   `https://data.nber.org/morg/annual/morgYY.dta` for YY = 79..99, 00..24.
   Verified: `morg24.dta` exists (43.6 MB, last-modified 2025-05-20; 244,144 rows;
   columns include `year, stfips, age, earnhre, earnwke, uhourse, paidhre, earnwt,
   weight, I25a..I25d, minsamp, lfsr94, intmonth`). `morg25.dta` does NOT exist (404).
   These are the exact files the paper used (its fn. 11), harmonized names across years.
2. **Census Basic Monthly CPS, 2025 (and 2026 partial)** (public, verified):
   `https://www2.census.gov/programs-surveys/cps/datasets/2025/basic/{mon}25pub.csv`
   for mon = jan..dec (all 12 months verified present; 2026 files jan–jul also exist
   under `.../2026/basic/`). CSV header verified to contain (lowercase):
   `hrmis, gestfips, prtage, pemlr, pehruslt, peernper, peernhry, peernrt, peernhro,
   prerelg, prwernal, prhernal, pwsswgt, pworwgt, pternhly, pternwa` (395 columns).
   Record layout: `2025_Basic_CPS_Public_Use_Record_Layout_plus_IO_Code_list.txt`
   in the same directory.
3. **Vaghul–Zipperer historical state minimum wages, through 2022-12-31**
   (public, verified small download):
   `https://github.com/benzipperer/historicalminwage/releases/download/v1.4.0/mw_state_excel.zip`
   (770 KB; contains `mw_state_quarterly.xlsx`, `mw_state_changes.xlsx`,
   `mw_state_monthly.xlsx`). This is the same VZ series the paper uses (its fn. 14);
   the repo has NOT been updated since v1.4.0 (Nov 2022) — do not look for a newer release.
4. **FRED state minimum wage series, 2023–2026** (needs `FRED_API_KEY`; API endpoint
   verified reachable — returns proper `api_key is not set` error without a key):
   `https://api.stlouisfed.org/fred/series/observations?series_id=STTMINWG{POSTAL}&api_key=$FRED_API_KEY&file_type=json`
   e.g. `STTMINWGCA`, `STTMINWGNY`, … (annual, Jan-1 statutory rate, source US DOL).
   The exact series ids were not confirmable from the build box (FRED web UI blocks
   non-browser clients); at runtime, first call
   `https://api.stlouisfed.org/fred/series/search?search_text=minimum+wage+california&api_key=...&file_type=json`
   to confirm the id pattern, then pull all 50 states + DC.
5. **CPI for deflation**: the package ships `cpiursai1977-2016.dta` (CPI-U-RS, the
   paper's deflator). For 2016→2025, splice on CPI-U growth:
   - Primary (public, keyless, verified): BLS API v2
     `https://api.bls.gov/publicAPI/v2/timeseries/data/CUUR0000SA0?startyear=2016&endyear=2025`
     — verified returns monthly CPI-U through Dec 2025. **Known gap: Oct 2025 value is
     missing (footnote X, shutdown); average the other months in that quarter.**
   - Fallback: FRED `CPIAUCNS`/`CPIAUCSL` via `FRED_API_KEY`.
   Splicing CPI-U-RS with CPI-U growth after its last year is the standard Census
   practice; document it in the findings note.
6. **QCEW (OPTIONAL, skip by default)**: the paper benchmarks CPS counts to QCEW only
   to improve precision ("little effect on point estimates"). If you have time:
   `https://data.bls.gov/cew/data/files/{year}/csv/{year}_qtrly_singlefile.zip`
   (verified: 2024 file returns 200, ~300 MB/yr — heavy; that is why default is skip).
   If skipped, say so and note SEs are modestly larger than the paper's benchmarked ones.
7. Blocked from scripts (do NOT waste time): `www.bls.gov` (403 Akamai), `www.dol.gov`
   (403), `fred.stlouisfed.org` web pages (403/HTTP2 resets — the `api.stlouisfed.org`
   API is fine), `epi.org` (403). IPUMS is not available. Nothing here needs them.

## 3. Construction

### 3.1 Minimum wage panel, 1979q1–2025q4 (state × quarter, quarterly max of daily MW)
- 1979–2016: reuse the replication's cleaned VZ series (from `clean_VZmwdata_QJE.do` /
  package data). 2016q3–2022q4: extend with `mw_state_quarterly.xlsx` from source 3
  (use the max of state and federal; VZ file already includes the federal floor).
- 2023q1–2025q4 (and 2026q1 if you extend): take FRED Jan-1 annual values (source 4)
  as effective 20XXq1, federal floor $7.25 throughout. Then apply these **known
  mid-year-effective states** (statutory schedule knowledge, cross-check levels
  against FRED; if a level disagrees by >$0.05 trust FRED and flag in the note):
  - FL: changes each Sep 30 → effective q4: $12.00 (2023q4), $13.00 (2024q4), $14.00 (2025q4).
  - OR (standard/state rate): changes Jul 1 → q3: $14.20 (2023q3), $14.70 (2024q3), $15.05 (2025q3).
  - NV: Jul 1 → $11.25 (2023q3, no-benefits tier), $12.00 (2024q3, unified; constant after).
  - DC: Jul 1 → $17.00 (2023q3), $17.50 (2024q3), ~$17.95 (2025q3).
  - CT: $15.00 effective 2023-06-01 (q2), then indexed Jan 1 ($15.69 2024q1, $16.35 2025q1).
  - NY: use the statewide (upstate) rate, consistent with VZ's state series; note the
    NYC/Long Island rates are higher (sub-state variation ignored, as in the paper).
- Sanity checks before proceeding: (i) plot the 50-state panel — no decreases ever
  (statutory MW never falls nominally); (ii) 2022q4→2023q1 seam: VZ value ≤ FRED value,
  jumps only in indexing states; (iii) federal floor states (TX, GA, …) flat at $7.25.

### 3.2 New event list (extends the paper's 138 events)
- Keep the original 138 events exactly as in the replication
  (`codebase/data/eventclassification.dta` and the ported equivalent).
- Candidate new events 2016q3–2024q4: every quarter a state's MW rises ≥ $0.25 (nominal).
- Apply the paper's prominence screen: share of the state's wage-earners earning below
  the new MW in the 4 quarters before the event ≥ 2% (compute from your CPS panel, as
  the dofiles do). Follow the ported logic for combining/flagging increases that occur
  in consecutive quarters (see `create_to_combine_consecutive_events_QJE.do`): in the
  indexation era nearly every treated state steps annually — treat each qualifying
  step as an event, exactly as the paper treats its own multi-step states, and let the
  small-event/other-event controls Ω absorb the rest. Require ≥ 4 quarters of post
  data (events through 2024q4); events with τ-windows truncated by 2025q4 contribute
  the τ's they have.
- Deliverable checkpoint: write `output/new_events.csv` (state, event quarter, old MW,
  new MW, nominal and real %ΔMW, bite b̄₋₁, Kaitz = new MW / state median wage at τ=−1).
  Expect roughly 100–200 new events; if you get <30 or >400 your screen is wrong — stop
  and debug against the original 138 (re-run the screen on 1979–2016 and confirm you
  reproduce ~138 before trusting the new-era list).

### 3.3 CPS wage-bin panel, 1979q1–2025q4
Rebuild (or extend, if the replication's ported builder runs) the state × $0.25-bin ×
quarter employment count panel, mirroring `state_panels_cents_new_QJE.do`:
- MORG years 1979–2024 from source 1. Hourly wage = `earnhre/100` if `paidhre==1`,
  else `earnwke/uhourse`. Drop imputed wages: 1979–88 & Sep 1995 onward = positive
  allocation flags (`I25a` for hourly, `I25b/c/d` weekly/hours; follow the ported
  Hirsch–Schumacher logic); 1989–93 = "unedited missing but edited positive".
  Exclude Jan 1994–Aug 1995 entirely (no reliable imputation flags — the paper drops
  1994q1–1995q3 from the estimation sample).
- 2025 from source 2 (this replicates NBER's MORG extract): keep `hrmis ∈ {4,8}`,
  `prtage ≥ 16`, earnings-eligible `prerelg==1`; hourly workers `peernhry==1` →
  wage = `pternhly/100`; others → `pternwa/100` ÷ `pehruslt` (usual hours; drop if
  hours vary/missing, mirroring the MORG rule); drop allocated earnings
  (`prhernal==1` for hourly, `prwernal==1` for weekly); ORG weight = `pworwgt/10000`;
  state fips = `gestfips`; employment status `pemlr ∈ {1,2}`.
  **Seam validation (mandatory):** also build 2024 from the Census monthly files and
  compare state×quarter counts of jobs under $15 (2016$) against the MORG-built 2024;
  correlation must be ≥ 0.98 and aggregate within ±3%; otherwise use MORG for 2024
  (always) and flag the 2025 level shift in the findings note (the event-study FEs
  ρ_jt absorb a pure level seam, but report it).
- Deflate to **2016 dollars** with CPI-U-RS spliced per source 5 (keep the paper's
  base year so all magnitudes are directly comparable). Bins: [0,1.25), then $0.25
  bins to $30, top bin $30+, i.e. the paper's 117 bins. Note in the findings that by
  2025 more mass sits in the $30+ bin (real wage growth); this bin is outside every
  event's [MW−4, MW+17] window, so it only matters for the falsification tail.
- Counts E_sjt = Σ earnwt/3 within state×bin×quarter (per the dofiles); population
  N_st (16+) from CPS final weights as the ported code does. Balance the panel with
  zeros (`state_panels_cents_balanced_QJE.do` logic).

## 4. Estimation

Baseline = paper's eq. (1), the specification behind Fig. II/III and Table I col 1:
E_sjt/N_st on treatment dummies I(τ,k), τ=−3..4 × k=−4..+17 ($1 aggregates of the
$0.25 bins relative to the new MW), state×bin FE μ_sj, quarter×bin FE ρ_jt, plus the
paper's Ω controls ({BELOW,ABOVE}×{EARLY,PRE,POST} for federal and for small events).
Cluster by state. Use the ported estimation code if the replication produced it;
otherwise `pyfixest.feols` (or R `fixest::feols`) — ~1.1M rows (117 bins × 51 states ×
~184 quarters), FE dims ≈ 6k + 21.5k: minutes on this box. Weight and normalize
exactly as the ported Fig. II code does.

**Windows (the flagship dimension).** Split events into five calendar cohorts by
event date, and estimate all treatment dummies interacted with cohort in ONE
regression (shared FEs and controls):
- W1: 1979q1–1994q4  (early era; federal-dominated variation, few state events)
- W2: 1995q1–2007q4  (new-MW-research era)
- W3: 2008q1–2015q4  (Great Recession + recovery)
- W4: 2016q1–2019q4  ($15-era ramp-up begins; last window overlapping the paper)
- W5: 2020q1–2024q4  (COVID + tight low-wage labor market + inflation era; NEW)
Also estimate: (a) pooled original replication sample (events 1979–2016) as the
anchor — this should reproduce the replication's numbers (Δa≈.021, Δb≈−.018,
%Δe≈+2.8%); if it does not, stop and reconcile before running anything else; and
(b) pooled all-events 1979–2024 ("the finding today").

**Per window, compute** (formulas in paper §II.B, ported in `create_programs.do`):
Δb (missing below), Δa (excess at/above, W̄=MW+4), b̄₋₁ (bite), %Δ affected
employment = (Δa+Δb)/b̄₋₁, %Δ affected wage via eq. (2) (Δwb from the same
coefficients), own-wage elasticity OWE = %Δe/%Δw, and real %ΔMW. SEs: delta method
as in the paper if the ported code has it; otherwise block bootstrap over states
(200 reps — cheap at this scale); label which you used.

**C3 (bite) check:** among W4+W5 events, split by Kaitz at τ=−1 (above/below 0.5 —
new-era events reach well past the paper's 0.59 frontier) and report %Δe for each
half (one extra interacted regression). This directly tests "no disemployment up to
Kaitz ~0.59" on out-of-sample bites.

**Fallback tier (if the bin panel or full regression fails):** the paper's own
"simpler method" (Table I last column): state×quarter panel, outcomes = per-capita
jobs paying below MW+$4 (in 2016$) and total wage bill below that cutoff; same event
dummies and controls. It reproduces the paper's %Δe and %Δw closely and is 100× lighter.
Use it rather than shipping nothing; label the method in every output.

## 5. Outputs (write to `output/`)

1. `estimates_by_window.csv` — tidy: one row per (window × method), columns:
   `window, period, n_events, mean_real_dmw_pct, bite, kaitz_mean, delta_a, delta_a_se,
   delta_b, delta_b_se, pct_demp, pct_demp_se, pct_dwage, pct_dwage_se, owe, owe_se,
   method, notes`. Include rows for the anchor replication (1979–2016) and pooled
   1979–2024, and the paper's published numbers as a `method="paper_published"` row.
2. `living_estimate.png` + `.pdf` — the flagship figure, three stacked panels sharing
   the x-axis (event-cohort time, W1..W5 at cohort midpoints, x from 1979 to 2025):
   - Panel A: %Δ affected employment, point + 95% CI per window; horizontal dashed
     line at +0.028 with a shaded ±1.96×0.029 band labeled "CDLZ (2019) pooled,
     1979–2016"; light shading over 1979–2016 labeled "original sample". A zero line.
   - Panel B: %Δ affected wage per window, same style, dashed line at +0.068.
   - Panel C: Δa (blue) and Δb (red) per window with CIs — the bunching signature
     itself (readers see missing≈excess in every era, or where it breaks).
   Annotate W5 with mean real %ΔMW so the inflation-era caveat is visible.
3. `figure2_new_era.png` — Fig. II analog (bin-by-bin employment changes, k=−4..17)
   for pooled W4+W5 events next to the original replication's Fig. II, same axes.
4. `findings.md` — ≤2 pages: the three claims, original vs today's numbers, the
   Kaitz split, data/method caveats (2025 seam, CPI splice, mid-year MW dating for
   FL/OR/NV/DC/CT, QCEW skipped, truncated post-windows for 2022+ events), and a
   one-paragraph verdict on whether the finding held, strengthened, faded, or reversed.

## 6. Failure playbook

- NBER MORG down → mirror at `https://www.nber.org/morg/annual/` (same files); if both
  fail, this is fatal for pre-2016 rebuild — but the replication's already-built panel
  covers 1979–2016, so fall back to *extending* it with Census monthly 2016–2025 only.
- Census 2025 CSVs fail → end the panel at 2024q4; drop nothing else (W5 events keep
  their truncated windows).
- `FRED_API_KEY` invalid → CPI via BLS API (already keyless); MW 2023–2025 from the
  embedded schedule in §3.1 alone, flagged `access=manual-curated` in the note.
- VZ zip gone → `mw_state_quarterly` is also on the repo master branch
  (`https://github.com/benzipperer/historicalminwage`, `release/` dir) — clone it.
- Any single state's MW series looks wrong → drop that state's NEW events (keep it as
  control with its Ω dummies) and list it in the findings note; never silently impute.
- Running out of time → priority order: anchor reproduction → pooled 1979–2024 →
  W4+W5 vs original (this is the minimum publishable update) → full five windows →
  Kaitz split → Fig. II analog.