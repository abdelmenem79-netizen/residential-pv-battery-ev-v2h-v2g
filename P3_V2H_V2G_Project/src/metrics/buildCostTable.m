function T = buildCostTable(RESULTS, cfg)
%BUILDCOSTTABLE Build Table II economic comparison.

regimes = cfg.project.regimeOrder;
importCost = zeros(1, numel(regimes));
exportRevenue = zeros(1, numel(regimes));
battDeg = zeros(1, numel(regimes));
evDeg = zeros(1, numel(regimes));
total = zeros(1, numel(regimes));

for k = 1:numel(regimes)
    R = RESULTS.(regimes(k));
    importCost(k) = R.cost.import;
    exportRevenue(k) = R.cost.exportRevenue;
    battDeg(k) = R.cost.batteryDegradation;
    evDeg(k) = R.cost.evDegradation;
    total(k) = R.cost.total;
end

improveVsOld = total(1) - total;
improveVsV2H = total(2) - total;

metric = [
    "Import cost"
    "Export revenue"
    "Battery degradation cost"
    "EV degradation cost"
    "Net operating cost"
    "Improvement vs V2H-Old"
    "Improvement vs V2H"
    ];

unit = repmat("GBP/day", numel(metric), 1);
values = [
    importCost
    exportRevenue
    battDeg
    evDeg
    total
    improveVsOld
    improveVsV2H
    ];

T = table(metric, unit, values(:,1), values(:,2), values(:,3), ...
    'VariableNames', {'Metric', 'Unit', char(regimes(1)), char(regimes(2)), char(regimes(3))});
T.Properties.Description = "Table II. Economic comparison across V2H-Old, V2H, and V2G.";
end

