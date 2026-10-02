function FIGURES = plotMultiDayFigures(MULTIDAY, cfg)
%PLOTMULTIDAYFIGURES Create IEEE-ready multi-day robustness figures.

FIGURES = struct('handle', {}, 'baseName', {}, 'caption', {});
FIGURES(end+1) = plotScreeningSummary(MULTIDAY, cfg);

T = MULTIDAY.DailyMetrics(MULTIDAY.DailyMetrics.UseInSummary, :);
if isempty(T)
    return
end

FIGURES(end+1) = plotDailyNetCost(T, cfg);
FIGURES(end+1) = plotNetCostDistribution(T, cfg);
FIGURES(end+1) = plotDailyExportEnergy(T, cfg);
FIGURES(end+1) = plotV2GBenefit(T, cfg);
FIGURES(end+1) = plotDailyNetGridEnergy(T, cfg);
FIGURES(end+1) = plotEVThroughputTradeoff(T, cfg);
FIGURES(end+1) = plotSelectionMap(MULTIDAY.SelectedDays, cfg);
FIGURES(end+1) = plotStatisticalSummary(MULTIDAY.StatisticalResults, cfg);
end

function info = plotScreeningSummary(MULTIDAY, cfg)
fig = baseFigure('Figure M1 Screening Summary', cfg, 8);
ax = axes(fig);
candidate = MULTIDAY.Screening.Summary.CandidateDays(1);
valid = MULTIDAY.Screening.Summary.ValidDays(1);
excluded = MULTIDAY.Screening.Summary.ExcludedDays(1);
solverFailed = sum(~MULTIDAY.RunLog.SolverSolved);
bar(ax, [candidate, valid, excluded, solverFailed]);
set(ax, 'XTick', 1:4, 'XTickLabel', ["Candidate","Valid","Excluded","Solver failed"]);
xtickangle(ax, 20);
ylabel(ax, 'Count');
applyIEEEStyle(fig, cfg);
info = localInfo(fig, 'FigM1_multiday_valid_excluded_summary', ...
    'Valid and excluded day summary, including solver-failed regime runs.');
end

function info = plotDailyNetCost(T, cfg)
fig = baseFigure('Figure A Daily Net Operating Cost', cfg, 11);
ax = axes(fig);
[labels, values] = pivotByDate(T, "NetOperatingCost_GBP_per_day", cfg);
plot(ax, 1:numel(labels), values, 'o-', 'LineWidth', cfg.figure.lineWidth);
set(ax, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(ax, 35);
ylabel(ax, 'Net cost (GBP/day)');
legend(ax, cfg.project.regimeLabels, 'Location', 'best', 'Box', 'off');
applyIEEEStyle(fig, cfg);
info = localInfo(fig, 'FigM2_multiday_daily_net_operating_cost', ...
    'Daily net operating cost by regime across selected representative days.');
end

function info = plotNetCostDistribution(T, cfg)
fig = baseFigure('Figure B Net Cost Distribution', cfg, 8);
ax = axes(fig);
regimes = cfg.project.regimeOrder;
labels = cfg.project.regimeLabels;
hold(ax, 'on');
for r = 1:numel(regimes)
    rows = T.Regime == regimes(r);
    y = T.NetOperatingCost_GBP_per_day(rows);
    if ~isempty(y)
        x = r + linspace(-0.08, 0.08, numel(y)).';
        scatter(ax, x, y, 24, 'filled', 'MarkerFaceAlpha', 0.65);
        plot(ax, [r-0.22, r+0.22], [median(y), median(y)], 'k-', 'LineWidth', 1.2);
    end
end
hold(ax, 'off');
set(ax, 'XTick', 1:numel(labels), 'XTickLabel', labels);
ylabel(ax, 'Net cost (GBP/day)');
applyIEEEStyle(fig, cfg);
info = localInfo(fig, 'FigM3_multiday_cost_distribution', ...
    'Distribution of daily net operating cost across representative days.');
end

function info = plotDailyExportEnergy(T, cfg)
fig = baseFigure('Figure C Daily Export Energy', cfg, 11);
ax = axes(fig);
[labels, values] = pivotByDate(T, "GridExportEnergy_kWh_per_day", cfg);
plot(ax, 1:numel(labels), values, 'o-', 'LineWidth', cfg.figure.lineWidth);
set(ax, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(ax, 35);
ylabel(ax, 'Export energy (kWh/day)');
legend(ax, cfg.project.regimeLabels, 'Location', 'best', 'Box', 'off');
applyIEEEStyle(fig, cfg);
info = localInfo(fig, 'FigM5_multiday_daily_export_energy', ...
    'Daily grid export energy by regime across selected representative days.');
end

function info = plotV2GBenefit(T, cfg)
fig = baseFigure('Figure D V2G Benefit', cfg, 8);
ax = axes(fig);
dates = unique(T.Date);
labels = strings(numel(dates), 1);
benefit = NaN(numel(dates), 1);
for i = 1:numel(dates)
    labels(i) = dateLabel(T, dates(i));
    benefit(i) = value(T, dates(i), "V2H", "NetOperatingCost_GBP_per_day") - ...
        value(T, dates(i), "V2G", "NetOperatingCost_GBP_per_day");
end
bar(ax, benefit);
hold(ax, 'on');
yline(ax, 0, 'k-', 'LineWidth', 0.9);
meanBenefit = mean(benefit, 'omitnan');
if isfinite(meanBenefit)
    yline(ax, meanBenefit, 'k--', 'LineWidth', 0.9);
end
hold(ax, 'off');
set(ax, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(ax, 35);
ylabel(ax, 'V2G benefit vs V2H (GBP/day)');
applyIEEEStyle(fig, cfg);
info = localInfo(fig, 'FigM4_multiday_v2g_benefit_vs_v2h', ...
    'Daily V2G economic benefit relative to corrected V2H.');
end

function info = plotDailyNetGridEnergy(T, cfg)
fig = baseFigure('Figure M6 Daily Net Grid Energy', cfg, 11);
ax = axes(fig);
[labels, values] = pivotByDate(T, "NetGridEnergy_kWh_per_day", cfg);
plot(ax, 1:numel(labels), values, 'o-', 'LineWidth', cfg.figure.lineWidth);
set(ax, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(ax, 35);
legend(ax, cfg.project.regimeLabels, 'Location', 'best', 'Box', 'off');
yline(ax, 0, 'k-', 'LineWidth', 0.9);
ylabel(ax, 'Net grid energy (kWh/day)');
applyIEEEStyle(fig, cfg);
info = localInfo(fig, 'FigM6_multiday_daily_net_grid_energy', ...
    'Daily net grid energy by regime; negative values indicate net-export days.');
end

function info = plotEVThroughputTradeoff(T, cfg)
fig = baseFigure('Figure M7 EV Throughput Trade-off', cfg, 8);
ax = axes(fig);
hold(ax, 'on');
rowsV2H = T.Regime == "V2H";
rowsV2G = T.Regime == "V2G";
scatter(ax, T.EVThroughput_kWh_per_day(rowsV2H), T.EVDegradationCost_GBP_per_day(rowsV2H), ...
    28, 'filled', 'MarkerFaceAlpha', 0.65);
scatter(ax, T.EVThroughput_kWh_per_day(rowsV2G), T.EVDegradationCost_GBP_per_day(rowsV2G), ...
    28, 'filled', 'MarkerFaceAlpha', 0.65);
hold(ax, 'off');
xlabel(ax, 'EV throughput (kWh/day)');
ylabel(ax, 'EV degradation cost (GBP/day)');
legend(ax, ["V2H","V2G"], 'Location', 'best', 'Box', 'off');
applyIEEEStyle(fig, cfg);
info = localInfo(fig, 'FigM7_multiday_ev_throughput_degradation_tradeoff', ...
    'EV throughput and degradation-cost trade-off for corrected V2H and V2G.');
end

function info = plotSelectionMap(selectedDays, cfg)
fig = baseFigure('Figure F Representative-Day Selection Map', cfg, 8);
ax = axes(fig);
scatter(ax, selectedDays.LoadEnergy_kWh, selectedDays.PVEnergy_kWh, ...
    42 + 4*selectedDays.EVTripEnergy_kWh, selectedDays.EVTripEnergy_kWh, 'filled');
text(ax, selectedDays.LoadEnergy_kWh, selectedDays.PVEnergy_kWh, ...
    " " + string(selectedDays.DayIndex), 'FontName', cfg.figure.fontName, ...
    'FontSize', cfg.figure.fontSize);
xlabel(ax, 'Daily load energy (kWh/day)');
ylabel(ax, 'Daily PV energy (kWh/day)');
cb = colorbar(ax);
cb.Label.String = 'EV trip energy (kWh/day)';
cb.Label.FontName = cfg.figure.fontName;
applyIEEEStyle(fig, cfg);
info = localInfo(fig, 'FigM8_multiday_representative_day_map', ...
    'Representative-day selection map using load, PV, and EV trip-energy features.');
end

function info = plotStatisticalSummary(S, cfg)
fig = baseFigure('Figure M9 Statistical Comparison Summary', cfg, 10);
ax = axes(fig);
meanDiff = S.MeanDifference;
lo = S.CI95Lower;
hi = S.CI95Upper;
x = 1:height(S);
hold(ax, 'on');
bar(ax, x, meanDiff, 0.62);
hasCI = isfinite(lo) & isfinite(hi);
if any(hasCI)
    errLow = meanDiff(hasCI) - lo(hasCI);
    errHigh = hi(hasCI) - meanDiff(hasCI);
    errorbar(ax, x(hasCI), meanDiff(hasCI), errLow, errHigh, 'k.', 'LineWidth', 1.0);
end
yline(ax, 0, 'k-', 'LineWidth', 0.9);
hold(ax, 'off');
labels = "C" + string((1:height(S)).');
set(ax, 'XTick', x, 'XTickLabel', labels);
ylabel(ax, 'Mean paired difference');
applyIEEEStyle(fig, cfg);
info = localInfo(fig, 'FigM9_multiday_statistical_comparison_summary', ...
    'Statistical comparison summary showing mean paired differences and confidence intervals where available.');
end

function fig = baseFigure(name, cfg, heightCm)
fig = figure('Name', name, 'Color', 'w', 'Visible', 'off', ...
    'Units', 'centimeters', 'Position', [2, 2, cfg.figure.doubleColumnWidthCm, heightCm]);
end

function [labels, values] = pivotByDate(T, variableName, cfg)
dates = unique(T.Date);
regimes = cfg.project.regimeOrder;
labels = strings(numel(dates), 1);
values = NaN(numel(dates), numel(regimes));
for i = 1:numel(dates)
    labels(i) = dateLabel(T, dates(i));
    for r = 1:numel(regimes)
        values(i, r) = value(T, dates(i), regimes(r), variableName);
    end
end
end

function x = value(T, dateValue, regime, variableName)
idx = T.Date == dateValue & T.Regime == regime;
if any(idx)
    x = T.(variableName)(find(idx, 1));
else
    x = NaN;
end
end

function s = dateLabel(T, dateValue)
idx = T.Date == dateValue;
if any(idx)
    s = T.DateLabel(find(idx, 1));
else
    s = string(dateValue);
end
end

function info = localInfo(fig, baseName, caption)
info = struct('handle', fig, 'baseName', string(baseName), 'caption', string(caption));
end
