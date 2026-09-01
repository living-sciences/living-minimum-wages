# Follow-up: calibrated theory update

You are seeded from the completed replication of this paper. A previous follow-up
(`followup/001-living-update/` in this workspace — read its report.md, result_card.json,
and results/ CSVs first) re-estimated the paper's main claims on data through 2024-2026.
Your job is the next intellectual step: produce a CALIBRATED, UPDATED THEORY/MODEL that a
2026 version of this paper would contain — not just "did the old claims hold," but "what
model best organizes the original findings PLUS the new evidence, with parameters
calibrated to the latest data."

Requirements:
1. START from the paper's own theoretical framework (re-read the paper's model section).
   Recalibrate its structural/central parameters on the latest data (reuse 001's
   downloaded data and code wherever possible — do not re-fetch what already exists in
   followup/001-living-update/workspace or results).
2. Where 001 found the findings changed (weakened channels, regime exceptions, faded
   shocks), EXTEND or AMEND the model minimally to reconcile the original and new
   evidence. Prefer the smallest modification that fits both eras (e.g. one new
   state-dependence, one time-varying parameter, one added margin). Justify it against
   at least one alternative you considered and rejected.
3. VALIDATE the updated model quantitatively: show side-by-side calibration (paper-era
   vs 2026 parameters), and at least one out-of-sample or held-out check (e.g. fit the
   model on pre-2015 data, test on 2015-2026; or show the updated model explains an
   episode the original cannot — 2020 is often that episode).
4. Be epistemically honest and label every claim: [ESTIMATED] (from data), [CALIBRATED]
   (parameter chosen to match a moment), [PROPOSED] (theoretical suggestion consistent
   with evidence but not itself tested). Never dress speculation as estimation.
5. Deliverables under this follow-up's results/ dir:
   - theory_update.md — the written theory section, publication-quality prose: original
     model recap (brief), what the new evidence demands, the updated model, calibration
     table, validation, what the update implies going forward. This is the piece the
     user will read — write it as the "Theory, updated to 2026" section of a living paper.
   - calibration_table.csv — paper-era vs 2026 parameter values with sources/moments.
   - one figure (model fit or mechanism comparison, original vs updated, PNG+PDF).
   - result_card.json per the standard contract, metrics = key parameter shifts.
6. Keep compute modest (reuse 001 outputs; this is estimation + calibration, not a new
   data build). If a genuinely structural estimation is infeasible in-session, calibrate
   to the moments 001 already produced and say so plainly.

Paper-specific theory focus:

CDLZ 2019 has an explicit bunching framework (missing/excess jobs around the new minimum). 001 found held-but-softened: no significant job loss anywhere, but the central estimate drifted +2.8%->~0 and the $15-era window is -4.0% (se 2.4). Update: recalibrate the bunching model on the 2016-2024 events; the key theoretical object is the employment-effect-by-bite (Kaitz) function — estimate/calibrate how the labor-demand elasticity behaves as bite rises toward 0.5+, propose the minimal model (e.g. monopsony with an elasticity that declines in bite, or heterogeneous-firm exit margin) that produces "zero at moderate bite, possibly negative at high bite," and state the predicted threshold with honest uncertainty.

CRITICAL EXECUTION RULE (a previous attempt failed on this): run long estimations in the
FOREGROUND and wait for them to finish. NEVER end your turn/session to "await a background
task notification" — this session TERMINATES when you end your turn, killing your background
jobs and failing the study. If a step is slow, block on it (use generous command timeouts or
poll in a loop within your turn).

A previous attempt (followup/002-theory-update/) was killed by exactly that mistake; its
partial outputs remain in followup/002-theory-update/results/ (e.g. log_kaitz_all.txt) and
its workspace/ — inspect and REUSE anything valid instead of recomputing from scratch.