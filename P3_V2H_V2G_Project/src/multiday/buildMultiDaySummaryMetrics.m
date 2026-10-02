function T = buildMultiDaySummaryMetrics(DailyMetrics, cfg, excludedBeforeSolving)
%BUILDMULTIDAYSUMMARYMETRICS Summarise daily metrics by regime.

if nargin < 3
    excludedBeforeSolving = 0;
end

metricInfo = [
    "GridImportEnergy_kWh_per_day", "Grid import energy", "kWh/day"
    "GridExportEnergy_kWh_per_day", "Grid export energy", "kWh/day"
    "NetGridEnergy_kWh_per_day", "Net grid energy", "kWh/day"
    "PeakGridImport_kW", "Peak grid import", "kW"
    "PeakGridExport_kW", "Peak grid export", "kW"
    "EVThroughput_kWh_per_day", "EV throughput", "kWh/day"
    "BatteryThroughput_kWh_per_day", "Battery throughput", "kWh/day"
    "EVSOCMin_pct", "EV SOC minimum", "%"
    "ImportCost_GBP_per_day", "Import cost", "GBP/day"
    "ExportRevenue_GBP_per_day", "Export revenue", "GBP/day"
    "BatteryDegradationCost_GBP_per_day", "Battery degradation cost", "GBP/day"
    "EVDegradationCost_GBP_per_day", "EV degradation cost", "GBP/day"
    "NetOperatingCost_GBP_per_day", "Net operating cost", "GBP/day"
    "ImprovementVsV2HOld_GBP_per_day", "Improvement vs V2H-Old", "GBP/day"
    "ImprovementVsV2H_GBP_per_day", "Improvement vs V2H", "GBP/day"
    ];

regimes = cfg.project.regimeOrder;
T = table('Size', [0 16], ...
    'VariableTypes', {'string','string','string','double','double','double','double','double','double','double','double','double','double','double','double','double'}, ...
    'VariableNames', {'Metric','SourceVariable','Regime','Mean','Median','Std','Minimum','Maximum','P25','P75','IQR','CoefficientOfVariation','ValidDays','SolvedDays','FailedDays','ExcludedBeforeSolving'});

for m = 1:size(metricInfo, 1)
    sourceVariable = metricInfo(m, 1);
    metricName = metricInfo(m, 2) + " (" + metricInfo(m, 3) + ")";
    for r = 1:numel(regimes)
        regime = regimes(r);
        rows = DailyMetrics.Regime == regime;
        usable = rows & DailyMetrics.UseInSummary;
        values = DailyMetrics.(sourceVariable)(usable);
        values = values(isfinite(values));
        solvedDays = sum(usable);
        validDays = sum(rows);
        failedDays = validDays - solvedDays;
        meanValue = meanOrNaN(values);
        stdValue = stdOrNaN(values);
        p25 = percentileLocal(values, 25);
        p75 = percentileLocal(values, 75);
        row = table(metricName, sourceVariable, regime, ...
            meanValue, medianOrNaN(values), stdValue, ...
            minOrNaN(values), maxOrNaN(values), p25, p75, p75-p25, ...
            coefficientOfVariation(meanValue, stdValue), validDays, solvedDays, failedDays, excludedBeforeSolving, ...
            'VariableNames', T.Properties.VariableNames);
        T = [T; row]; %#ok<AGROW>
    end
end
T.Properties.Description = "Multi-day summary metrics by regime.";
end

function x = meanOrNaN(v)
if isempty(v), x = NaN; else, x = mean(v); end
end

function x = medianOrNaN(v)
if isempty(v), x = NaN; else, x = median(v); end
end

function x = stdOrNaN(v)
if numel(v) < 2, x = NaN; else, x = std(v); end
end

function x = minOrNaN(v)
if isempty(v), x = NaN; else, x = min(v); end
end

function x = maxOrNaN(v)
if isempty(v), x = NaN; else, x = max(v); end
end

function x = coefficientOfVariation(mu, sigma)
if isfinite(mu) && abs(mu) > eps && isfinite(sigma)
    x = sigma/abs(mu);
else
    x = NaN;
end
end

function p = percentileLocal(v, q)
v = sort(v(isfinite(v)));
if isempty(v)
    p = NaN;
    return
end
if numel(v) == 1
    p = v;
    return
end
pos = 1 + (numel(v)-1)*q/100;
lo = floor(pos);
hi = ceil(pos);
if lo == hi
    p = v(lo);
else
    p = v(lo) + (pos-lo)*(v(hi)-v(lo));
end
end
