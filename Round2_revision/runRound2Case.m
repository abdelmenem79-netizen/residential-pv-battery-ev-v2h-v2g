function [row,R] = runRound2Case(cfg,I,regime,mode,cap,key,out)
% Persist every attempt, including failures. Existing identical case IDs resume.
path=fullfile(out,'runs_certified',char(key)+".mat");
if isfile(path)
    Q=load(path);assert(Q.row.ModelVersion=="R2.2");
    assert(isequaln(Q.I,I) && Q.mode==mode && Q.cap==cap);
    if Q.row.Valid
        row=Q.row;R=Q.R;return
    end
    archive=fullfile(out,'failed_attempts');if ~isfolder(archive),mkdir(archive);end
    movefile(path,fullfile(archive,string(key)+"_"+string(datetime('now','Format','yyyyMMdd_HHmmss'))+".mat"));
end
cfg.round2.logFile=string(fullfile(out,'logs_certified',char(key)+".log"));
cfg.round2.tight=true;
R=[];v=struct();m=struct();err="";status="NOT_RUN";
try
    R=solveRound2(cfg,I,regime,mode,cap);status=R.solver.status;
    [v,m]=validateRound2(R,cfg,I,mode,R.round2.appliedReserve_kWh);
catch ME
    err=string(getReport(ME,'extended','hyperlinks','off'));
    status="FAILED: "+string(ME.message);
end
row=table(string(key),double(I.metadata.dayNumber),string(I.metadata.calendarDate),string(regime), ...
    string(mode),logical(cap),string(status),"R2.2",string(datetime('now','Format','yyyy-MM-dd HH:mm:ss')), ...
    'VariableNames',{'CaseID','DayID','CalendarDate','Regime','TerminalMode','ReserveCapped','SolverStatus','ModelVersion','Generated'});
fields={'Cost_GBP','ImportCost_GBP','ExportRevenue_GBP','BatteryDeg_GBP','EVDeg_GBP', ...
    'GridImport_kWh','GridExport_kWh','NetGrid_kWh','EVCharge_kWh','EVDischarge_kWh', ...
    'EVInitialSOC_pct','EVFinalSOC_pct','EVInitialEnergy_kWh','EVFinalEnergy_kWh', ...
    'BatteryMinSOC_pct','BatteryMaxSOC_pct','EVMinSOC_pct','EVMaxSOC_pct', ...
    'BalanceMax_kW','BalanceRMS_kW','GridSimultaneity_kW','EVChargeAway_kW', ...
    'EVDischargeAway_kW','CostError_GBP','FirstTripError_kWh','TerminalViolation_kWh', ...
    'TripEnergy_kWh','OptimisationTime_s','VerificationTime_s'};
for j=1:numel(fields)
    k=fields{j};row.(k)=NaN;if isfield(m,k),row.(k)=m.(k);end
end
row.Valid=isfield(v,'AllPass') && v.AllPass;row.Error=err;
row.ObjectiveLowerBound_GBP=NaN;row.AbsoluteMIPGap_GBP=NaN;
if ~isempty(R)
    row.ObjectiveLowerBound_GBP=R.solver.lowerBound;
    row.AbsoluteMIPGap_GBP=R.solver.absoluteGap;
end
row.SourceMAT=string(path);
save(path,'row','R','v','I','cfg','mode','cap','-v7.3');
fprintf('%s %s valid=%d cost=%.9f\n',key,status,row.Valid,row.Cost_GBP);
end
