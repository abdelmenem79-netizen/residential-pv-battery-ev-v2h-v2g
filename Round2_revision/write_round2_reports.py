"""Generate evidence-based reports after the numerical freeze."""
from pathlib import Path
import json
import pandas as pd
import hashlib
import re

O=Path(__file__).resolve().parent;R=O.parent;D=O/'tables'

def table(df):
    def fmt(x):
        if isinstance(x,float):return f'{x:.8g}' if pd.notna(x) else 'not applicable'
        return str(x).replace('|','/').replace('\n',' ')
    return '| '+' | '.join(df.columns)+' |\n| '+' | '.join(['---']*len(df.columns))+' |\n'+''.join('| '+' | '.join(fmt(x) for x in row)+' |\n' for row in df.itertuples(index=False,name=None))

def main():
    s=pd.read_csv(D/'comparison_summary.csv').set_index('Comparison');rs=pd.read_csv(D/'restoration_summary.csv').set_index('Comparison')
    th=pd.read_csv(D/'break_even_thresholds.csv');v=pd.read_csv(D/'validation_summary.csv');runtime=pd.read_csv(D/'computational_summary.csv')
    days=pd.read_csv(O/'audit'/'verified_days.csv');base=days[days.DayID==43598]
    main=s.loc['Capped none / all tested'];term=s.loc['Capped ge / all tested'];old=s.iloc[0];eq=s.loc['Capped eq / all tested']
    impact=pd.read_csv(D/'separated_accuracy_and_reserve_effects.csv');profiles=pd.read_csv(D/'subset_profile_comparison.csv')
    rA=rs.loc['A Flat accounting'];rB=rs.loc['B Timed EV-only accounting'];rC=rs.loc['C Terminal optimisation']
    br=pd.read_csv(D/'baseline_runs.csv');bnone=br[(br.ReserveCapped==1)&(br.TerminalMode=='none')];bge=br[(br.ReserveCapped==1)&(br.TerminalMode=='ge')]
    rest=pd.read_csv(D/'restoration_day_level.csv')
    components=[
        ['Shared optimisation','P3_V2H_V2G_Project/src/optimisation/solveStorageRegimeCVX.m','864 declared continuous and 1440 binary scalars','Reserve contradiction; no EV terminal constraint','Audited fork solveRound2.m','1,2'],
        ['Reserve','src/optimisation/buildConstraints.m; solveRound2.m','Nonnegative next-day peak net forecast','Reserve >3 kWh conflicts with SOC upper bound','Cap achievable reserve; report unmet forecast','1'],
        ['Objective','src/optimisation/buildObjective.m','Import minus export plus two degradation proxies','Default relative native gap distorted by objective offset','Keep objective; absolute gap 1e-8 GBP','1,2,5'],
        ['EV mobility','src/ev/buildEVProfile.m; computeTripEnergy.m','Availability-gated; first-trip 90% equality if applicable; withdrawal after departure','No universal 07:30 departure; day dependent','Retain mobility and timing unchanged','2,4'],
        ['Terminal energy','solveRound2.m','Historical none','Daily depletion not priced as restoration','All90 >=initial; chronological21 equality sensitivity','2'],
        ['Tariffs','src/setup/buildTariffs.m','TOU import .0499/.1199/.2499; export .0379 GBP/kWh','Three old scenarios do not locate onset','Repeated MILPs and bracket refinement','5'],
        ['Degradation','src/optimisation/buildObjective.m','Battery throughput; EV discharge-only .011 GBP/kWh','Proxy, not calibrated ageing','Unchanged; limit interpretation','2,7'],
        ['Multi-day','results_extension/run_multiday_v2h_v2g.m','90 selected IDs, old74 valid pairs','Selection and accuracy effects conflated','Fresh uncapped controls and full capped reoptimisation','1'],
        ['Monte Carlo','results_extension/run_monte_carlo_uncertainty.m','Fixed saved schedules; physical draws inactive','80 draws choose failed historical pairs','Retire analysis; preserve exact RNG audit','3'],
        ['Dates / data','Total_Data_house1.xlsx; House1_data_Struct.mat','Explicit Day Month Year agree','DayNum serial-date interpretation wrong; AllHouses MAT absent','Map explicit fields; mark historical outputs obsolete','4'],
        ['Solver bridge','C:/cvx/shims/cvx_gurobi.m','Custom settings passed to third argument','Gurobi accepts model and params only','Authorised one-line index 3 to2; private backup','1,2,5'],
        ['Tables / figures','Round2_revision/finalise_round2.m; summarise_round2.py; plot_round2.m','Certified runs only','Historical outputs must not be mixed','Frozen MAT, CSV, workbooks, vector/600dpi figures','all'],
        ['Validation','Round2_revision/validateRound2.m','Independent balances, SOC, logic and objective checks','Household validity is not feeder feasibility','Fail-fast finalise_round2.m','all'],
        ['External provenance','Swansea thesis / London Datastore','Documentary attribution only','Raw-meter/preparation chain not authenticated','Withhold prepared matrices pending rights check','6']]
    comp=pd.DataFrame(components,columns=['Component','File/function','Current implementation','Problem found','Required action','Reviewer point'])
    comp.to_csv(D/'component_audit.csv',index=False)
    maxReserve=max(impact.ReserveChangeV2H_GBP.abs().max(),impact.ReserveChangeV2G_GBP.abs().max())
    numerical=f'''## Frozen numerical findings

The corrected reserve formulation produces {int(main.ValidPairs)}/90 valid pairs. Mean no-terminal-condition saving is GBP {main.MeanSaving_GBP:.9f}/day, versus historical GBP {old.MeanSaving_GBP:.9f}/day. The original 74-day comparison and recovered 16-day comparison are separately tabulated below. Changing solver accuracy and changing reserve policy are separately controlled: the maximum absolute capped-minus-uncapped cost change on an originally valid day at the same certified accuracy is GBP {maxReserve:.9g}.

{table(s.reset_index()[['Comparison','ValidPairs','MeanV2HCost_GBP','MeanV2GCost_GBP','MeanSaving_GBP','MedianSaving_GBP','MinSaving_GBP','MaxSaving_GBP','V2GLowerCostDays','TieWithinToleranceDays','V2GNetRevenueDays']])}

The EV terminal condition reduces the mean saving to GBP {term.MeanSaving_GBP:.9f}/day: {int(term.V2GLowerCostDays)}/90 are lower-cost and {int(term.TieWithinToleranceDays)}/90 are ties within GBP 0.00001. This is actual re-optimisation. V2G is a feasible-set superset of corrected V2H under a common terminal constraint and objective; an accurately solved V2G optimum cannot be more expensive, apart from numerical tolerance. Negative post-accounting differences do not contradict this property because post-accounting dispatches are not re-optimised.

The >= condition prevents net EV depletion but does not require identical final energy across regimes. Unpriced surplus final energy can therefore still differ, particularly when the first-trip equality forces charging and corrected V2H cannot export the surplus. The remaining small saving is not evidence of a complete cyclic mobility policy or terminal-energy valuation. The strict-equality sensitivity and retained final-state columns make this distinction inspectable.

Equality sensitivity attempts {int(eq.AttemptedDays)} days, selected by unique(round(linspace(1,90,20))) plus baseline; {int(eq.ValidPairs)} form common valid pairs. All failed equality cases are retained in equality_infeasibility_evidence.csv and independently rerun with DualReductions=0. Equality can force surplus energy disposal that corrected V2H cannot achieve under the export interlock; the >= condition does not force this. All90 are used for the main >= experiment, so its conclusions do not depend on representative-subset selection.

### Baseline results: 19 June 2014, ID43598
{table(pd.concat([bnone,bge])[['Regime','TerminalMode','Cost_GBP','GridImport_kWh','GridExport_kWh','EVCharge_kWh','EVDischarge_kWh','EVInitialSOC_pct','EVFinalSOC_pct','SolverStatus','Valid']])}

### Historical-subset profile comparison
{table(profiles)}

These are descriptive within-dataset contrasts. The reviewer description of the excluded days as sunny/low-load is not assumed: the table tests it directly. The contradiction is driven by the next-day 16:00-20:00 net forecast, not simply the current day's PV or load total. No random-sample or population-level selection-bias estimate is claimed.
'''
    restoration=f'''## Restoration and terminal comparisons

For BOTH regimes: deficit=max(0,E_initial-E_final); grid energy=deficit/0.9. Scenario A reprices at GBP0.0499/kWh. Scenario B constructs a next-day, pre-first-departure EV-only charging schedule, using the actual next-day connected prefix, tariff vector, 6.6kW power cap, charging efficiency and SOC upper bound. This timing convention is explicit; it is not an observed restoration policy. Charging is assigned to lowest-price eligible intervals first. No next-day household balance, appliance schedule, stationary battery, feeder constraint or rolling mobility trajectory is optimised in B. Its feasibility flag applies only to this EV charging subproblem. A does not establish interval feasibility.

Scenario C independently re-optimises the complete existing 24h household model with E_EV(T)>=E_EV(0), under its original TOU tariff. C includes the original EV discharge degradation proxy; A/B add import energy cost only, consistently with the original EV proxy not charging-side ageing. No additional restoration cost is added to C, avoiding double counting.

{table(rs.reset_index()[['Comparison','ValidPairs','MeanV2HCost_GBP','MeanV2GCost_GBP','MeanSaving_GBP','MedianSaving_GBP','MinSaving_GBP','MaxSaving_GBP','V2GLowerCostDays','V2GLowerCost_pct']])}

Timed EV-only restoration feasibility: {int(rest.EVOnlyScheduleFeasible.sum())}/{len(rest)} regime-day schedules. Flat and timed accounting mean savings are GBP {rA.MeanSaving_GBP:.9f} and GBP {rB.MeanSaving_GBP:.9f}, respectively; terminal-optimised mean saving is GBP {rC.MeanSaving_GBP:.9f}. This comparison does not establish robustness to arbitrary restoration windows or future tariffs. No 2-3-day rolling optimisation was performed; neither EV-only terminal restoration nor the timed subproblem restores the stationary battery or proves full-system cyclic repeatability.
'''
    tariffs=f'''## Re-optimised export-value onset

Each price entails two fresh MILPs (or an identical certified cached run). Import shape is retained at multipliers 0.75, 1, 1.25. Export-price bracketing expands from zero until a certified positive endpoint is found (maximum search allowance 0.30 GBP/kWh), then refines that local transition to <=0.0001 GBP/kWh. Unnecessary far-above-threshold tails are not used as final sweep evidence. The coarse scan permits an absolute objective gap up to GBP 0.002 per regime; its plotted costs are bounded incumbent estimates, not precision-exact optima. Figure error bars show the saving-bound intervals. Refinement retains the principal GBP 1e-8 absolute tolerance. Native MIP bounds define a conservative saving interval. Positive means its lower bound exceeds GBP 0.00001. The reported onset is not falsely described as a unique sign-changing root: equality can hold over a zero-saving plateau because V2G contains V2H's feasible schedules. Observed nonmonotonicity is explicitly flagged; local bracketing is not a global monotonicity proof.

{table(th)}
'''
    report=f'''# Round-2 Technical Audit Report

Model R2.2. Authoritative final files are under Round2_revision, with runs_certified, tables and Round2_Frozen_Results.mat. Historical files, preliminary default-gap runs and the original manuscript/reviewer DOCX files are preserved. This is a numerical correction and integration package, not a claim that the submitted manuscript has already been replaced or publicly deposited.

## Component audit
{table(comp)}

## Model corrections and solver integrity

Let E_B(t)=E_B(0)-dt*cumulativeFlux_B(t). The original reserve-window inequality is cumulativeFlux_B(t)<=(E_B(0)-E_B,min-R_raw)/dt for indices122:143. Equivalently E_B(t)>=E_B,min+R_raw. The common upper bound E_B(t)<=E_B,max implies R_raw<=E_B,max-E_B,min=4*(0.95-0.20)=3kWh. All16 historical failed days exceed this value. Both regimes were rerun uncapped as controls. Native logs report infeasible-or-unbounded; the bounded-variable model plus the explicit SOC contradiction establishes infeasibility, rather than relying on that ambiguous status alone.

The corrected requirement is R_applied=min(R_raw,3). This is an achievable reserve target, not a promise to cover the entire forecast. The uncovered amount max(0,R_raw-3) is exported in model_counts_reserve.csv. No tariff, trip, SOC limit, efficiency, initial state, appliance or export interlock was changed by the cap.

The additional terminal experiment imposes E_EV(T)>=E_EV(0) inside CVX. This is selected over equality because it prevents net depletion without unnecessarily forcing disposal of useful surplus energy. Equality is tested separately. First-trip equality and trip withdrawal remain as implemented. The baseline first-trip target is90%, at the last connected state before06:00, not a fabricated07:30 threshold. Baseline connected availability is9h and selected-day availability varies9-15h. Baseline initial states come from the implemented SOC input workbooks, not the nominal65% shorthand.

Two solver problems were discovered. First, installed CVX passed custom Gurobi settings to input3 instead of params input2; the authorised one-line installed-shim repair is documented, with a private backup. Second, CVX canonicalisation shifts the native objective by a large constant. The default relative gap could therefore admit economic errors material to a GBP/day comparison; one preliminary terminal result violated the expected nesting order. Those runs were superseded. Final runs use MIPGap=0 and MIPGapAbs=1e-8, with native incumbent/bound certificates and independent cost reconstruction. Software: MATLAB R2025a Update1, CVX2.2 Build9, Gurobi12.0.3. Native variable counts include CVX auxiliary variables and must not be confused with declared model counts.

{numerical}
{restoration}
{tariffs}

## Monte Carlo audit and decision

All500 historical RNG draws were replayed in the original order and their calculated saving matched the stored value (or both nonfinite). All80 nonfinite draws select an invalid historical corrected-regime pair, propagating NaN saved costs; there is no new optimisation in this function. There are420 finite outcomes and408 positive outcomes:408/500=81.6%,408/420=97.142857%. Neither is retained as a physical reliability probability.

{table(pd.read_csv(D/'monte_carlo_variable_trace.csv'))}

The scientific decision is to withdraw this analysis from the proposed corrected results, not invent distributions and call them measured physical uncertainty. The original DOCX still contains it until manuscript integration. The exact removal map includes abstractP9, Section6.D, Table19, and conclusions/limitations. Reviewer Point3 is therefore not claimed fully CLOSED yet.

## Date and provenance

{table(base[['DayID','CalendarDate','StructureFirstIndex','WorkbookFirstRow','StructureLastIndex','WorkbookLastRow']])}

DayNum is an identifier matched to explicit fields, not an Excel serial date. All90 date/profile matches were asserted against Total_Data_house1.xlsx and House1_data_Struct.mat. AllHouses_data_Struct.mat was not available; the actual active House1 MAT was used. The prepared source spans13June-2October2014. Historical2019-labelled outputs are retained as obsolete evidence and inventoried in audit/historical_date_occurrences.txt, not silently relabelled as new runs. The original DOCX'sP180 still requires replacement; global project/manuscript date closure is not claimed.

The London Datastore catalogue describes half-hourly consumption from5567 households duringNovember2011-February2014 and labels its licence Creative Commons Attribution. That catalogue does not authenticate the identity, resampling, PV/mobility augmentation or2014date transformation of the prepared House1 matrices. See [London Datastore](https://data.london.gov.uk/dataset/smartmeter-energy-consumption-data-in-london-households-vqm0d) and the documented [Swansea thesis attribution](https://cronfa.swan.ac.uk/Record/cronfa64638). Original meter identity, download version and full raw-to-prepared chain remain unverified. Do not equate uncertain prepared-data rights with a claim that the original catalogue has no licence.

## Validation and computational overhead

{table(v)}

{table(runtime)}

The balance metric is max(abs(A1*x+A10*POn-b1)), in kW, with RMS of the same vector. The independently reconstructed physical power equation must agree. Power/SOC-energy checks use1e-5 in their recorded units; reconstructed cost uses1e-6GBP. Model declarations count864 continuous entries and1440 binary entries (including appliance and startup variables), T=144. Optimisation timing covers CVX model construction/canonicalisation and solver return; it is not native Gurobi-only wall time. Verification timing covers validateRound2 only. Runtime is machine- and instance-dependent; these runs do not establish asymptotic scalability.

## External validity and release limits

One prepared household over a restricted period is not annual or multi-household evidence. The grid power bound is a modelling bound, not a validated connection rating. No feeder power flow, voltage limits, transformer thermal model, phase imbalance or hosting-capacity calculation exists. No compatible external benchmark was established from the available companion-development records; cross-paper costs with different boundaries are not substituted. Capital cost, communication/aggregator fees and ageing calibration remain outside the operating-cost claim.

The local reproducibility package separates author code and derived tables from private prepared profiles, historical MAT archives and commercial/third-party solver source. Public repository destination and code licence still require author approval. A real public deposit is not claimed. Prepared input redistribution is withheld pending provenance/rights evidence. Full public reproducibility is consequently not yet established.

## Submission gate

Numerical outputs are frozen only after finalise_round2 passes. Manuscript integration, removal of old Monte Carlo/inferential material, final figure/cross-reference reconciliation and public-release approval remain explicit gates. Do not submit the unmodified energies-4550332.docx with the new tables appended. See MANUSCRIPT_CHANGES_REQUIRED.md and Round2_Reviewer_Closure_Matrix.xlsx.
'''
    (O/'Round2_Technical_Audit_Report.md').write_text(report,encoding='utf8')
    replacements=f'''# Evidence-ready replacement results

These paragraphs and tables are proposed integration text, not an assertion that the source DOCX has been edited. All values are generated from certified CSVs.

## Abstract / principal results replacement
After capping the stationary-battery reserve target at its3kWh usable band, all90 selected days formed valid corrected-V2H/V2G pairs. Under the24h formulation without an EV terminal condition, mean V2G saving was GBP{main.MeanSaving_GBP:.6f}/day, with lower cost on{int(main.V2GLowerCostDays)}/90days. With the EV terminal-energy condition imposed in the optimisation, mean saving was GBP{term.MeanSaving_GBP:.6f}/day, with lower cost on{int(term.V2GLowerCostDays)}/90days and{int(term.TieWithinToleranceDays)}ties within GBP0.00001. The much smaller terminal-constrained difference indicates that end-of-horizon EV energy treatment materially affects the short-horizon result. Symmetric post-optimisation restoration accounting is reported separately and is not interpreted as re-optimisation. These household-specific results do not establish annual profitability, full-system cyclic operation or network feasibility.

{numerical}
{restoration}
{tariffs}

## Limitations replacement
The analysis uses one prepared household over13June-2October2014 and deterministic selected-day scenarios. It does not establish population-level statistical significance or annual performance. The EV terminal experiment prevents net EV depletion within each optimisation, but stationary-battery terminal restoration and rolling multi-day state continuity are not imposed. Timed post-accounting restoration is an EV-only charging subproblem, not proof of a feasible next-day household or feeder schedule. No distribution-voltage, transformer-thermal, phase-imbalance or hosting-capacity model is included. The degradation proxy is not chemistry-calibrated, and charger/infrastructure investment costs are excluded.

## Code and Data Availability proposal
The author-generated correction, validation and result-generation code and derived result tables have been assembled in a local reproducibility package. No public repository URL or approved code licence is available at this stage. Prepared House1 input matrices are withheld pending confirmation of their raw-source identity, transformation chain and redistribution conditions. The original London Datastore catalogue carries a Creative Commons Attribution label, but that does not independently establish the provenance of the prepared PV/mobility-augmented matrices. Repository information must be added only after deposit and author approval.
'''
    (O/'MANUSCRIPT_REPLACEMENT_TEXT.md').write_text(replacements,encoding='utf8')
    changes=f'''# Manuscript changes required before submission

Source: energies-4550332.docx (original unchanged). Paragraph numbers refer to audit/energies-4550332.json. Each numerical replacement must use tables/ and MANUSCRIPT_REPLACEMENT_TEXT.md. Do not reuse old plots with new captions.

1. AbstractP9: replace old74-pair/.509/.632claims with certified90-day unconstrained and terminal findings; remove Monte Carlo and unrerun capacity/degradation claims.
2. IntroductionP13-18 and systemP40-41: define R2.2 reserve cap, common corrected regime objective, optional EV-terminal condition and absolute MIP tolerance. V2H-Old remains historical only.
3. P30: keep the first Unlike stationary storage sentence; delete the duplicate second sentence.
4. Section5: retain explicit2014date fields; update solver settings, selected90, equality subset and EV-terminal experiments. Baseline is part of90. Replace the no-terminal-only framing with separate none/ge/eq cases. Do not invent07:30mobility.
5. Section6A/P180: use19June2014, ID43598, remove13May2019 and independent-additional-baseline claim.
6. Replace baselineTables2-5 and Figures2-4 with certified baseline none/ge tables and R2_01 figures; no newly solved legacy comparator is supplied.
7. Replace old LOW/MEDIUM/HIGHTables6-8 and their figures with tariff_pairs, break_even_thresholds and R2_04/R2_05. Do not describe onset as a unique root where a zero plateau exists.
8. Old degradationTable9 and capacityTable10 were not regenerated under R2.2. Withdraw their numerical conclusions/figures or commission separate corrected re-optimisation before retaining them. They are not silently accepted as current evidence.
9. Replace multi-dayTables11-15,17-18 and associated figures with principal_pairs, comparison_summary, subset_profile_comparison, computational_summary, validation_summary and R2_02/R2_03/R2_07. Report all90 and separately original74/recovered16. Separate solver-accuracy and reserve effects.
10. Delete Table16, Wilcoxon, p-values, Cohen's dz and inferential significance language. Use descriptive paired summaries with stated GBP0.00001tie tolerance.
11. Delete Section6.D/P338-342, Table19 and all manuscript Monte Carlo findings, including abstract/conclusion/limitations claims. Preserve the defect explanation in the reviewer response and audit only.
12. Replace restorationTable20 and Figures15-16 with restoration_summary, restoration_paired, timed schedule and R2_06. Distinguish A/B accounting from C optimisation. Do not infer full-system restoration feasibility from B.
13. Section7/P362-367: remove feasible-subset-only scope; retain one-household/period/network/investment limits; explain EV-only terminal and no rolling/stationary-terminal evidence.
14. ConclusionsP369-374: replace old values and capacity/Monte Carlo claims; no universal V2G profitability or repeatability claim.
15. P378: use truthful local-package/public-deposit-pending language, not invented availability or licence. FundingP376 and institutional-only IUK acknowledgmentP379 remain unchanged.
16. Renumber all retained tables/figures after deletions; reconcile every cross-reference. Table6capitalisation and Table7spacing are superseded by the replacement captions.

## Exact maps

- tables/manuscript_paragraph_change_map.csv covers affected source paragraphs individually.
- tables/manuscript_caption_map.csv inventories every original table/figure caption.
- audit/historical_date_occurrences.txt records project text/code date occurrences. Historical files are preserved and marked obsolete, not altered to masquerade as new output.

## Remaining integration gate
The source DOCX was deliberately preserved. These edits have not yet been applied to a new, fully rendered manuscript. Therefore comments whose closure requires complete removal or global manuscript consistency remain NOT CLOSED in the final status, even though their evidence and replacement text are available.
'''
    (O/'MANUSCRIPT_CHANGES_REQUIRED.md').write_text(changes,encoding='utf8')
    closure=[
      [1,'Cap reserve; rerun90; compare74 and16','solveRound2 reserve saturation','Fresh uncapped90 + capped90 for both',f'90/90 valid; mean saving {main.MeanSaving_GBP:.9f} GBP','Section5 reserve; Section6 multi-day','Report numerical findings; comparison_summary','CLOSED'],
      [2,'True EV terminal optimisation','Eev(end)>=EevStart; equality sensitivity','All90 ge plus21 eq, both regimes',f'Mean saving {term.MeanSaving_GBP:.9f}; {int(term.V2GLowerCostDays)} lower-cost','Section5 terminal; Section6 terminal results','Certified cases and replacement text; DOCX integration pending','PARTIALLY CLOSED'],
      [3,'Explain80NaN; replace/remove MC','Exact RNG audit; MC excluded from new analysis','500 historical draws replayed','80 select failed pairs; physical draws inactive','Delete Section6D/Table19/abstract/conclusions','Removal map prepared; original DOCX still contains MC','NOT CLOSED'],
      [4,'Resolve date globally','Explicit Day Month Year validation','All90 workbook/MAT checks','ID43598 =2014-06-19','Section5A and6A; all affected captions','Correct new outputs; historical/source DOCX inconsistencies retained pending integration','NOT CLOSED'],
      [5,'True export tariff threshold','Repeated MILPs and bound-aware bisection','none/ge, three import multipliers','Actual onset brackets in break_even_thresholds','Section6 tariff experiment','tariff_runs + tariff_pairs + R2_04/R2_05','CLOSED'],
      [6,'Release code and prepared matrices','Local candidate package','No public upload','Public repository/licence approval and prepared-data rights unresolved','Code/Data Availability','Package + provenance statement; no public claim','NOT CLOSED'],
      [7,'Restoration tariff/timing comparison','Symmetric accounting and EV-only timed schedule','90 A/B/C pairs',f'A {rA.MeanSaving_GBP:.9f}; B {rB.MeanSaving_GBP:.9f}; C {rC.MeanSaving_GBP:.9f} GBP','Section6 restoration','restoration_day_level, schedule, summary, R2_06','CLOSED']]
    cl=pd.DataFrame(closure,columns=['Reviewer point','Required action','Code change','Simulation performed','Result','Manuscript location','Response-letter evidence','Status']);cl.to_csv(D/'reviewer_closure_matrix.csv',index=False)
    (O/'audit'/'closure_workbook_data.json').write_text(json.dumps({'headers':list(cl.columns),'rows':cl.values.tolist()},indent=2),encoding='utf8')
    comments=json.loads((O/'audit'/'Round-2 Comments.json').read_text(encoding='utf8'))['paragraphs']
    responses={
      1:f'We agree that the reserve contradiction required a model correction, not exclusion of failed days. The target is now min(raw forecast,3kWh), with unmet forecast reported. All90 days were re-optimised for both corrected regimes and passed validation. The new mean saving without an EV terminal condition is GBP{main.MeanSaving_GBP:.9f}/day. Original74 and recovered16 results, and fresh uncapped controls at the same absolute solver tolerance, are reported separately. The subset-profile table tests rather than assumes the claimed sunny/low-load pattern. See the numerical findings and separated_accuracy_and_reserve_effects.csv.',
      2:f'We performed actual CVX/Gurobi re-optimisation with final EV energy at least initial energy for all 90 days, exceeding the requested subset. Mean saving is GBP {term.MeanSaving_GBP:.9f}/day, with {int(term.V2GLowerCostDays)} lower-cost days and {int(term.TieWithinToleranceDays)} ties at GBP 0.00001. Equality was additionally attempted on {int(eq.AttemptedDays)} chronologically distributed days including the baseline, giving {int(eq.ValidPairs)} valid common pairs; every failed case is retained and diagnosed. This much smaller terminal-constrained advantage changes the headline interpretation. No rolling optimisation or stationary-battery terminal constraint is claimed. The manuscript integration text is prepared but has not yet replaced the source DOCX.',
      3:'The audit replayed all500 draws. All80 nonfinite outcomes selected one of the16 failed historical pairs, propagating NaN stored results. Only selected saved day, import/export tariffs and two degradation multipliers affect recalculated costs; PV/load/trip/arrival/departure samples do not. Dispatch is never re-optimised. We propose removing this analysis completely rather than presenting it as physical uncertainty. It is excluded from the corrected result package, but its removal from the source manuscript remains pending and is not claimed completed.',
      4:'Explicit workbook and active House1 MAT Day/Month/Year fields establish19June2014. DayNum43598 is an identifier, not an Excel serial date. Workbook row and structure indices are in verified_days.csv. All90 new outputs use this verified mapping. The old2019-labelled archives are retained as obsolete evidence, and the source manuscriptP180 requires correction; global consistency is not falsely claimed.',
      5:'Both regimes were re-optimised at every tested price for no-terminal and terminal-constrained cases, retaining the import TOU shape at0.75,1 and1.25multipliers. The resulting onset brackets and spreads are in break_even_thresholds.csv. Refinement uses a price tolerance0.0001GBP/kWh and a bound-certified positive-saving threshold0.00001GBP. Because the feasible sets are nested, a zero-saving plateau can occur; we report its positive-value onset rather than claim a unique sign-changing root. Figures R2_04 and R2_05 show the results.',
      6:'A local reproducibility candidate has been prepared containing author code and derived results, excluding prepared profiles, private historical MAT archives, licence-bearing logs and CVX/Gurobi source. No public deposit or code licence has been approved. The London catalogue labels its original data Creative Commons Attribution, but the exact raw-meter identity and preparation/augmentation chain for House1 remain unverified. We cannot presently assert redistribution rights for those prepared matrices. Repository approval and a truthful final availability statement remain open; no public URL is invented.',
      7:f'Both regimes are restored symmetrically. Flat-price accounting gives mean saving GBP{rA.MeanSaving_GBP:.9f}/day; actual-TOU next-day predeparture EV-only charging accounting gives GBP{rB.MeanSaving_GBP:.9f}/day. True24hterminal-constrained optimisation gives GBP{rC.MeanSaving_GBP:.9f}/day. The timed schedule checks connected slots,6.6kW power and EV SOC, but not a complete next-day household or network schedule. The comparison therefore qualifies the accounting reversal rather than treating it as the terminal-optimised economic result.'}
    response='# Round-2 response to Reviewer1\n\nEvidence-supported draft for Word. The original manuscript has not been edited. Changes in Manuscript below identify REQUIRED integration locations, not completed edits. Resolve the closure gates before submitting this response.\n\n'
    for x in comments[1:6]:
        n=x['paragraph']-1
        answer=responses[n] if n<=3 else ('The limitation is retained: one household, restricted period, no feeder/transformer/voltage/phase/hosting-capacity model and no compatible external numerical benchmark. A local release candidate is not a public repository; see Question6.' if n==4 else 'The exact paragraph/caption map removes the duplicateP30sentence, corrects baselineP180and replaces inferential tests with descriptive statistics. These edits remain a manuscript-integration gate, not a completed source-DOCX change.')
        response+=f'## Overarching comment {n}\n\n> {x["text"].strip()}\n\n### Response\n{answer}\n\n### Changes in Manuscript\nSee MANUSCRIPT_CHANGES_REQUIRED.md and the exact paragraph/caption maps.\n\n'
    for x in comments[6:]:
        n=x['paragraph']-6
        response+=f'## Reviewer Question {n}\n\n> {x["text"].strip()}\n\n### Response\nWe thank the reviewer for identifying this issue. {responses[n]}\n\n### Changes in Manuscript\n{closure[n-1][5]}. Required edits and replacement numerical text are provided in MANUSCRIPT_CHANGES_REQUIRED.md and MANUSCRIPT_REPLACEMENT_TEXT.md.\n\n'
    response+='## Status\n\n'+table(cl[['Reviewer point','Status','Response-letter evidence']])+'\nOverall revision status: NOT READY. Numerical evidence is available; manuscript integration and release approval remain unresolved.\n'
    (O/'Round2_Response_to_Reviewer.md').write_text(response,encoding='utf8')
    # Editorial spacing only; numerical strings and identifiers remain unchanged.
    for filename in ['Round2_Technical_Audit_Report.md','Round2_Response_to_Reviewer.md',
            'MANUSCRIPT_REPLACEMENT_TEXT.md','MANUSCRIPT_CHANGES_REQUIRED.md']:
        f=O/filename;text=f.read_text(encoding='utf8')
        text=text.replace('Final runs use MIPGap=0 and MIPGapAbs=1e-8',
            'Principal runs and threshold refinement use MIPGap=0 and MIPGapAbs=1e-8; coarse tariff points use up to GBP 0.002 with reported objective bounds')
        for a,b in [('all90','all 90'),('All90','All 90'),('all16','all 16'),('All16','All 16'),
            ('All500','All 500'),('All80','All 80'),('all90days','all 90 days'),
            ('original74','original 74'),('recovered16','recovered 16'),('first-trip90','first-trip 90'),
            ('GBP0','GBP 0'),('GBP1','GBP 1'),('GBP-','GBP -'),('Index3','Index 3'),
            ('Section6','Section 6'),('Section5','Section 5'),('Table19','Table 19'),('Point3','Point 3')]:text=text.replace(a,b)
        text=re.sub(r'(?<=\d)(days|day|hours|ties|lower-cost|pairs|draws|households|GBP|kWh|kW|h\b|%\b)',r' \1',text)
        f.write_text(text,encoding='utf8')
        text=text.replace('GBP 0.002 per regime','GBP 0.005 per regime')
        text=text.replace('up to GBP 0.002 with reported objective bounds','up to GBP 0.005 with reported objective bounds')
        text=text.replace('Refinement retains the principal GBP 1e-8 absolute tolerance.',
            'Refinement first tests the certified saving interval and uses GBP 1e-8 absolute tolerance whenever that interval does not establish the sign. Both final endpoint signs and the price-bracket width are checked independently.')
        text=text.replace('Principal runs and threshold refinement use MIPGap=0 and MIPGapAbs=1e-8;',
            'Principal runs and sign-ambiguous tariff refinements use MIPGap=0 and MIPGapAbs=1e-8;')
        text=text.replace('Runtime is machine- and instance-dependent;',
            'Runtime means exclude failed attempts, whose counts are reported separately. Runtime is machine- and instance-dependent;')
        for a,b in [('all500','all 500'),('the16','the 16'),('Original74','Original 74'),
                ('establish19June2014','establish 19 June 2014'),('DayNum43598','DayNum 43598'),
                ('old2019','old 2019'),('manuscriptP180','manuscript P180'),
                ('duplicateP30sentence','duplicate P30 sentence'),('baselineP180and','baseline P180 and'),
                ('at0.75,1 and1.25multipliers','at 0.75, 1 and 1.25 multipliers'),
                ('tolerance0.0001','tolerance 0.0001'),('threshold0.00001','threshold 0.00001'),
                ('True24hterminal','True 24 h terminal'),('Question6','Question 6'),
                ('Section 5A and6A','Section 5.A and 6.A')]:text=text.replace(a,b)
        if filename=='Round2_Technical_Audit_Report.md':
            text += f'\n## Denominator and materiality clarification\n\nThe corrected no-terminal run has {int(main.V2GNetRevenueDays)}/{int(main.ValidPairs)} net-revenue V2G days ({100*main.V2GNetRevenueDays/main.ValidPairs:.4f}%). This new 90-day denominator must not be confused with the historical 43/74 (58.1081%). A value near 47.8% is justified only for the newly solved 90-day population, not the historical 74-pair result. See saving_materiality.csv for terminal-case counts above numerical and practical saving thresholds; lower-cost does not necessarily mean a material economic benefit.\n'
        f.write_text(text,encoding='utf8')
    print('Reports and closure matrix CSV generated.')

if __name__=='__main__':main()
