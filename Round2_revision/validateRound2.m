function [v,m] = validateRound2(R,cfg,I,terminalMode,reserve)
% Independent numerical checks of power, energy, logic and cost identities.
t=tic;dt=cfg.Dt;tol=1e-5;etol=1e-5;ctol=1e-6;
bd=R.P_batt_discharge;bc=R.P_batt_charge;ed=R.P_ev_discharge;ec=R.P_ev_charge;
gi=R.P_grid_import;ge=R.P_grid_export;
Eb0=cfg.battery.capacity*I.initialSOC.battery_pct/100;
Ee0=cfg.ev.capacity*I.initialSOC.ev_pct/100;
Eb=Eb0+dt*cumsum(cfg.battery.etaCharge*cfg.battery.etaConverter*bc-bd/(cfg.battery.etaDischarge*cfg.battery.etaConverter));
Ee=Ee0+dt*cumsum(cfg.ev.eta*ec-ed/cfg.ev.eta)-cumsum(I.ev.trip.energyEvent_kWh);
balance=bd-bc+ed-ec+gi-ge+I.P_pv-I.P_load-R.P_app;
matrix=R.raw.powerBalanceMatrix*R.raw.x+R.raw.applianceMatrix*R.raw.POn-R.raw.powerBalanceRHS;
ci=dt*sum(I.tariff.import.*gi);ce=dt*sum(I.tariff.export.*ge);
cb=cfg.battery.price/(2*cfg.battery.cycleLife*cfg.battery.capacity)*dt*sum(cfg.battery.etaCharge*cfg.battery.etaConverter*bc+bd/(cfg.battery.etaDischarge*cfg.battery.etaConverter));
cv=cfg.ev.price/(2*cfg.ev.cycleLife*cfg.ev.capacity)*dt*sum(ed.*I.ev.available);
cost=ci-ce+cb+cv;
v=struct();
v.Finite=all(isfinite([R.raw.x;R.raw.isOn;R.raw.POn;Eb;Ee;R.solver.objective]));
v.PowerBalance=max(abs(matrix))<=tol && max(abs(balance-matrix))<=tol;
v.PowerBounds=all(R.raw.x>=R.raw.boundsLower-tol & R.raw.x<=R.raw.boundsUpper+tol);
v.BatterySOC=min([Eb0;Eb])>=cfg.battery.capacity*cfg.soc.min/100-etol && max([Eb0;Eb])<=cfg.battery.capacity*cfg.soc.max/100+etol;
v.EVSOC=min([Ee0;Ee])>=cfg.ev.capacity*cfg.ev.soc.min/100-etol && max([Ee0;Ee])<=cfg.ev.capacity*cfg.ev.soc.max/100+etol;
away=I.ev.available<0.5;
v.Availability=max([0;ec(away);ed(away)])<=tol;
v.GridExclusivity=max(min(gi,ge))<=tol;
v.BatteryExclusivity=max(min(bc,bd))<=tol;
v.EVExclusivity=max(min(ec,ed))<=tol;
v.CrossStorageInterlocks=max([min(ed,bc);min(ec,bd)])<=tol;
v.ExportInterlocks=max(min(bd,ge))<=tol;
if R.regime=="V2H",v.ExportInterlocks=v.ExportInterlocks && max(min(ed,ge))<=tol;end
v.IntegerModes=max(abs([R.raw.isOn;R.raw.POn;R.raw.startupp]-round([R.raw.isOn;R.raw.POn;R.raw.startupp])))<=tol;
dep=I.ev.trip.timeGoIndex;
firstErr=0;
if ~isempty(dep) && I.ev.available(dep(1))==1
    firstErr=abs(Ee(dep(1))-cfg.ev.capacity*cfg.ev.desiredBeforeFirstTripPct/100);
end
v.FirstTrip=firstErr<=etol;
terminalViolation=0;
if terminalMode=="ge",terminalViolation=max(0,Ee0-Ee(end));end
if terminalMode=="eq",terminalViolation=abs(Ee0-Ee(end));end
v.TerminalSOC=terminalViolation<=etol;
v.Reserve=min(Eb(122:143))>=cfg.battery.capacity*cfg.soc.min/100+reserve-etol;
v.Cost=abs(cost-R.solver.objective)<=ctol && abs(cost-R.cost.total)<=ctol;
v.ExportRevenue=abs(ce-R.cost.exportRevenue)<=ctol;
v.Degradation=abs(cb-R.cost.batteryDegradation)<=ctol && abs(cv-R.cost.evDegradation)<=ctol;
v.StateReconstruction=max(abs(Eb-0.01*cfg.battery.capacity*R.SOC_batt))<=etol && max(abs(Ee-0.01*cfg.ev.capacity*R.SOC_ev))<=etol;
v.DateMapping=isfield(I.metadata,'calendarDateVerified') && I.metadata.calendarDateVerified;
v.Solver=R.solver.status=="Solved";
v.AllPass=all(structfun(@(x)logical(x),v));
m=struct('Cost_GBP',cost,'ImportCost_GBP',ci,'ExportRevenue_GBP',ce, ...
    'BatteryDeg_GBP',cb,'EVDeg_GBP',cv,'GridImport_kWh',sum(gi)*dt, ...
    'GridExport_kWh',sum(ge)*dt,'NetGrid_kWh',sum(gi-ge)*dt, ...
    'EVCharge_kWh',sum(ec)*dt,'EVDischarge_kWh',sum(ed)*dt, ...
    'EVInitialSOC_pct',I.initialSOC.ev_pct,'EVFinalSOC_pct',100*Ee(end)/cfg.ev.capacity, ...
    'EVInitialEnergy_kWh',Ee0,'EVFinalEnergy_kWh',Ee(end), ...
    'BatteryMinSOC_pct',100*min([Eb0;Eb])/cfg.battery.capacity, ...
    'BatteryMaxSOC_pct',100*max([Eb0;Eb])/cfg.battery.capacity, ...
    'EVMinSOC_pct',100*min([Ee0;Ee])/cfg.ev.capacity,'EVMaxSOC_pct',100*max([Ee0;Ee])/cfg.ev.capacity, ...
    'BalanceMax_kW',max(abs(matrix)),'BalanceRMS_kW',sqrt(mean(matrix.^2)), ...
    'GridSimultaneity_kW',max(min(gi,ge)),'EVChargeAway_kW',max([0;ec(away)]), ...
    'EVDischargeAway_kW',max([0;ed(away)]),'CostError_GBP',abs(cost-R.solver.objective), ...
    'FirstTripError_kWh',firstErr,'TerminalViolation_kWh',terminalViolation, ...
    'TripEnergy_kWh',sum(I.ev.trip.energyEvent_kWh), ...
    'OptimisationTime_s',R.runtime.optimisation_s,'VerificationTime_s',toc(t));
end
