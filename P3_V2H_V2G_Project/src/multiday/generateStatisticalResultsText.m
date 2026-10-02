function text = generateStatisticalResultsText(MULTIDAY, cfg)
%GENERATESTATISTICALRESULTSTEXT Summarise paired statistical evidence.

S = MULTIDAY.StatisticalResults;
target = "V2G net cost vs V2H net cost";
idx = S.Comparison == target;
if ~any(idx)
    text = "No paired V2H/V2G statistical comparison was available because no solved paired days were found.";
    return
end

row = S(find(idx, 1), :);
pText = pValueText(row.PairedTTestPValue, row.WilcoxonPValue);
ciText = ciValueText(row.CI95Lower, row.CI95Upper);
toolText = string(row.TestAvailability);

text = sprintf(['The paired comparisons are made on the same valid days across all three regimes, which reduces the influence of ' ...
    'day-to-day variation in PV generation, household demand, and EV availability. For V2G versus corrected V2H net operating cost, ' ...
    'the mean paired difference is %s GBP/day using the convention "%s". The median paired difference is %s GBP/day, with %d ' ...
    'improving day(s), %d worsening day(s), and %d tie(s). %s %s The evidence label is "%s". Test availability: %s.'], ...
    fmt(row.MeanDifference), string(row.DifferenceDefinition), fmt(row.MedianDifference), ...
    row.PositiveImprovementDays, row.NegativeImprovementDays, row.TieDays, ciText, pText, ...
    string(row.Interpretation), toolText);

if all(~isfinite([row.PairedTTestPValue, row.WilcoxonPValue]))
    text = text + " Statistical p-values are not reported when the required MATLAB statistical functions are unavailable; the sign-count evidence is reported instead.";
elseif min([row.PairedTTestPValue, row.WilcoxonPValue], [], 'omitnan') >= cfg.analysis.significanceAlpha
    text = text + " The result should therefore be described as robustness evidence, not as statistically significant evidence.";
end
end

function s = pValueText(pT, pW)
parts = strings(0, 1);
if isfinite(pT)
    parts(end+1) = "paired t-test p=" + string(compose('%.4g', pT));
end
if isfinite(pW)
    parts(end+1) = "Wilcoxon signed-rank p=" + string(compose('%.4g', pW));
end
if isempty(parts)
    s = "No p-value is available in the current MATLAB installation.";
else
    s = "Available test result(s): " + strjoin(parts, "; ") + ".";
end
end

function s = ciValueText(lo, hi)
if isfinite(lo) && isfinite(hi)
    s = "The 95% confidence interval for the mean difference is [" + ...
        string(compose('%.3f', lo)) + ", " + string(compose('%.3f', hi)) + "] GBP/day.";
else
    s = "A 95% confidence interval is not available for this comparison.";
end
end

function s = fmt(x)
if isfinite(x)
    s = char(compose('%.3f', x));
else
    s = 'not available';
end
end
