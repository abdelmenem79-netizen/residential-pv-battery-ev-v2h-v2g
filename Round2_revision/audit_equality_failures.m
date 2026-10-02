function audit_equality_failures()
% Re-run failed equality cases with DualReductions=0 to disambiguate status.
out=fileparts(mfilename('fullpath'));root=fileparts(out);
addpath(fullfile(root,'P3_V2H_V2G_Project','config'));addpath(genpath(fullfile(root,'P3_V2H_V2G_Project','src')));
P=load(fullfile(out,'Round2_principal_results.mat'));
bad=P.rows(P.rows.TerminalMode=="eq" & ~P.rows.Valid,:);evidence=table();
for k=1:height(bad)
    S=load(bad.SourceMAT(k));cfg=S.cfg;cfg.round2.diagnoseInfeasibility=true;
    key="feasibility_only_"+bad.CaseID(k);
    cache=fullfile(out,'runs_certified',key+".mat");
    if isfile(cache)
        C=load(cache);row=C.row;
    else
        [row,~]=runRound2Case(cfg,S.I,bad.Regime(k),"eq",true,key,out);
    end
    native=fileread(fullfile(out,'logs_certified',key+".log"));
    nativeInfeasible=contains(native,'Model is infeasible') && ~contains(native,'Model is infeasible or unbounded');
    assert(nativeInfeasible && ~row.Valid && contains(row.Error,'CVX status Infeasible'), ...
        'Equality diagnosis needs further review');
    dep=S.I.ev.trip.timeGoIndex(1);after=(1:cfg.DPoints).'>dep;
    % Relaxed upper bound allocates ALL appliance energy to post-departure
    % connected slots, ignoring its time window. This cannot understate the
    % EV discharge opportunity, because appliances each run for one hour.
    app=cfg.appliances.dishwasher.power+cfg.appliances.washingMachine.power;
    maxDis=min(cfg.ev.Pmax,max(0,S.I.P_load-S.I.P_pv)).*S.I.ev.available;
    lower=cfg.ev.capacity*cfg.ev.desiredBeforeFirstTripPct/100 ...
        -sum(S.I.ev.trip.energyEvent_kWh(after))-(cfg.Dt*sum(maxDis(after))+app)/cfg.ev.eta;
    initial=cfg.ev.capacity*S.I.initialSOC.ev_pct/100;
    evidence=[evidence;table(bad.CaseID(k),bad.DayID(k),bad.Regime(k), ...
        nativeInfeasible,initial,lower,lower>initial+1e-5, ...
        "Equality forces depletion not required by >=; native bounded MILP infeasibility verified", ...
        row.SourceMAT,'VariableNames',{'CaseID','DayID','Regime','NativeInfeasible', ...
        'InitialEnergy_kWh','RelaxedTerminalLowerBound_kWh','AnalyticBoundProvesInfeasible', ...
        'Interpretation','DiagnosticSourceMAT'})]; %#ok<AGROW>
end
writetable(evidence,fullfile(out,'tables','equality_infeasibility_evidence.csv'));
end
