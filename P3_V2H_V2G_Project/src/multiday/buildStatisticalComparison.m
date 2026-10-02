function T = buildStatisticalComparison(MULTIDAY, cfg)
%BUILDSTATISTICALCOMPARISON Paired statistical comparisons across regimes.

DailyMetrics = MULTIDAY.DailyMetrics;
defs = comparisonDefinitions();

T = table('Size', [0 18], ...
    'VariableTypes', {'string','string','string','string','string','double','double','double','double','double','double','double','double','double','double','double','double','string'}, ...
    'VariableNames', {'Comparison','Metric','BaselineRegime','AlternativeRegime','DifferenceDefinition', ...
    'PairedDays','MeanDifference','MedianDifference','StdDifference','MinimumDifference','MaximumDifference', ...
    'CI95Lower','CI95Upper','PairedTTestPValue','WilcoxonPValue','EffectSize_CohenDz', ...
    'PercentDaysImproved','Interpretation'});

for i = 1:height(defs)
    diffs = pairedDiffs(DailyMetrics, defs(i, :));
    diffs = diffs(isfinite(diffs));
    n = numel(diffs);
    if n == 0
        row = emptyRow(defs(i, :), T);
        T = [T; row]; %#ok<AGROW>
        continue
    end

    [ciLow, ciHigh] = confidenceInterval(diffs);
    pT = pairedTTestP(diffs);
    pW = wilcoxonP(diffs);
    sd = std(diffs);
    if n > 1 && isfinite(sd) && sd > 0
        dz = mean(diffs)/sd;
    else
        dz = NaN;
    end
    improved = sum(diffs > cfg.optimization.boundTolerance);
    worsened = sum(diffs < -cfg.optimization.boundTolerance);
    ties = n - improved - worsened; %#ok<NASGU>
    pctImproved = 100*improved/n;
    interpretation = interpretationLabel(mean(diffs), pctImproved, pT, pW, cfg.analysis.significanceAlpha);

    row = table(defs.Comparison(i), defs.Metric(i), defs.BaselineRegime(i), defs.AlternativeRegime(i), ...
        defs.DifferenceDefinition(i), n, mean(diffs), median(diffs), sd, min(diffs), max(diffs), ...
        ciLow, ciHigh, pT, pW, dz, pctImproved, interpretation, ...
        'VariableNames', T.Properties.VariableNames);
    T = [T; row]; %#ok<AGROW>
end

T.PositiveImprovementDays = positiveCounts(DailyMetrics, defs, cfg);
T.NegativeImprovementDays = negativeCounts(DailyMetrics, defs, cfg);
T.TieDays = tieCounts(DailyMetrics, defs, cfg);
T.TestAvailability = repmat(testAvailability(), height(T), 1);
T.Properties.Description = "Paired statistical comparison across valid solved days.";
end

function defs = comparisonDefinitions()
Comparison = [
    "V2H net cost vs V2H-Old net cost";
    "V2G net cost vs V2H net cost";
    "V2G net cost vs V2H-Old net cost";
    "V2G export energy vs V2H export energy";
    "V2G EV throughput vs V2H EV throughput";
    "V2G EV degradation cost vs V2H EV degradation cost";
    "V2G net grid energy vs V2H net grid energy"
    ];
Metric = [
    "net operating cost";
    "net operating cost";
    "net operating cost";
    "grid export energy";
    "EV throughput";
    "EV degradation cost";
    "net grid energy"
    ];
BaselineRegime = ["V2HOld"; "V2H"; "V2HOld"; "V2H"; "V2H"; "V2H"; "V2H"];
AlternativeRegime = ["V2H"; "V2G"; "V2G"; "V2G"; "V2G"; "V2G"; "V2G"];
Variable = [
    "NetOperatingCost_GBP_per_day";
    "NetOperatingCost_GBP_per_day";
    "NetOperatingCost_GBP_per_day";
    "GridExportEnergy_kWh_per_day";
    "EVThroughput_kWh_per_day";
    "EVDegradationCost_GBP_per_day";
    "NetGridEnergy_kWh_per_day"
    ];
Direction = [
    "baseline_minus_alternative";
    "baseline_minus_alternative";
    "baseline_minus_alternative";
    "alternative_minus_baseline";
    "alternative_minus_baseline";
    "alternative_minus_baseline";
    "baseline_minus_alternative"
    ];
DifferenceDefinition = [
    "positive means V2H is lower cost than V2H-Old";
    "positive means V2G is lower cost than V2H";
    "positive means V2G is lower cost than V2H-Old";
    "positive means V2G exports more energy than V2H";
    "positive means V2G uses more EV throughput than V2H";
    "positive means V2G has higher EV degradation cost than V2H";
    "positive means V2G has lower or more export-oriented net grid energy than V2H"
    ];
defs = table(Comparison, Metric, BaselineRegime, AlternativeRegime, Variable, Direction, DifferenceDefinition);
end

function row = emptyRow(def, T)
row = table(def.Comparison, def.Metric, def.BaselineRegime, def.AlternativeRegime, ...
    def.DifferenceDefinition, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
    "descriptive only", 'VariableNames', T.Properties.VariableNames);
end

function diffs = pairedDiffs(T, def)
dates = unique(T.Date);
diffs = NaN(numel(dates), 1);
for i = 1:numel(dates)
    a = value(T, dates(i), def.BaselineRegime, def.Variable);
    b = value(T, dates(i), def.AlternativeRegime, def.Variable);
    if def.Direction == "baseline_minus_alternative"
        diffs(i) = a - b;
    else
        diffs(i) = b - a;
    end
end
end

function x = value(T, dateValue, regime, variableName)
idx = T.Date == dateValue & T.Regime == regime & T.UseInSummary;
if any(idx)
    x = T.(variableName)(find(idx, 1));
else
    x = NaN;
end
end

function [lo, hi] = confidenceInterval(diffs)
n = numel(diffs);
if n < 2 || std(diffs) == 0
    lo = NaN;
    hi = NaN;
    return
end
if exist('tinv', 'file') == 2
    tcrit = tinv(0.975, n-1);
else
    tcrit = 1.96;
end
halfWidth = tcrit*std(diffs)/sqrt(n);
lo = mean(diffs) - halfWidth;
hi = mean(diffs) + halfWidth;
end

function p = pairedTTestP(diffs)
if exist('ttest', 'file') == 2 && numel(diffs) > 1 && std(diffs) > 0
    [~, p] = ttest(diffs);
else
    p = NaN;
end
end

function p = wilcoxonP(diffs)
nonzero = diffs(abs(diffs) > eps);
if exist('signrank', 'file') == 2 && numel(nonzero) > 1
    p = signrank(nonzero);
else
    p = NaN;
end
end

function label = interpretationLabel(meanDiff, pctImproved, pT, pW, alpha)
pAvailable = isfinite(pW) || isfinite(pT);
p = min([pW, pT], [], 'omitnan');
if pAvailable && p < alpha && meanDiff > 0 && pctImproved >= 80
    label = "strong evidence";
elseif pAvailable && p < alpha && meanDiff > 0
    label = "moderate evidence";
elseif meanDiff > 0 && pctImproved > 50
    label = "weak evidence";
else
    label = "descriptive only";
end
end

function c = positiveCounts(DailyMetrics, defs, cfg)
c = zeros(height(defs), 1);
for i = 1:height(defs)
    diffs = pairedDiffs(DailyMetrics, defs(i, :));
    c(i) = sum(isfinite(diffs) & diffs > cfg.optimization.boundTolerance);
end
end

function c = negativeCounts(DailyMetrics, defs, cfg)
c = zeros(height(defs), 1);
for i = 1:height(defs)
    diffs = pairedDiffs(DailyMetrics, defs(i, :));
    c(i) = sum(isfinite(diffs) & diffs < -cfg.optimization.boundTolerance);
end
end

function c = tieCounts(DailyMetrics, defs, cfg)
c = zeros(height(defs), 1);
for i = 1:height(defs)
    diffs = pairedDiffs(DailyMetrics, defs(i, :));
    diffs = diffs(isfinite(diffs));
    c(i) = sum(abs(diffs) <= cfg.optimization.boundTolerance);
end
end

function s = testAvailability()
parts = strings(0, 1);
if exist('ttest', 'file') == 2
    parts(end+1) = "paired t-test available";
else
    parts(end+1) = "paired t-test not available in current MATLAB installation";
end
if exist('signrank', 'file') == 2
    parts(end+1) = "Wilcoxon signed-rank available";
else
    parts(end+1) = "Wilcoxon signed-rank not available in current MATLAB installation";
end
s = strjoin(parts, "; ");
end
