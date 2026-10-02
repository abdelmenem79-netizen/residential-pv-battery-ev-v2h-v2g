function objective = buildObjective(cfg, inputs, vars, flags)
%BUILDOBJECTIVE Build the P3 economic objective from CVX expressions.

Dt = cfg.Dt;

objective = struct();
objective.importCost = Dt * sum(inputs.tariff.import(:) .* vars.P_grid_import(:));

if flags.exportRevenueEnabled
    objective.exportRevenue = Dt * sum(inputs.tariff.export(:) .* vars.P_grid_export(:));
else
    objective.exportRevenue = 0;
end

objective.batteryDegradation = Dt * sum(cfg.battery.price .* ( ...
    (cfg.battery.etaConverter * cfg.battery.etaCharge) .* (-vars.P_batt_charge(:)) ./ ...
        (2*cfg.battery.cycleLife*cfg.battery.capacity) + ...
    vars.P_batt_discharge(:) ./ ...
        (cfg.battery.etaConverter*cfg.battery.etaDischarge*2*cfg.battery.cycleLife*cfg.battery.capacity)));

objective.evDegradation = Dt * sum(cfg.ev.price .* vars.P_ev_discharge(:) .* inputs.ev.available(:) ./ ...
    (2*cfg.ev.cycleLife*cfg.ev.capacity));

objective.total = objective.importCost + objective.batteryDegradation + ...
    objective.evDegradation - objective.exportRevenue;
end

