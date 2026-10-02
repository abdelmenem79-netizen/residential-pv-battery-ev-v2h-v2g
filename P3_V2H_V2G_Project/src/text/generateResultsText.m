function Text = generateResultsText(RESULTS, TABLES, cfg)
%GENERATERESULTSTEXT Generate value-grounded P3 results wording.

op = TABLES.Operational;
cost = TABLES.Economic;
sens = TABLES.TariffSensitivity;

impOld = val(op, "Grid import energy", "V2HOld");
impH = val(op, "Grid import energy", "V2H");
impG = val(op, "Grid import energy", "V2G");
expOld = val(op, "Grid export energy", "V2HOld");
expH = val(op, "Grid export energy", "V2H");
expG = val(op, "Grid export energy", "V2G");
netOld = val(op, "Net grid energy", "V2HOld");
netH = val(op, "Net grid energy", "V2H");
netG = val(op, "Net grid energy", "V2G");

costOld = val(cost, "Net operating cost", "V2HOld");
costH = val(cost, "Net operating cost", "V2H");
costG = val(cost, "Net operating cost", "V2G");
revG = val(cost, "Export revenue", "V2G");

Text = struct();
Text.operational_results = sprintf([ ...
    'The daily grid import energy is %.3f kWh for V2H-Old, %.3f kWh for corrected V2H, and %.3f kWh for V2G. ', ...
    'The corresponding export energy is %.3f, %.3f, and %.3f kWh/day, respectively. ', ...
    'Net grid energy changes from %.3f kWh/day in V2H-Old to %.3f kWh/day in corrected V2H and %.3f kWh/day in V2G.'], ...
    impOld, impH, impG, expOld, expH, expG, netOld, netH, netG);

Text.economic_results = sprintf([ ...
    'Using the stated sign convention, net operating cost is %.3f GBP/day for V2H-Old, %.3f GBP/day for corrected V2H, and %.3f GBP/day for V2G. ', ...
    'The V2G case earns %.3f GBP/day of export revenue. A negative net cost indicates net operating revenue over the simulated day.'], ...
    costOld, costH, costG, revG);

Text.validation_results = sprintf([ ...
    'Maximum power-balance errors are %s kW, %s kW, and %s kW for V2H-Old, V2H, and V2G. ', ...
    'Validation pass/fail outcomes are reported separately in Table III because P3 economic conclusions depend on the physical credibility inherited from the P2 model checks.'], ...
    string(TABLES.Validation.V2HOld(1)), string(TABLES.Validation.V2H(1)), string(TABLES.Validation.V2G(1)));

low = sens(1, :);
high = sens(end, :);
Text.tariff_sensitivity_results = sprintf([ ...
    'In the low tariff case, the V2G benefit against corrected V2H is %.3f GBP/day. ', ...
    'In the high tariff case, the same benefit is %.3f GBP/day. ', ...
    'These values are daily fixed-dispatch sensitivity values, not annualised costs.'], ...
    low.V2GBenefitAgainstV2H_GBP_per_day, high.V2GBenefitAgainstV2H_GBP_per_day);

Text.unit_note = 'All power values are in kW, daily energy values are in kWh/day, tariffs are in GBP/kWh, and daily operating costs are in GBP/day.';
Text.sign_convention = 'Positive cost is an expense. Export revenue is subtracted from import and degradation costs: total net cost = import cost + battery degradation cost + EV degradation cost - export revenue.';

Text.run_context = sprintf('Case-study day %.0f was simulated using %.0f samples of %.4f h each.', ...
    cfg.case.date, cfg.DPoints, cfg.Dt);
Text.result_timestamp = string(datetime('now'));
Text.source_regime_status = sprintf('Solver statuses: V2H-Old=%s, V2H=%s, V2G=%s.', ...
    RESULTS.V2HOld.solver.status, RESULTS.V2H.solver.status, RESULTS.V2G.solver.status);
end

function out = val(T, metric, regime)
idx = T.Metric == metric;
out = T.(regime)(idx);
end

