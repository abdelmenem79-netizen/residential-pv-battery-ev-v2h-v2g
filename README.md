# Residential PV-battery-EV scheduling: V2H and V2G

Research code, derived result tables and figures prepared for the Round 2 revision. Repository: https://github.com/abdelmenem79-netizen/residential-pv-battery-ev-v2h-v2g. The author has authorised publication without a reuse licence for now. No MIT or other reuse licence is granted by this package. Prepared input redistribution remains unverified, and those inputs are excluded.

## Authors and contacts
- A. Alrashidi: 2263535@swansea.ac.uk
- Ashraf Fahmy: a.a.fahmy@swansea.ac.uk
- Abdelmenem Abobghala: abdelmenem.abobghala@uoz.edu.ly

These names and public contact details were supplied and approved by the user. Public visibility must not be described as an open-source licence. Third-party software and data are not relicensed.

## Included
Author project MATLAB helpers, R2.2 reserve/terminal solver fork, validators, tariff and restoration experiments, figure/table scripts, parameter-only MAT configuration, selected-day identifiers, derived aggregate tables and publication figures. CSV SourceMAT paths use PROJECT_ROOT placeholders. Their corresponding private schedules are not bundled.

## Excluded
Prepared household/PV/EV profiles and their workbooks; historical private schedule MAT archives; newly solved MAT files containing those profiles; interval restoration schedules; proprietary CVX/Gurobi source and binaries; installed solver logs containing licence identifiers. There is no synthetic-data fallback.

## Prerequisites
MATLAB R2025a (tested Update1), CVX2.2 Build9, Gurobi12.0.3 with a valid licence. Obtain authorised prepared files House1_data_Struct.mat, Total_Data_house1.xlsx, SOCFinal.xlsx and SOCFinalEV.xlsx and place them in private_inputs at this package root. These exact files are necessary to rerun; this candidate alone does not establish public end-to-end reproducibility.

The installed CVX shim used in the audited environment had `cvx_run_solver(@gurobi,prob,params,'res',settings,3)`. Its custom-setting argument must target params input2, not input3. Check your installed shim/version; obtain authorisation and back it up before applying the one-line correction. Proprietary source is intentionally not copied here. Default relative MIP tolerance is not an acceptable substitute: the CVX objective offset can make it economically loose.

## MATLAB rerun from package root
```
addpath('Round2_revision');
run_round2_principal;
audit_equality_failures;
run_round2_restoration;
run_round2_tariffs;
finalise_round2;
plot_round2;
```
Principal runs preserve uncapped infeasible controls and strict-equality failures. The main capped none/ge cases must pass all90days. Use a fresh output directory for new solver versions; do not reuse cache entries from a changed model/configuration.

Run `python Round2_revision/summarise_round2.py --numerical-only` after the MATLAB stage with Python, pandas and numpy. This mode does not require the private source-DOCX extraction JSONs or rg. Full report-generation scripts additionally expect those private document-audit files. Excel packaging uses the @oai/artifact-tool library in the authoring environment; CSV/MAT and MATLAB figures are the portable authoritative numerical outputs. No dependency on Excel is required for solving or validation.

## Figures and tables
plot_round2 creates8figures: two baselineEV panels (none/ge), daily costs, daily savings, tariff curves, tariff-onset brackets, restoration comparison and cost decomposition. Each has vectorPDF and600dpiPNG. CSV table names identify the corresponding experiment. comparison_summary separates historical74, certified uncapped74, capped90, original74and recovered16. restoration_summary separates A/B accounting from C optimisation.

No rolling horizon, stationary-battery terminal restoration, network feasibility or universal V2G profitability is claimed. Historic Monte Carlo results are audit-only and are not a physical uncertainty analysis. The conservative manuscript revision is maintained separately and is not included in this package. Publication of this package is not a new optimisation run.
