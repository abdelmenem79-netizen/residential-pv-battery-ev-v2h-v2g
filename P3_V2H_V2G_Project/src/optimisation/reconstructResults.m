function Result = reconstructResults(cfg, inputs, flags, dv, model, solution)
%RECONSTRUCTRESULTS Convert solver variables into the standard P3 result API.

D = cfg.DPoints;
Dt = cfg.Dt;
x = solution.x(:);

PB_d = x(dv.idx.P_batt_discharge);
PB_c = x(dv.idx.P_batt_charge);
EV_d = x(dv.idx.P_ev_discharge);
EV_c = x(dv.idx.P_ev_charge);
PG_i = x(dv.idx.P_grid_import);
PG_e = x(dv.idx.P_grid_export);

P_app = cfg.appliances.dishwasher.power * solution.POn(1:D) + ...
    cfg.appliances.washingMachine.power * solution.POn(D+1:2*D);

P_batt_net = PB_d + PB_c;
P_ev_net = model.evDisCoeff(:).*EV_d + model.evChargeCoeff(:).*EV_c;
P_grid_net = PG_i - PG_e;

E_batt = cfg.battery.capacity * inputs.initialSOC.battery_pct / 100 - ...
    Dt*cumsum(PB_d/(cfg.battery.etaDischarge*cfg.battery.etaConverter) + ...
    cfg.battery.etaCharge*cfg.battery.etaConverter*PB_c);
SOC_batt = 100 * E_batt / cfg.battery.capacity;

E_ev = cfg.ev.capacity * inputs.initialSOC.ev_pct / 100 - ...
    Dt*cumsum(EV_d/cfg.ev.eta + cfg.ev.eta*EV_c) - ...
    cumsum(inputs.ev.trip.energyEvent_kWh(:));
SOC_ev = 100 * E_ev / cfg.ev.capacity;

importCost = Dt * sum(inputs.tariff.import(:).*PG_i(:));
if flags.exportRevenueEnabled
    exportRevenue = Dt * sum(inputs.tariff.export(:).*PG_e(:));
else
    exportRevenue = 0;
end

battDeg = Dt * sum(cfg.battery.price .* ( ...
    (cfg.battery.etaConverter*cfg.battery.etaCharge).*(-PB_c(:))./(2*cfg.battery.cycleLife*cfg.battery.capacity) + ...
    PB_d(:)./(cfg.battery.etaConverter*cfg.battery.etaDischarge*2*cfg.battery.cycleLife*cfg.battery.capacity)));
evDeg = Dt * sum(cfg.ev.price .* EV_d(:).*inputs.ev.available(:)./(2*cfg.ev.cycleLife*cfg.ev.capacity));
totalCost = importCost + battDeg + evDeg - exportRevenue;

powerBalanceLHS = P_batt_net + P_ev_net + P_grid_net - P_app;
powerBalanceRHS = inputs.P_load(:) - inputs.P_pv(:);

Result = struct();
Result.name = flags.label;
Result.regime = flags.name;
Result.time_h = inputs.time_h(:);
Result.P_load = inputs.P_load(:);
Result.P_pv = inputs.P_pv(:);
Result.P_app = P_app(:);
Result.P_grid_net = P_grid_net(:);
Result.P_grid_import = PG_i(:);
Result.P_grid_export = PG_e(:);
Result.P_ev_net = P_ev_net(:);
Result.P_ev_charge = max(-EV_c(:), 0);
Result.P_ev_discharge = max(EV_d(:), 0);
Result.P_batt_net = P_batt_net(:);
Result.P_batt_charge = max(-PB_c(:), 0);
Result.P_batt_discharge = max(PB_d(:), 0);
Result.SOC_batt = SOC_batt(:);
Result.SOC_ev = SOC_ev(:);
Result.EV_available = inputs.ev.available(:);
Result.P_balance_LHS = powerBalanceLHS(:);
Result.P_balance_RHS = powerBalanceRHS(:);

Result.cost.import = importCost;
Result.cost.exportRevenue = exportRevenue;
Result.cost.batteryDegradation = battDeg;
Result.cost.evDegradation = evDeg;
Result.cost.total = totalCost;
Result.cost.unit = "GBP/day";
Result.cost.signConvention = "total net cost = import + degradation - export revenue";

Result.validation = struct();
Result.solver.status = solution.status;
Result.solver.objective = solution.objective;
Result.solver.objectiveValue = solution.objective;
Result.solver.name = cfg.optimization.solver;

Result.runtime.optimisation_s = solution.optimisationRuntime_s;
Result.runtime.verification_s = NaN;
Result.runtime.total_s = NaN;

Result.model.timeSteps = solution.modelStats.timeSteps;
Result.model.continuousVariables = solution.modelStats.continuousVariables;
Result.model.binaryVariables = solution.modelStats.binaryVariables;
Result.model.binaryBreakdown = solution.modelStats.binaryBreakdown;

Result.raw.x = solution.x;
Result.raw.isOn = solution.isOn;
Result.raw.POn = solution.POn;
Result.raw.boundsLower = model.lb;
Result.raw.boundsUpper = model.ub;
Result.raw.powerBalanceMatrix = model.A1;
Result.raw.applianceMatrix = model.A10;
Result.raw.powerBalanceRHS = model.b1;
end
