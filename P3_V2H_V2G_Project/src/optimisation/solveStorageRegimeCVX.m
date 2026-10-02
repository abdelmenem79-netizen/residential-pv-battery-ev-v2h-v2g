function Result = solveStorageRegimeCVX(cfg, inputs, flags)
%SOLVESTORAGEREGIMECVX Shared CVX/Gurobi MILP model for all P3 regimes.

D = cfg.DPoints;
Dt = cfg.Dt;
dv = buildDecisionVariables(cfg, inputs, flags);
model = buildConstraints(cfg, inputs, flags, dv);
modelStats = countModelVariables(dv, D);

if exist('cvx_begin', 'file') ~= 2
    error('CVX is required but was not found on the MATLAB path.');
end

cvx_clear
% Revision runtime logging: optimisation timer covers the CVX/Gurobi solve
% stage only, from immediately before cvx_begin to immediately after cvx_end.
optimisationTimer = tic;
cvx_begin quiet
    cvx_solver(char(cfg.optimization.solver))

    variable x(dv.n)
    variable isOn(dv.n) binary
    variable POn(2*D) binary
    variable startupp(2*D) binary

    PB_d = x(dv.idx.P_batt_discharge);
    PB_c = x(dv.idx.P_batt_charge);
    EV_d = x(dv.idx.P_ev_discharge);
    EV_c = x(dv.idx.P_ev_charge);
    PG_i = x(dv.idx.P_grid_import);
    PG_e = x(dv.idx.P_grid_export);

    b_PB_d = isOn(dv.idx.P_batt_discharge);
    b_PB_c = isOn(dv.idx.P_batt_charge);
    b_EV_d = isOn(dv.idx.P_ev_discharge);
    b_EV_c = isOn(dv.idx.P_ev_charge);
    b_PG_i = isOn(dv.idx.P_grid_import);
    b_PG_e = isOn(dv.idx.P_grid_export);

    vars = struct();
    vars.P_batt_discharge = PB_d;
    vars.P_batt_charge = PB_c;
    vars.P_ev_discharge = EV_d;
    vars.P_ev_charge = EV_c;
    vars.P_grid_import = PG_i;
    vars.P_grid_export = PG_e;

    objective = buildObjective(cfg, inputs, vars, flags);
    minimize(objective.total)

    subject to
        model.A1 * x + model.A10 * POn == model.b1;
        x <= model.ub;
        x >= model.lb;

        if ~flags.exportEnabled
            PG_e == 0;
            b_PG_e == 0;
        end

        b_PG_i + b_PG_e <= 1;
        PG_i <= cfg.grid.Pmax .* b_PG_i;
        PG_i >= cfg.optimization.minSwitchPower .* b_PG_i;
        PG_e <= cfg.grid.Pmax .* b_PG_e;
        PG_e >= cfg.optimization.minSwitchPower .* b_PG_e;

        PB_d <= cfg.battery.Pmax .* b_PB_d;
        -PB_c <= cfg.battery.Pmax .* b_PB_c;
        PB_d >= cfg.optimization.minSwitchPower .* b_PB_d;
        -PB_c >= cfg.optimization.minSwitchPower .* b_PB_c;
        b_PB_d + b_PB_c <= 1;

        EV_d <= cfg.ev.Pmax .* b_EV_d;
        -EV_c <= cfg.ev.Pmax .* b_EV_c;
        EV_d >= cfg.optimization.minSwitchPower .* b_EV_d;
        -EV_c >= cfg.optimization.minSwitchPower .* b_EV_c;
        b_EV_d + b_EV_c <= 1;

        if flags.evAvailabilityGated
            b_EV_d <= inputs.ev.available(:);
            b_EV_c <= inputs.ev.available(:);
        end

        b_EV_d .* inputs.ev.available(:) + b_PB_c <= 1;
        b_EV_c .* inputs.ev.available(:) + b_PB_d <= 1;

        if ~flags.batteryToGridAllowed
            b_PB_d + b_PG_e <= 1;
        end
        if ~flags.evToGridAllowed
            b_EV_d + b_PG_e <= 1;
        end

        Ebmax = cfg.battery.capacity * cfg.soc.max / 100;
        Ebmin = cfg.battery.capacity * cfg.soc.min / 100;
        Estart = cfg.battery.capacity * inputs.initialSOC.battery_pct / 100;
        netFluxBatt = PB_d/(cfg.battery.etaDischarge*cfg.battery.etaConverter) + ...
            cfg.battery.etaCharge*cfg.battery.etaConverter*PB_c;
        cumFluxBatt = cumsum(netFluxBatt);
        cumFluxBatt <= (Estart - Ebmin) / Dt;
        if model.peakReserveMode == "legacy_abs"
            cumFluxBatt((1:D).' > 121 & (1:D).' < 144) <= abs((Estart - Ebmin - model.peakForecast_kWh) / Dt);
        else
            cumFluxBatt((1:D).' > 121 & (1:D).' < 144) <= (Estart - Ebmin - model.peakForecast_kWh) / Dt;
        end
        cumFluxBatt >= (Estart - Ebmax) / Dt;

        EevStart = cfg.ev.capacity * inputs.initialSOC.ev_pct / 100;
        EevMax = cfg.ev.capacity * cfg.ev.soc.max / 100;
        EevMin = cfg.ev.capacity * cfg.ev.soc.min / 100;
        netFluxEV = EV_d/cfg.ev.eta + cfg.ev.eta*EV_c;
        Eev = EevStart - Dt*cumsum(netFluxEV) - cumsum(inputs.ev.trip.energyEvent_kWh(:));
        Eev <= EevMax;
        Eev >= EevMin;

        if ~isempty(inputs.ev.trip.timeGoIndex)
            kDep = max(1, min(D, inputs.ev.trip.timeGoIndex(1)));
            if inputs.ev.available(kDep) == 1
                Eev(kDep) == cfg.ev.desiredBeforeFirstTripPct * cfg.ev.capacity / 100;
            end
        end

        if cfg.appliances.dishwasher.power > 0
            sum(cfg.appliances.dishwasher.power * POn(1:D)) == cfg.appliances.dishwasher.power / Dt;
        else
            POn(1:D) == 0;
            startupp(1:D) == 0;
        end

        if cfg.appliances.washingMachine.power > 0
            sum(cfg.appliances.washingMachine.power * POn(D+1:2*D)) == cfg.appliances.washingMachine.power / Dt;
        else
            POn(D+1:2*D) == 0;
            startupp(D+1:2*D) == 0;
        end

        dishStart = round(cfg.appliances.dishwasher.startHour / Dt);
        dishEnd = round((cfg.appliances.dishwasher.startHour + cfg.appliances.dishwasher.waitHours) / Dt);
        washStart = round(cfg.appliances.washingMachine.startHour / Dt);
        washEnd = round((cfg.appliances.washingMachine.startHour + cfg.appliances.washingMachine.waitHours) / Dt);

        startupp(1:max(1, dishStart)) == 0;
        if dishEnd + 1 <= D
            startupp(dishEnd+1:D) == 0;
        end
        startupp(D+1:D+max(1, washStart)) == 0;
        if washEnd + 1 <= D
            startupp(D+washEnd+1:2*D) == 0;
        end

        minUpTime = round(1 / Dt);
        for jj = 1:2
            for kk = 1:D
                if kk > D - minUpTime
                    sumidx = kk:D;
                else
                    sumidx = kk:kk+minUpTime-1;
                end
                startupp(kk+(jj-1)*D) - sum(POn(sumidx+(jj-1)*D))/numel(sumidx) <= 0;
            end
        end

        idx2 = 2:D;
        -POn(idx2-1) + POn(idx2) - startupp(idx2) <= 0;
        -POn(D+idx2-1) + POn(D+idx2) - startupp(D+idx2) <= 0;
cvx_end
optimisationRuntime_s = toc(optimisationTimer);

if ~strcmpi(cvx_status, 'Solved') && ~strcmpi(cvx_status, 'Inaccurate/Solved')
    error('CVX did not solve %s. Status = %s', flags.name, cvx_status);
end

solution = struct();
solution.x = x(:);
solution.isOn = isOn(:);
solution.POn = POn(:);
solution.status = string(cvx_status);
solution.objective = cvx_optval;
solution.optimisationRuntime_s = optimisationRuntime_s;
solution.modelStats = modelStats;

Result = reconstructResults(cfg, inputs, flags, dv, model, solution);
end
