function run_round2_restoration()
% A: flat-price accounting; B: explicit next-day predeparture charging-only
% accounting; C: separate complete terminal-constrained household optimisation.
% B does not claim full next-day household/network feasibility or rolling control.
out=fileparts(mfilename('fullpath'));root=fileparts(out);p3=fullfile(root,'P3_V2H_V2G_Project');
addpath(fullfile(p3,'config'));addpath(genpath(fullfile(p3,'src')));
Q=load(fullfile(out,'audit','prepared_inputs_private.mat'));cfg=Q.cfg;
rows=table();schedule=table();
for n=1:height(Q.days)
    id=Q.days.DayID(n);dc=cfg;dc.case.date=id+1;
    % Only the next day's EV/tariff inputs are needed, not a day-after forecast.
    nd=loadHouseData(dc,id+1);next=struct('time_h',nd.time_h, ...
        'ev',buildEVProfile(dc,nd.evAvailableRaw,nd.evDistanceRaw),'tariff',buildTariffs(dc));
    prefix=find(next.ev.available<.5,1)-1;
    if isempty(prefix),prefix=cfg.DPoints;end
    permitted=false(cfg.DPoints,1);permitted(1:prefix)=true;
    for reg=["V2H","V2G"]
        S=load(fullfile(out,'runs_certified',"principal_none_"+id+"_"+reg+".mat"));
        T=load(fullfile(out,'runs_certified',"principal_ge_"+id+"_"+reg+".mat"));
        assert(S.row.Valid && T.row.Valid);
        deficit=max(0,S.row.EVInitialEnergy_kWh-S.row.EVFinalEnergy_kWh);
        need=deficit/cfg.ev.eta;flat=need*cfg.tariff.import.offPeak;
        % Linear minimum import cost: sort actual next-day connected slots by
        % tariff and then time; no trip occurs before the first departure.
        ix=find(permitted);[~,order]=sortrows([next.tariff.import(ix),ix],[1,2]);ix=ix(order);
        charge=zeros(cfg.DPoints,1);remaining=need;
        for k=ix.'
            e=min(remaining,cfg.ev.Pmax*cfg.Dt);charge(k)=e/cfg.Dt;remaining=remaining-e;
            if remaining<1e-10,break;end
        end
        feasible=remaining<=1e-6;
        ePath=S.row.EVFinalEnergy_kWh+cfg.ev.eta*cfg.Dt*cumsum(charge);
        physical=feasible && all(charge<=cfg.ev.Pmax+1e-6) && all(charge(~permitted)==0) ...
            && max(ePath)<=cfg.ev.capacity*cfg.ev.soc.max/100+1e-6;
        tou=NaN;if physical,tou=sum(charge.*next.tariff.import)*cfg.Dt;end
        row=table(id,Q.days.CalendarDate(n),reg,S.row.Cost_GBP,deficit,need, ...
            cfg.ev.eta,cfg.tariff.import.offPeak,flat,tou,S.row.Cost_GBP+flat, ...
            S.row.Cost_GBP+tou,T.row.Cost_GBP,physical,remaining,prefix*cfg.Dt, ...
            'VariableNames',{'DayID','CalendarDate','Regime','UnconstrainedCost_GBP', ...
            'RestoreBattery_kWh','RestoreGrid_kWh','ChargeEfficiency','FlatPrice_GBPperkWh', ...
            'FlatRestorationCost_GBP','TOURestorationCost_GBP','FlatAdjustedCost_GBP', ...
            'TOUAdjustedCost_GBP','TerminalOptimisedCost_GBP','EVOnlyScheduleFeasible', ...
            'UnservedGridEnergy_kWh','NextDayPredepartureConnected_h'});
        rows=[rows;row]; %#ok<AGROW>
        schedule=[schedule;table(repmat(id,cfg.DPoints,1),repmat(reg,cfg.DPoints,1), ...
            24+next.time_h,next.ev.available,next.tariff.import,charge,ePath, ...
            'VariableNames',{'DayID','Regime','ElapsedHour','Available','ImportTariff','RestorationCharge_kW','StoredEnergy_kWh'})]; %#ok<AGROW>
    end
end
writetable(rows,fullfile(out,'tables','restoration_day_level.csv'));
writetable(schedule,fullfile(out,'tables','restoration_timed_schedule.csv'));
save(fullfile(out,'Round2_restoration_results.mat'),'rows','schedule','-v7.3');
end
