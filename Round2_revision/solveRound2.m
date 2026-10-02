function R = solveRound2(cfg, inputs, regime, terminalMode, capReserve)
%SOLVEROUND2 Auditable Round-2 fork of solveStorageRegimeCVX.
% Scientific changes: optional reserve saturation and EV terminal condition.
% Existing objective, all other interlocks, bounds and appliance logic retained.
D=cfg.DPoints; Dt=cfg.Dt;
flags=struct('name',string(regime),'label',string(regime),'exportEnabled',true, ...
    'exportRevenueEnabled',true,'evAvailabilityGated',true, ...
    'evDischargeInBalanceGated',false,'evToGridAllowed',string(regime)=="V2G", ...
    'batteryToGridAllowed',false,'useLegacyReserveAbs',false);
dv=buildDecisionVariables(cfg,inputs,flags);
model=buildConstraints(cfg,inputs,flags,dv);
stats=countModelVariables(dv,D);
rawReserve=model.peakForecast_kWh;
usable=cfg.battery.capacity*(cfg.soc.max-cfg.soc.min)/100;
if capReserve
    % Round 2 P1: achievable reserve target; unmet forecast remains reported.
    model.peakForecast_kWh=min(rawReserve,usable);
end
cvx_clear
timer=tic;
cvx_begin quiet
    cvx_solver(char(cfg.optimization.solver))
    % Clear inherited settings; use audited absolute economic accuracy below.
    cvx_solver_settings -clear
    if isfield(cfg.round2,'tight') && cfg.round2.tight
        % Requires the audited installed-shim argument-index fix (3 -> 2).
        absoluteTolerance=1e-8;
        if isfield(cfg.round2,'absoluteTolerance'),absoluteTolerance=cfg.round2.absoluteTolerance;end
        cvx_solver_settings('MIPGap',0,'MIPGapAbs',absoluteTolerance,'OutputFlag',1, ...
            'LogToConsole',0,'LogFile',char(cfg.round2.logFile))
        if isfield(cfg.round2,'diagnoseInfeasibility') && cfg.round2.diagnoseInfeasibility
            cvx_solver_settings('DualReductions',0)
        end
        if isfield(cfg.round2,'boundFocus') && cfg.round2.boundFocus
            cvx_solver_settings('Threads',6,'MIPFocus',3,'Cuts',2)
        end
        if isfield(cfg.round2,'integralityFocus') && cfg.round2.integralityFocus
            cvx_solver_settings('IntegralityFocus',1,'IntFeasTol',1e-9)
        end
        if isfield(cfg.round2,'diagnosticTimeLimit')
            cvx_solver_settings('TimeLimit',cfg.round2.diagnosticTimeLimit)
        end
    end
    variable x(dv.n)
    variable isOn(dv.n) binary
    variable POn(2*D) binary
    variable startupp(2*D) binary
    PB_d=x(dv.idx.P_batt_discharge);PB_c=x(dv.idx.P_batt_charge);
    EV_d=x(dv.idx.P_ev_discharge);EV_c=x(dv.idx.P_ev_charge);
    PG_i=x(dv.idx.P_grid_import);PG_e=x(dv.idx.P_grid_export);
    b_PB_d=isOn(dv.idx.P_batt_discharge);b_PB_c=isOn(dv.idx.P_batt_charge);
    b_EV_d=isOn(dv.idx.P_ev_discharge);b_EV_c=isOn(dv.idx.P_ev_charge);
    b_PG_i=isOn(dv.idx.P_grid_import);b_PG_e=isOn(dv.idx.P_grid_export);
    vars=struct('P_batt_discharge',PB_d,'P_batt_charge',PB_c, ...
        'P_ev_discharge',EV_d,'P_ev_charge',EV_c, ...
        'P_grid_import',PG_i,'P_grid_export',PG_e);
    obj=buildObjective(cfg,inputs,vars,flags);
    if isfield(cfg.round2,'diagnoseInfeasibility') && cfg.round2.diagnoseInfeasibility
        % Diagnostic only: identical feasible set, constant objective.
        minimize(0*obj.total)
    else
        minimize(obj.total)
    end
    subject to
        model.A1*x+model.A10*POn==model.b1;
        x<=model.ub; x>=model.lb;
        b_PG_i+b_PG_e<=1;
        PG_i<=cfg.grid.Pmax*b_PG_i;
        PG_i>=cfg.optimization.minSwitchPower*b_PG_i;
        PG_e<=cfg.grid.Pmax*b_PG_e;
        PG_e>=cfg.optimization.minSwitchPower*b_PG_e;
        PB_d<=cfg.battery.Pmax*b_PB_d; -PB_c<=cfg.battery.Pmax*b_PB_c;
        PB_d>=cfg.optimization.minSwitchPower*b_PB_d;
        -PB_c>=cfg.optimization.minSwitchPower*b_PB_c;
        b_PB_d+b_PB_c<=1;
        EV_d<=cfg.ev.Pmax*b_EV_d; -EV_c<=cfg.ev.Pmax*b_EV_c;
        EV_d>=cfg.optimization.minSwitchPower*b_EV_d;
        -EV_c>=cfg.optimization.minSwitchPower*b_EV_c;
        b_EV_d+b_EV_c<=1;
        b_EV_d<=inputs.ev.available(:);b_EV_c<=inputs.ev.available(:);
        b_EV_d.*inputs.ev.available(:)+b_PB_c<=1;
        b_EV_c.*inputs.ev.available(:)+b_PB_d<=1;
        b_PB_d+b_PG_e<=1;
        if ~flags.evToGridAllowed
            b_EV_d+b_PG_e<=1;
        end
        Ebmax=cfg.battery.capacity*cfg.soc.max/100;
        Ebmin=cfg.battery.capacity*cfg.soc.min/100;
        Estart=cfg.battery.capacity*inputs.initialSOC.battery_pct/100;
        cumFluxBatt=cumsum(PB_d/(cfg.battery.etaDischarge*cfg.battery.etaConverter) ...
            +cfg.battery.etaCharge*cfg.battery.etaConverter*PB_c);
        cumFluxBatt<=(Estart-Ebmin)/Dt;
        cumFluxBatt((1:D).'>121 & (1:D).'<144)<= ...
            (Estart-Ebmin-model.peakForecast_kWh)/Dt;
        cumFluxBatt>=(Estart-Ebmax)/Dt;
        EevStart=cfg.ev.capacity*inputs.initialSOC.ev_pct/100;
        Eev=EevStart-Dt*cumsum(EV_d/cfg.ev.eta+cfg.ev.eta*EV_c) ...
            -cumsum(inputs.ev.trip.energyEvent_kWh(:));
        Eev<=cfg.ev.capacity*cfg.ev.soc.max/100;
        Eev>=cfg.ev.capacity*cfg.ev.soc.min/100;
        if ~isempty(inputs.ev.trip.timeGoIndex)
            kDep=max(1,min(D,inputs.ev.trip.timeGoIndex(1)));
            if inputs.ev.available(kDep)==1
                Eev(kDep)==cfg.ev.desiredBeforeFirstTripPct*cfg.ev.capacity/100;
            end
        end
        % Round 2 P2: true solver-side terminal energy, not repricing.
        if terminalMode=="ge"
            Eev(end)>=EevStart;
        elseif terminalMode=="eq"
            Eev(end)==EevStart;
        else
            assert(terminalMode=="none");
        end
        if cfg.appliances.dishwasher.power>0
            sum(cfg.appliances.dishwasher.power*POn(1:D))==cfg.appliances.dishwasher.power/Dt;
        else
            POn(1:D)==0;startupp(1:D)==0;
        end
        if cfg.appliances.washingMachine.power>0
            sum(cfg.appliances.washingMachine.power*POn(D+1:2*D))==cfg.appliances.washingMachine.power/Dt;
        else
            POn(D+1:2*D)==0;startupp(D+1:2*D)==0;
        end
        ds=round(cfg.appliances.dishwasher.startHour/Dt);
        de=round((cfg.appliances.dishwasher.startHour+cfg.appliances.dishwasher.waitHours)/Dt);
        ws=round(cfg.appliances.washingMachine.startHour/Dt);
        we=round((cfg.appliances.washingMachine.startHour+cfg.appliances.washingMachine.waitHours)/Dt);
        startupp(1:max(1,ds))==0;
        if de+1<=D,startupp(de+1:D)==0;end
        startupp(D+1:D+max(1,ws))==0;
        if we+1<=D,startupp(D+we+1:2*D)==0;end
        minUpTime=round(1/Dt);
        for jj=1:2
            for kk=1:D
                if kk>D-minUpTime,si=kk:D;else,si=kk:kk+minUpTime-1;end
                startupp(kk+(jj-1)*D)-sum(POn(si+(jj-1)*D))/numel(si)<=0;
            end
        end
        j=2:D;
        -POn(j-1)+POn(j)-startupp(j)<=0;
        -POn(D+j-1)+POn(D+j)-startupp(D+j)<=0;
cvx_end
runtime=toc(timer);
if ~ismember(string(cvx_status),["Solved","Inaccurate/Solved"])
    error('Round2:Unsolved','CVX status %s; objective %.12g',cvx_status,cvx_optval);
end
s=struct('x',x(:),'isOn',isOn(:),'POn',POn(:),'status',string(cvx_status), ...
    'objective',cvx_optval,'optimisationRuntime_s',runtime,'modelStats',stats);
R=reconstructResults(cfg,inputs,flags,dv,model,s);
R.solver.lowerBound=cvx_optbnd;
R.solver.absoluteGap=max(0,cvx_optval-cvx_optbnd);
R.solver.boundSource="CVX reported bound; may be weaker than native MIP bound";
if isfield(cfg.round2,'tight') && cfg.round2.tight
    native=fileread(cfg.round2.logFile);
    token=regexp(native,'Best objective ([^,]+), best bound ([^,]+), gap','tokens');
    assert(~isempty(token),'Native MIP certificate absent');token=token{end};
    gap=abs(str2double(token{1})-str2double(token{2}));
    assert(isfinite(gap) && gap<=absoluteTolerance+1e-8,'Native absolute MIP gap too large');
    R.solver.nativeStatus="OPTIMAL";
    R.solver.lowerBound=cvx_optval-gap;
    R.solver.absoluteGap=gap;
    R.solver.boundSource="native Gurobi incumbent/bound, adjusted for CVX constant";
end
R.raw.startupp=startupp(:);
R.round2=struct('version',"R2.2",'terminalMode',terminalMode, ...
    'reserveCapped',capReserve,'rawReserve_kWh',rawReserve, ...
    'appliedReserve_kWh',model.peakForecast_kWh,'unmetReserve_kWh',max(0,rawReserve-model.peakForecast_kWh));
end
