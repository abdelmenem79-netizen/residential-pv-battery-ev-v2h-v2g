function info = plotGridEnergyComparison(RESULTS, Toperational, cfg)
%PLOTGRIDENERGYCOMPARISON Draw Fig. 2 import/export/net grid energy bars.

fig = figure('Name', 'Fig. 2 Grid Energy Comparison', 'Color', 'w', ...
    'Visible', 'off', 'Units', 'centimeters', ...
    'Position', [2, 2, cfg.figure.singleColumnWidthCm, 6.4]);
ax = axes(fig);

labels = cfg.project.regimeLabels;
data = [
    metricValue(Toperational, "Grid import energy", "V2HOld"), metricValue(Toperational, "Grid export energy", "V2HOld"), metricValue(Toperational, "Net grid energy", "V2HOld")
    metricValue(Toperational, "Grid import energy", "V2H"), metricValue(Toperational, "Grid export energy", "V2H"), metricValue(Toperational, "Net grid energy", "V2H")
    metricValue(Toperational, "Grid import energy", "V2G"), metricValue(Toperational, "Grid export energy", "V2G"), metricValue(Toperational, "Net grid energy", "V2G")
    ];

bar(ax, data, 'grouped');
set(ax, 'XTickLabel', labels);
ylabel(ax, 'Energy (kWh/day)');
legend(ax, {'Import', 'Export', 'Net'}, 'Location', 'northoutside', ...
    'Orientation', 'horizontal', 'Box', 'off');
applyIEEEStyle(fig, cfg);

info = localInfo(fig, 'Fig02_grid_energy_comparison', ...
    'Grid import, export, and net grid energy comparison.');
end

function v = metricValue(T, metric, regime)
idx = T.Metric == metric;
v = T.(regime)(idx);
end

function info = localInfo(fig, baseName, caption)
info = struct('handle', fig, 'baseName', string(baseName), 'caption', string(caption));
end

