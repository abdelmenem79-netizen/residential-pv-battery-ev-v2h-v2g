function T = buildMultiDayRegimeComparison(DailyMetrics, cfg)
%BUILDMULTIDAYREGIMECOMPARISON Build robustness comparison indicators.

pairs = buildDailyPairTable(DailyMetrics);
n = height(pairs);

if n == 0
    metrics = [
        "Average V2H benefit vs V2H-Old";
        "Average V2G benefit vs V2H";
        "Average V2G benefit vs V2H-Old";
        "Percentage of days where V2G has the lowest net operating cost";
        "Percentage of days where V2G exports more than V2H";
        "Percentage of days where V2G becomes net exporter";
        "Worst-case V2G benefit vs V2H";
        "Best-case V2G benefit vs V2H"
        ];
    T = table(metrics, repmat("not available", numel(metrics), 1), NaN(numel(metrics), 1), ...
        'VariableNames', {'Metric','Unit','Value'});
    return
end

benefitV2HVsOld = pairs.CostOld - pairs.CostV2H;
benefitV2GVsV2H = pairs.CostV2H - pairs.CostV2G;
benefitV2GVsOld = pairs.CostOld - pairs.CostV2G;

v2gLowest = pairs.CostV2G <= min([pairs.CostOld, pairs.CostV2H, pairs.CostV2G], [], 2);
v2gExportsMore = pairs.ExportV2G > pairs.ExportV2H;
v2gNetExporter = pairs.NetGridV2G < 0;

Metric = [
    "Average V2H benefit vs V2H-Old";
    "Average V2G benefit vs V2H";
    "Average V2G benefit vs V2H-Old";
    "Median V2G benefit vs V2H";
    "Worst-case V2G benefit vs V2H";
    "Best-case V2G benefit vs V2H";
    "Percentage of days where V2G has the lowest net operating cost";
    "Percentage of days where V2G exports more than V2H";
    "Percentage of days where V2G becomes net exporter";
    "Percentage of days where V2G passes all validation checks";
    "Percentage of days where V2H passes all validation checks";
    "Percentage of days where V2H-Old fails EV availability";
    "Solved paired days"
    ];
Unit = [
    "GBP/day";
    "GBP/day";
    "GBP/day";
    "GBP/day";
    "GBP/day";
    "GBP/day";
    "%";
    "%";
    "%";
    "%";
    "%";
    "%";
    "days"
    ];
Value = [
    mean(benefitV2HVsOld)
    mean(benefitV2GVsV2H)
    mean(benefitV2GVsOld)
    median(benefitV2GVsV2H)
    min(benefitV2GVsV2H)
    max(benefitV2GVsV2H)
    100*mean(v2gLowest)
    100*mean(v2gExportsMore)
    100*mean(v2gNetExporter)
    validationPercent(DailyMetrics, "V2G")
    validationPercent(DailyMetrics, "V2H")
    100*mean(~DailyMetrics.EVAvailabilityPass(DailyMetrics.Regime == "V2HOld"))
    n
    ];

T = table(Metric, Unit, Value);
T.Properties.Description = "Robustness comparison across solved paired days.";
end

function pct = validationPercent(T, regime)
rows = T.Regime == regime;
if ~any(rows)
    pct = NaN;
else
    pct = 100*mean(T.PowerBalancePass(rows) & T.BoundsPass(rows) & ...
        T.GridLogicPass(rows) & T.EVAvailabilityPass(rows) & T.SolverSolved(rows));
end
end

function P = buildDailyPairTable(DailyMetrics)
dates = unique(DailyMetrics.Date);
P = table('Size', [0 10], ...
    'VariableTypes', {'double','string','double','double','double','double','double','double','double','double'}, ...
    'VariableNames', {'Date','DateLabel','CostOld','CostV2H','CostV2G','ExportOld','ExportV2H','ExportV2G','NetGridV2H','NetGridV2G'});

for i = 1:numel(dates)
    rows = DailyMetrics.Date == dates(i) & DailyMetrics.UseInSummary;
    if ~all(ismember(["V2HOld","V2H","V2G"], DailyMetrics.Regime(rows)))
        continue
    end
    row = table(dates(i), dateLabel(DailyMetrics, dates(i)), ...
        value(DailyMetrics, dates(i), "V2HOld", "NetOperatingCost_GBP_per_day"), ...
        value(DailyMetrics, dates(i), "V2H", "NetOperatingCost_GBP_per_day"), ...
        value(DailyMetrics, dates(i), "V2G", "NetOperatingCost_GBP_per_day"), ...
        value(DailyMetrics, dates(i), "V2HOld", "GridExportEnergy_kWh_per_day"), ...
        value(DailyMetrics, dates(i), "V2H", "GridExportEnergy_kWh_per_day"), ...
        value(DailyMetrics, dates(i), "V2G", "GridExportEnergy_kWh_per_day"), ...
        value(DailyMetrics, dates(i), "V2H", "NetGridEnergy_kWh_per_day"), ...
        value(DailyMetrics, dates(i), "V2G", "NetGridEnergy_kWh_per_day"), ...
        'VariableNames', P.Properties.VariableNames);
    P = [P; row]; %#ok<AGROW>
end
end

function x = value(T, dateValue, regime, varName)
idx = T.Date == dateValue & T.Regime == regime & T.UseInSummary;
if any(idx)
    x = T.(varName)(find(idx, 1));
else
    x = NaN;
end
end

function s = dateLabel(T, dateValue)
idx = T.Date == dateValue;
if any(idx)
    s = T.DateLabel(find(idx, 1));
else
    s = "";
end
end
