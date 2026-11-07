# The Effect of Minimum Wages on Low-Wage Jobs (Cengiz, Dube, Lindner and Zipperer, QJE 2019)

This repository holds the working directory of an automated replication and
extension of the paper, produced by [SAI](https://sai.science) agents. It is
the same file tree a signed-in user can browse in the run's workspace, and it
backs the public living-paper page:

**https://livingscience.ai/econ/living-minimum-wages**

## What is here

- `run/` — the replication working directory: `analyze/` (extracted claims),
  `replication/` (the ported and executed codebase), `verify/` (per-claim
  verdicts and the replication score), `report/` (the run's own report), and
  `followup/` (the extension studies: a re-estimation of the paper's main
  claims on data through 2024-2026, and a refit of the paper's model to the
  combined evidence, each with its report, result card, and figures).
- `referee_report.md` — the referee-style report synthesized from the run.
- Some large input data files are omitted; where that happened,
  `run/LARGE_FILES_OMITTED.md` lists them.

## The paper

Cengiz, D., Dube, A., Lindner, A., and Zipperer, B. (2019). The Effect of Minimum Wages on Low-Wage Jobs. Quarterly Journal of Economics 134(3), 1405-1454.

Replication materials from the paper's Harvard Dataverse deposit (doi:10.7910/DVN/TJCTC7). Files under `run/replication/codebase/` derive from those materials
(possibly modified by the replication agent) and remain under their original
authors' terms. Everything else in this repository is generated output from
the SAI pipeline.

## Caveats

Replication scores measure whether claims reproduce under our agents' effort,
not whether authors did anything wrong. Read the referee report's Notes and
the per-claim verdicts in `run/verify/verdicts.json` before quoting any
number.

## Data sources for the extension studies

The extension studies pulled fresh public data on August 23, 2026. In full:

- Current Population Survey, Merged Outgoing Rotation Group extracts, 2015 to 2024, distributed by the National Bureau of Economic Research (data.nber.org/morg).
- U.S. Census Bureau, Current Population Survey Basic Monthly public-use microdata, January to December 2025 (October 2025 is unavailable because of the federal government shutdown).
- Vaghul and Zipperer, "Historical State and Sub-State Minimum Wages," release v1.4.0 (November 2022), quarterly state series, from github.com/benzipperer/historicalminwage.
- U.S. Department of Labor, state minimum wage rate series (STTMINWG, by state), retrieved from FRED, Federal Reserve Bank of St. Louis, supplemented with legislated mid-year 2023 to 2025 increases for Florida, Oregon, Nevada, DC and Connecticut coded from state statutory schedules.
- U.S. Bureau of Labor Statistics, Quarterly Census of Employment and Wages, state total covered employment, open-data API, 2016 to 2025.
- U.S. Bureau of Labor Statistics, Consumer Price Index for All Urban Consumers (CPI-U, series CUUR0000SA0), monthly 2016 to 2025, used to extend the paper's CPI-U-RS deflator past 2016.
- The paper's own replication package (the 1979 to 2016 wage-bin panel, minimum-wage panel, CPI-U-RS deflator, QCEW benchmark and event classification files), reused as the pre-2017 backbone and for validation.

The theory update fetched no new data; it works entirely from the living update's panel.
