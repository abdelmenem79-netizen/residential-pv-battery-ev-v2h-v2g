"""Machine-generated summaries from certified CSVs, not manually typed results."""
from pathlib import Path
import csv
import hashlib
import json
import math
import re
import subprocess
import sys
import pandas as pd
import numpy as np

O = Path(__file__).resolve().parent
R = O.parent
D = O / 'tables'

def read(name):
    return pd.read_csv(D / name)

def save(frame, name):
    frame.to_csv(D / name, index=False, float_format='%.12g')

def truth(s):
    return s.astype(str).str.lower().isin(['1', 'true'])

def summary(label, h, g, attempted=None):
    h=np.asarray(h, dtype=float);g=np.asarray(g, dtype=float)
    finite=np.isfinite(h)&np.isfinite(g);s=h[finite]-g[finite]
    n=len(s);assert n
    return dict(Comparison=label,AttemptedDays=attempted or len(h),ValidPairs=n,
        FailedPairs=(attempted or len(h))-n,MeanV2HCost_GBP=h[finite].mean(),
        MeanV2GCost_GBP=g[finite].mean(),MeanSaving_GBP=s.mean(),
        MedianSaving_GBP=np.median(s),MinSaving_GBP=s.min(),MaxSaving_GBP=s.max(),
        Q25Saving_GBP=np.quantile(s,.25),Q75Saving_GBP=np.quantile(s,.75),
        V2GLowerCostDays=int((s>1e-5).sum()),V2GLowerCost_pct=100*(s>1e-5).mean(),
        TieWithinToleranceDays=int((np.abs(s)<=1e-5).sum()),
        V2HLowerCostDays=int((s < -1e-5).sum()),
        V2GNetRevenueDays=int((g[finite]<-1e-5).sum()),SavingTolerance_GBP=1e-5)

def main():
    runs=read('certified_principal_runs.csv');pairs=read('principal_pairs.csv')
    dayfile=O/'audit'/'verified_days.csv'
    if not dayfile.exists():dayfile=O/'selected_days.csv'
    days=pd.read_csv(dayfile);oldmask=truth(days.OldValidPair)
    summaries=[summary('Historical saved default solver / original 74',
        days.OldV2HCost_GBP,days.OldV2GCost_GBP,90)]
    u=runs[runs.CaseID.str.startswith('uncapped_')]
    hu=u[u.Regime=='V2H'].set_index('DayID').reindex(days.DayID)
    gu=u[u.Regime=='V2G'].set_index('DayID').reindex(days.DayID)
    summaries.append(summary('Fresh uncapped certified solver / original 74',hu.Cost_GBP,gu.Cost_GBP,90))
    for mode in ['none','ge','eq']:
        p=pairs[pairs.TerminalMode==mode]
        summaries.append(summary('Capped '+mode+' / all tested',p.V2HCost_GBP,p.V2GCost_GBP))
        if mode!='eq':
            for old,label in [(True,'original 74'),(False,'recovered 16')]:
                a=p[truth(p.OldValidPair)==old]
                summaries.append(summary('Capped '+mode+' / '+label,a.V2HCost_GBP,a.V2GCost_GBP))
    s=pd.DataFrame(summaries);save(s,'comparison_summary.csv')
    materiality=[]
    for mode in ['none','ge','eq']:
        x=pairs[pairs.TerminalMode==mode].Saving_GBP.dropna()
        for threshold in [1e-5,1e-4,1e-3,.01]:
            materiality.append(dict(TerminalMode=mode,ValidPairs=len(x),SavingThreshold_GBP=threshold,
                DaysAboveThreshold=int((x>threshold).sum()),PercentAboveThreshold=100*(x>threshold).mean()))
    save(pd.DataFrame(materiality),'saving_materiality.csv')
    p=pairs[pairs.TerminalMode=='none'].set_index('DayID')
    impact=days[['DayID','CalendarDate','OldValidPair','OldV2HCost_GBP','OldV2GCost_GBP']].copy()
    for reg,control,col in [('V2H',hu,'OldV2HCost_GBP'),('V2G',gu,'OldV2GCost_GBP')]:
        impact['CertifiedUncapped'+reg]=impact.DayID.map(control.Cost_GBP)
        impact['CertifiedCapped'+reg]=impact.DayID.map(p[reg+'Cost_GBP'])
        impact['AccuracyChange'+reg+'_GBP']=impact['CertifiedUncapped'+reg]-impact[col]
        impact['ReserveChange'+reg+'_GBP']=impact['CertifiedCapped'+reg]-impact['CertifiedUncapped'+reg]
    save(impact,'separated_accuracy_and_reserve_effects.csv')
    # Descriptive profile comparisons, not population-level inference.
    groups=[]
    for mask,label in [(oldmask,'Original 74'),(~oldmask,'Recovered 16')]:
        for field in ['Load_kWh','PV_kWh','Trip_kWh','Connected_h','RawReserve_kWh']:
            x=days.loc[mask,field]
            groups.append(dict(Group=label,Variable=field,Days=len(x),Mean=x.mean(),Median=x.median(),Min=x.min(),Max=x.max()))
    save(pd.DataFrame(groups),'subset_profile_comparison.csv')
    rest=read('restoration_day_level.csv');h=rest[rest.Regime=='V2H'].set_index('DayID');g=rest[rest.Regime=='V2G'].set_index('DayID')
    rs=[];rd=days[['DayID','CalendarDate','OldValidPair']].copy()
    scenarios=[('Unconstrained','UnconstrainedCost_GBP'),('A Flat accounting','FlatAdjustedCost_GBP'),
        ('B Timed EV-only accounting','TOUAdjustedCost_GBP'),('C Terminal optimisation','TerminalOptimisedCost_GBP')]
    for i,(label,col) in enumerate(scenarios):
        rs.append(summary(label,h[col],g[col]))
        mask=h.index.isin(days.loc[oldmask,'DayID'])
        rs.append(summary(label+' / original 74',h.loc[mask,col],g.loc[mask,col]))
        rs.append(summary(label+' / baseline',h.loc[[43598],col],g.loc[[43598],col]))
        rd[f'V2H_{i}_GBP']=rd.DayID.map(h[col]);rd[f'V2G_{i}_GBP']=rd.DayID.map(g[col])
        rd[f'Saving_{i}_GBP']=rd[f'V2H_{i}_GBP']-rd[f'V2G_{i}_GBP']
    save(pd.DataFrame(rs),'restoration_summary.csv');save(rd,'restoration_paired.csv')
    tariff=read('tariff_runs.csv');validruns=pd.concat([runs[truth(runs.Valid)],tariff],ignore_index=True)
    assert truth(tariff.Valid).all()
    vf=[]
    for key,threshold in [('BalanceMax_kW',1e-5),('GridSimultaneity_kW',1e-5),('EVChargeAway_kW',1e-5),
            ('EVDischargeAway_kW',1e-5),('CostError_GBP',1e-6),('FirstTripError_kWh',1e-5),
            ('TerminalViolation_kWh',1e-5)]:
        x=validruns[key];assert np.isfinite(x).all()
        vf.append(dict(Check=key,MaxObserved=x.max(),Tolerance=threshold,Pass=bool((x<=threshold).all()),Runs=len(x)))
    for frame,label,threshold in [(runs[truth(runs.Valid)],'PrincipalAbsoluteMIPGap_GBP',2e-8),
            (tariff,'TariffMaxAbsoluteMIPGap_GBP',.00500001)]:
        vf.append(dict(Check=label,MaxObserved=frame.AbsoluteMIPGap_GBP.max(),Tolerance=threshold,
            Pass=bool((frame.AbsoluteMIPGap_GBP<=threshold).all()),Runs=len(frame)))
    save(pd.DataFrame(vf),'validation_summary.csv')
    checks=read('validation_checks.csv');assert truth(checks.Pass).all()
    checkgroup=checks.groupby('Check').agg(Checks=('Pass','size'),Passed=('Pass',lambda x:truth(x).sum())).reset_index()
    checkgroup['Failed']=checkgroup.Checks-checkgroup.Passed;save(checkgroup,'validation_check_counts.csv')
    counts=read('model_counts_reserve.csv');runtime=[]
    for mode in ['none','ge','eq']:
        for reg in ['V2H','V2G']:
            a=runs[truth(runs.ReserveCapped)&(runs.TerminalMode==mode)&(runs.Regime==reg)]
            c=counts[counts.CaseID.isin(a.CaseID)]
            runtime.append(dict(TerminalMode=mode,Regime=reg,AttemptedRuns=len(a),ValidRuns=int(truth(a.Valid).sum()),
                FailedRuns=int((~truth(a.Valid)).sum()),T=int(c.TimeSteps.iloc[0]),
                ContinuousVariables=int(c.ContinuousVariables.iloc[0]),BinaryVariables=int(c.BinaryVariables.iloc[0]),
                MeanOptimisation_s=a.OptimisationTime_s.mean(),MaxOptimisation_s=a.OptimisationTime_s.max(),
                MeanVerification_s=a.VerificationTime_s.mean(),MaxAbsResidual_kW=a.BalanceMax_kW.max(),
                MaxRMSResidual_kW=a.BalanceRMS_kW.max()))
    save(pd.DataFrame(runtime),'computational_summary.csv')
    trace=[]
    for var,active,notes in [('day choice',True,'Selects stored pair; recovered by RNG replay'),
        ('import tariff',True,'Reprices stored grid import'),('export tariff',True,'Reprices stored grid export'),
        ('EV degradation multiplier',True,'Scales stored EV cost'),('battery degradation multiplier',True,'Scales stored battery cost'),
        ('PV',False,'Generated but not used by recalcCost'),('load',False,'Generated but not used by recalcCost'),
        ('trip',False,'Generated but not used by recalcCost'),('arrival',False,'Generated but not used by recalcCost'),
        ('departure',False,'Generated but not used by recalcCost')]:
        trace.append(dict(SampledVariable=var,Sampled=True,PassedToOptimiser=False,PassedToRecalcCost=active,
            ChangesDispatch=False,ChangesCost=active,Explanation=notes,Source='results_extension/run_monte_carlo_uncertainty.m'))
    save(pd.DataFrame(trace),'monte_carlo_variable_trace.csv')
    if '--numerical-only' in sys.argv:
        print(s.to_string(index=False))
        print(pd.DataFrame(rs).to_string(index=False))
        return
    # Exact document locators remain stable because originals are not edited.
    manuscript=json.loads((O/'audit'/'energies-4550332.json').read_text(encoding='utf8'))
    changes=[]
    for item in manuscript['paragraphs']:
        n=item['paragraph'];text=item['text'];actions=[]
        if n==9:actions.append('REPLACE abstract using final comparison_summary and restoration_summary; remove Monte Carlo and old 74-pair headline')
        if n in [13,14,18,40,41]:actions.append('UPDATE scope: capped reserve, certified MIP accuracy, EV-terminal re-optimisation; legacy results historical only')
        if n==30:actions.append('DELETE the second consecutive Unlike stationary storage sentence')
        if 100<=n<178 and any(w in text.lower() for w in ['terminal','74','monte carlo','capacity','restoration','reserve','90','date','2019','solver']):actions.append('RECONCILE methods with R2.2; do not carry historical scenario conclusions into corrected results')
        if 178<=n<=360:actions.append('REPLACE affected results/captions with certified R2.2 tables and figures; historical numerical evidence is not current')
        if n in [338,339,340,341,342]:actions.append('DELETE fixed-dispatch Monte Carlo section/Table 19 and related claims; retain audit evidence outside manuscript')
        if n==180:actions.append('CORRECT baseline to 19 June 2014; ID43598 belongs to selected 90, not an independent additional day')
        if any(w in text.lower() for w in ['wilcoxon','cohen','p-value','statistical signific']):actions.append('DELETE inferential claim; use descriptive paired summaries')
        if 362<=n<=374:actions.append('UPDATE limitations/conclusions to distinguish full 90 terminal experiment, EV-only timed accounting and no rolling/network evidence')
        if n==378:actions.append('UPDATE code/data availability truthfully; public deposit and prepared-input redistribution approval unresolved')
        if actions:changes.append(dict(Paragraph=n,CurrentText=text,RequiredAction='; '.join(actions),Evidence='Round2_revision/tables + solveRound2.m'))
    save(pd.DataFrame(changes),'manuscript_paragraph_change_map.csv')
    captions=[x for x in manuscript['paragraphs'] if re.match(r'^(Table|Figure)\s+\d+',x['text'])]
    cmap=[]
    for x in captions:
        txt=x['text'];kind,num=re.match(r'^(Table|Figure)\s+(\d+)',txt).groups();num=int(num)
        action='KEEP conceptual content; audit cross-reference' if num==1 else 'REPLACE or withdraw historical result; not valid for R2.2'
        if kind=='Table' and num in [16,19]:action='DELETE inferential/Monte Carlo table'
        cmap.append(dict(Type=kind,Number=num,Paragraph=x['paragraph'],Caption=txt,Action=action))
    save(pd.DataFrame(cmap),'manuscript_caption_map.csv')
    # Search text/code occurrences without modifying historical evidence.
    cmd=['rg','-n','--glob','*.m','--glob','*.md','--glob','*.csv','--glob','*.txt',
         '--glob','!Round2_revision/**','13 May 2019|2019-05-13|19 June 2014|43598',str(R)]
    proc=subprocess.run(cmd,capture_output=True,text=True,encoding='utf8',errors='replace')
    (O/'audit'/'historical_date_occurrences.txt').write_text(proc.stdout,encoding='utf8')
    # JSON typed payload is the sole workbook input; no retyping of reported numbers.
    sheets={}
    for file in ['comparison_summary.csv','principal_pairs.csv','baseline_runs.csv','computational_summary.csv',
        'restoration_summary.csv','restoration_day_level.csv','restoration_paired.csv','break_even_thresholds.csv',
        'tariff_pairs.csv','subset_profile_comparison.csv','separated_accuracy_and_reserve_effects.csv',
        'validation_summary.csv','validation_check_counts.csv','monte_carlo_variable_trace.csv','model_counts_reserve.csv',
        'certified_principal_runs.csv','equality_infeasibility_evidence.csv','saving_materiality.csv']:
        f=read(file);sheets[file[:-4]]={'headers':list(f.columns),'rows':f.astype(object).where(pd.notna(f),None).values.tolist()}
    (O/'audit'/'workbook_data.json').write_text(json.dumps(sheets,allow_nan=False,indent=2),encoding='utf8')
    print(s.to_string(index=False));print(pd.DataFrame(rs).to_string(index=False))

if __name__=='__main__':main()
