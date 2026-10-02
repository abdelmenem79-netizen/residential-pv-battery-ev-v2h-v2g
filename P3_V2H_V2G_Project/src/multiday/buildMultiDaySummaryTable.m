function T = buildMultiDaySummaryTable(DailyMetrics, Screening, cfg)
%BUILDMULTIDAYSUMMARYTABLE Compatibility wrapper for summary statistics.

if nargin < 2 || isempty(Screening)
    excludedCount = 0;
else
    excludedCount = height(Screening.ExcludedDays);
end
T = buildMultiDaySummaryMetrics(DailyMetrics, cfg, excludedCount);
end
