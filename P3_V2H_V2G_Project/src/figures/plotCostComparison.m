function info = plotCostComparison(Tcost, cfg)
%PLOTCOSTCOMPARISON Draw Fig. 6 net operating cost comparison.

fig = figure('Name', 'Fig. 6 Cost Comparison', 'Color', 'w', ...
    'Visible', 'off', 'Units', 'centimeters', ...
    'Position', [2, 2, cfg.figure.singleColumnWidthCm, 6.8]);
ax = axes(fig);

regimes = cfg.project.regimeOrder;
labels = cfg.project.regimeLabels;
components = [
    row(Tcost, "Import cost", regimes)
    row(Tcost, "Battery degradation cost", regimes)
    row(Tcost, "EV degradation cost", regimes)
    -row(Tcost, "Export revenue", regimes)
    ].';
total = row(Tcost, "Net operating cost", regimes);

x = 1:numel(labels);
bar(ax, x, components, 'stacked');
hold(ax, 'on');
plot(ax, x, total, 'ko-', 'MarkerFaceColor', 'k', 'LineWidth', 1.0);
hold(ax, 'off');
set(ax, 'XTick', x, 'XTickLabel', labels);
ylabel(ax, 'Cost (GBP/day)');
legend(ax, {'Import', 'Battery deg.', 'EV deg.', 'Export revenue', 'Net cost'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal', 'Box', 'off', ...
    'NumColumns', 2);
applyIEEEStyle(fig, cfg);

info = localInfo(fig, 'Fig06_net_operating_cost_comparison', ...
    'Net operating cost comparison.');
end

function values = row(T, metric, regimes)
idx = T.Metric == metric;
values = zeros(1, numel(regimes));
for k = 1:numel(regimes)
    values(k) = T.(regimes(k))(idx);
end
end

function info = localInfo(fig, baseName, caption)
info = struct('handle', fig, 'baseName', string(baseName), 'caption', string(caption));
end

