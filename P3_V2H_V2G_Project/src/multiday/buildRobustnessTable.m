function T = buildRobustnessTable(DailyMetrics, cfg)
%BUILDROBUSTNESSTABLE Compatibility wrapper for regime robustness metrics.

T = buildMultiDayRegimeComparison(DailyMetrics, cfg);
end
