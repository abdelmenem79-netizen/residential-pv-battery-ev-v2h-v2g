function T = buildMultiDayStatistics(DailyMetrics, cfg)
%BUILDMULTIDAYSTATISTICS Build simple paired economic comparisons.

comparisons = [
    "V2H net cost minus V2G net cost", "V2H", "V2G"
    "V2H-Old net cost minus V2H net cost", "V2HOld", "V2H"
    "V2H-Old net cost minus V2G net cost", "V2HOld", "V2G"
    ];

T = table('Size', [0 13], ...
    'VariableTypes', {'string','string','string','double','double','double','double','double','double','double','double','double','string'}, ...
    'VariableNames', {'Comparison','PositiveMeans','NegativeMeans','PairedDays','MeanDifference_GBP_per_day', ...
    'StdDifference_GBP_per_day','CI95Lower_GBP_per_day','CI95Upper_GBP_per_day', ...
    'ImprovedDays','WorsenedDays','TieDays','WilcoxonPValue','Method'});

for i = 1:size(comparisons, 1)
    label = comparisons(i, 1);
    regimeA = comparisons(i, 2);
    regimeB = comparisons(i, 3);
    diffs = pairedDifferences(DailyMetrics, regimeA, regimeB);
    diffs = diffs(isfinite(diffs));

    n = numel(diffs);
    if n == 0
        row = table(label, regimeA, regimeB, 0, NaN, NaN, NaN, NaN, 0, 0, 0, NaN, "no paired solved days", ...
            'VariableNames', T.Properties.VariableNames);
        T = [T; row]; %#ok<AGROW>
        continue
    end

    meanDiff = mean(diffs);
    sdDiff = std(diffs);
    if n > 1 && isfinite(sdDiff)
        tcrit = localTcrit(n-1);
        halfWidth = tcrit*sdDiff/sqrt(n);
    else
        halfWidth = NaN;
    end

    improved = sum(diffs > cfg.optimization.boundTolerance);
    worsened = sum(diffs < -cfg.optimization.boundTolerance);
    ties = n - improved - worsened;
    [pValue, method] = localSignedTest(diffs);

    row = table(label, regimeA, regimeB, n, meanDiff, sdDiff, ...
        meanDiff - halfWidth, meanDiff + halfWidth, improved, worsened, ties, pValue, method, ...
        'VariableNames', T.Properties.VariableNames);
    T = [T; row]; %#ok<AGROW>
end
T.Properties.Description = "Simple paired comparisons of daily net operating cost.";
end

function diffs = pairedDifferences(T, regimeA, regimeB)
dates = unique(T.Date);
diffs = NaN(numel(dates), 1);
for i = 1:numel(dates)
    a = value(T, dates(i), regimeA);
    b = value(T, dates(i), regimeB);
    diffs(i) = a - b;
end
end

function x = value(T, dateValue, regime)
idx = T.Date == dateValue & T.Regime == regime & T.UseInSummary;
if any(idx)
    x = T.NetOperatingCost_GBP_per_day(find(idx, 1));
else
    x = NaN;
end
end

function tcrit = localTcrit(df)
if exist('tinv', 'file') == 2
    tcrit = tinv(0.975, df);
else
    tcrit = 1.96;
end
end

function [pValue, method] = localSignedTest(diffs)
nonzero = diffs(abs(diffs) > eps);
if isempty(nonzero)
    pValue = 1;
    method = "all paired differences are ties";
elseif exist('signrank', 'file') == 2 && numel(nonzero) > 1
    pValue = signrank(nonzero);
    method = "Wilcoxon signed-rank";
else
    pValue = NaN;
    method = "sign-count summary only";
end
end
