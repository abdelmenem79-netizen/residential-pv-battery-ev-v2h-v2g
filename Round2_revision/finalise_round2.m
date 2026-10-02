function finalise_round2()
% Freeze only certified runs; retain uncapped failures as explicit controls.
out=fileparts(mfilename('fullpath'));root=fileparts(out);
addpath(fullfile(root,'P3_V2H_V2G_Project','config'));
addpath(genpath(fullfile(root,'P3_V2H_V2G_Project','src')));
P=load(fullfile(out,'Round2_principal_results.mat'));
T=load(fullfile(out,'Round2_tariff_results.mat'));
allRuns=[P.rows;T.rows];checks=table();
eqEvidence=readtable(fullfile(out,'tables','equality_infeasibility_evidence.csv'), ...
    'TextType','string','Delimiter',',','ReadVariableNames',true,'VariableNamingRule','preserve');
for k=1:height(allRuns)
    a=allRuns(k,:);S=load(a.SourceMAT);
    if a.Valid
        [v,m]=validateRound2(S.R,S.cfg,S.I,S.mode,S.R.round2.appliedReserve_kWh);
        assert(v.AllPass,'Independent revalidation failed: %s',a.CaseID);
        assert(abs(m.Cost_GBP-a.Cost_GBP)<1e-9);
        names=fieldnames(v);values=struct2cell(v);
        for j=1:numel(names)
            checks=[checks;table(a.CaseID,string(names{j}),logical(values{j}), ...
                "independent revalidation",a.SourceMAT,'VariableNames', ...
                {'CaseID','Check','Pass','Interpretation','SourceMAT'})]; %#ok<AGROW>
        end
    else
        n=find(P.days.DayID==a.DayID);
        uncapped=startsWith(a.CaseID,"uncapped_") && P.days.RawReserve_kWh(n)>3;
        equality=a.TerminalMode=="eq" && any(eqEvidence.CaseID==a.CaseID & eqEvidence.NativeInfeasible);
        expected=uncapped || equality;
        reason="Reserve exceeds usable band; algebraically infeasible";
        if equality,reason="Strict equality sensitivity: native infeasibility separately verified";end
        checks=[checks;table(a.CaseID,"ExplainedFailure",expected,reason, ...
            a.SourceMAT,'VariableNames',{'CaseID','Check','Pass','Interpretation','SourceMAT'})]; %#ok<AGROW>
        assert(expected,'Unexpected failed run: %s',a.CaseID);
    end
end
for j=1:height(T.thresholds)
    z=T.thresholds(j,:);a=T.pairs(T.pairs.TerminalMode==z.TerminalMode & T.pairs.ImportScale==z.ImportScale,:);
    lo=a(abs(a.ExportTariff-z.OnsetLower_GBPperkWh)<1e-10,:);
    hi=a(abs(a.ExportTariff-z.OnsetUpper_GBPperkWh)<1e-10,:);
    certified=~isempty(lo) && ~isempty(hi) && all(lo.SavingUpperBound_GBP<=T.tol) ...
        && all(hi.SavingLowerBound_GBP>T.tol) && z.BracketWidth_GBPperkWh<=T.priceTol;
    checks=[checks;table("threshold_"+z.TerminalMode+"_"+z.ImportScale, ...
        "ThresholdEndpointsAndWidth",certified,"Both final endpoints verified by objective bounds", ...
        string(fullfile(out,'Round2_tariff_results.mat')), ...
        'VariableNames',{'CaseID','Check','Pass','Interpretation','SourceMAT'})]; %#ok<AGROW>
end
assert(all(checks.Pass));
writetable(checks,fullfile(out,'tables','validation_checks.csv'));
pairs=table();
for mode=["none","ge","eq"]
    a=P.rows(P.rows.ReserveCapped & P.rows.TerminalMode==mode,:);
    ids=unique(a.DayID);
    if mode~="eq",assert(numel(ids)==90 && height(a)==180 && all(a.Valid));end
    for id=ids.'
        h=a(a.DayID==id & a.Regime=="V2H",:);g=a(a.DayID==id & a.Regime=="V2G",:);
        assert(height(h)==1 && height(g)==1);
        if mode~="eq",assert(h.Valid && g.Valid);end
        lb=h.ObjectiveLowerBound_GBP-g.Cost_GBP;
        ub=h.Cost_GBP-g.ObjectiveLowerBound_GBP;
        if h.Valid && g.Valid,assert(ub>=-1e-6,'Nested feasible-set cost contradiction');end
        n=find(P.days.DayID==id);
        pairs=[pairs;table(id,h.CalendarDate,mode,P.days.OldValidPair(n), ...
            h.Cost_GBP,g.Cost_GBP,h.Cost_GBP-g.Cost_GBP,lb,ub,lb>1e-5, ...
            h.SourceMAT,g.SourceMAT,'VariableNames',{'DayID','CalendarDate','TerminalMode', ...
            'OldValidPair','V2HCost_GBP','V2GCost_GBP','Saving_GBP', ...
            'SavingLowerBound_GBP','SavingUpperBound_GBP','CertifiedPositive', ...
            'V2HSourceMAT','V2GSourceMAT'})]; %#ok<AGROW>
    end
end
writetable(pairs,fullfile(out,'tables','principal_pairs.csv'));
writetable(P.rows(P.rows.DayID==43598,:),fullfile(out,'tables','baseline_runs.csv'));
counts=table();
for n=1:height(allRuns)
    if ~allRuns.Valid(n),continue;end
    S=load(allRuns.SourceMAT(n));r=S.R;
    counts=[counts;table(allRuns.CaseID(n),numel(S.I.P_load),numel(r.raw.x), ...
        numel(r.raw.isOn)+numel(r.raw.POn)+numel(r.raw.startupp), ...
        r.round2.rawReserve_kWh,r.round2.appliedReserve_kWh,r.round2.unmetReserve_kWh, ...
        'VariableNames',{'CaseID','TimeSteps','ContinuousVariables','BinaryVariables', ...
        'RawReserve_kWh','AppliedReserve_kWh','UnmetForecastReserve_kWh'})]; %#ok<AGROW>
end
writetable(counts,fullfile(out,'tables','model_counts_reserve.csv'));
save(fullfile(out,'Round2_Frozen_Results.mat'),'allRuns','pairs','checks','counts','-v7.3');
cfg=P.cfg;cfg.paths=struct();
if isfield(cfg,'round2'),cfg=rmfield(cfg,'round2');end
save(fullfile(out,'audit','public_configuration.mat'),'cfg');
fprintf('FROZEN: %d run records; %d checks, all PASS.\n',height(allRuns),height(checks));
end
