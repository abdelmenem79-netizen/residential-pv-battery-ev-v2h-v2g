function Text = generateDiscussionText(RESULTS, TABLES, cfg)
%GENERATEDISCUSSIONTEXT Generate concise P3 discussion wording from results.

op = TABLES.Operational;
cost = TABLES.Economic;
sens = TABLES.TariffSensitivity;

peakImpOld = val(op, "Peak grid import", "V2HOld");
peakImpH = val(op, "Peak grid import", "V2H");
peakImpG = val(op, "Peak grid import", "V2G");
peakExpG = val(op, "Peak grid export", "V2G");

evDisH = val(op, "EV discharge energy", "V2H");
evDisG = val(op, "EV discharge energy", "V2G");
evChgH = val(op, "EV charge energy", "V2H");
evChgG = val(op, "EV charge energy", "V2G");

battMinG = val(op, "Battery SOC minimum", "V2G");
evMinG = val(op, "EV SOC minimum", "V2G");

revH = val(cost, "Export revenue", "V2H");
revG = val(cost, "Export revenue", "V2G");

Text = struct();
Text.grid_power_discussion = sprintf([ ...
    'Peak grid import is %.3f kW in V2H-Old, %.3f kW in corrected V2H, and %.3f kW in V2G. ', ...
    'The V2G peak export is %.3f kW, which is the operational signature of the market-aware case rather than a household-only dispatch.'], ...
    peakImpOld, peakImpH, peakImpG, peakExpG);

Text.ev_power_discussion = sprintf([ ...
    'Corrected V2H charges and discharges the EV by %.3f and %.3f kWh/day, respectively. ', ...
    'V2G changes these values to %.3f and %.3f kWh/day, showing the EV acting as an economic asset when export revenue is available.'], ...
    evChgH, evDisH, evChgG, evDisG);

Text.soc_discussion = sprintf([ ...
    'The V2G battery and EV SOC trajectories remain within their configured limits; the minimum battery and EV SOC values are %.2f%% and %.2f%%. ', ...
    'The SOC result is therefore interpreted as a constrained economic dispatch rather than an unconstrained export maximisation.'], ...
    battMinG, evMinG);

Text.economic_discussion = sprintf([ ...
    'Corrected V2H earns %.3f GBP/day of export revenue, while V2G earns %.3f GBP/day. ', ...
    'The key P3 comparison is therefore not only reduced import cost but the change in net cost after export revenue and degradation costs are both included.'], ...
    revH, revG);

Text.tariff_sensitivity_discussion = sprintf([ ...
    'Across the configured low, medium, and high tariff cases, the V2G benefit against corrected V2H ranges from %.3f to %.3f GBP/day. ', ...
    'The sensitivity table reports daily values and should only be annualised by multiplying by 365 when explicitly required.'], ...
    min(sens.V2GBenefitAgainstV2H_GBP_per_day), max(sens.V2GBenefitAgainstV2H_GBP_per_day));

Text.limitations_wording = sprintf([ ...
    'The tariff sensitivity uses fixed dispatch profiles unless cfg.tariff.sensitivityCases is paired with additional optimisation runs. ', ...
    'The default case is therefore suitable for isolating export-price economics, while a full market-participation study would re-optimise dispatch under each tariff pair. ', ...
    'The V2H-Old case is retained as a restrictive legacy baseline; corrected V2H and V2G are the physically gated cases used for economic interpretation in P3.']);

Text.unit_note = sprintf('The project reports costs in GBP/day. Annual values, if needed, are daily values multiplied by 365.');
Text.regime_note = sprintf('Regime order is fixed as %s, %s, %s in all figures and tables.', ...
    cfg.project.regimeLabels(1), cfg.project.regimeLabels(2), cfg.project.regimeLabels(3));
end

function out = val(T, metric, regime)
idx = T.Metric == metric;
out = T.(regime)(idx);
end

