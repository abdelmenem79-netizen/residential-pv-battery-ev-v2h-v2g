function T = buildMultiDayTariffSensitivity(DailyMetrics, cfg)
%BUILDMULTIDAYTARIFFSENSITIVITY Apply tariff cases to solved daily dispatches.

cases = cfg.tariff.sensitivityCases;
T = table('Size', [height(cases), 10], ...
    'VariableTypes', {'string','double','double','double','double','double','double','double','double','string'}, ...
    'VariableNames', {'TariffCase','ImportTariff_GBP_per_kWh','ExportTariff_GBP_per_kWh', ...
    'V2HOldMeanCost_GBP_per_day','V2HMeanCost_GBP_per_day','V2GMeanCost_GBP_per_day', ...
    'V2HBenefitVsOld_GBP_per_day','V2GBenefitVsV2H_GBP_per_day', ...
    'V2GBenefitVsOld_GBP_per_day','Note'});

for i = 1:height(cases)
    imp = cases.ImportTariff_GBP_per_kWh(i);
    exp = cases.ExportTariff_GBP_per_kWh(i);
    oldCost = meanScenarioCost(DailyMetrics, "V2HOld", imp, exp);
    v2hCost = meanScenarioCost(DailyMetrics, "V2H", imp, exp);
    v2gCost = meanScenarioCost(DailyMetrics, "V2G", imp, exp);

    T(i, :) = table(string(cases.TariffCase(i)), imp, exp, oldCost, v2hCost, v2gCost, ...
        oldCost - v2hCost, v2hCost - v2gCost, oldCost - v2gCost, ...
        "Fixed-dispatch multi-day tariff sensitivity; dispatch is not re-optimised.", ...
        'VariableNames', T.Properties.VariableNames);
end
T.Properties.Description = "Multi-day tariff sensitivity using fixed solved dispatch profiles.";
end

function cost = meanScenarioCost(DailyMetrics, regime, importTariff, exportTariff)
rows = DailyMetrics.Regime == regime & DailyMetrics.UseInSummary;
if ~any(rows)
    cost = NaN;
    return
end
dailyCost = importTariff*DailyMetrics.GridImportEnergy_kWh_per_day(rows) + ...
    DailyMetrics.BatteryDegradationCost_GBP_per_day(rows) + ...
    DailyMetrics.EVDegradationCost_GBP_per_day(rows) - ...
    exportTariff*DailyMetrics.GridExportEnergy_kWh_per_day(rows);
cost = mean(dailyCost, 'omitnan');
end
