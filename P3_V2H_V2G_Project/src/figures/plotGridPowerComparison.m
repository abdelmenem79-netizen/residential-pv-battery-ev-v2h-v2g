function info = plotGridPowerComparison(RESULTS, cfg)
%PLOTGRIDPOWERCOMPARISON Draw Fig. 3 grid power over time.

fig = figure('Name', 'Fig. 3 Grid Power Comparison', 'Color', 'w', ...
    'Visible', 'off', 'Units', 'centimeters', ...
    'Position', [2, 2, cfg.figure.singleColumnWidthCm, 6.2]);
ax = axes(fig);
hold(ax, 'on');
styles = {':', '--', '-'};
fields = cfg.project.regimeOrder;
for k = 1:numel(fields)
    R = RESULTS.(fields(k));
    plot(ax, R.time_h, R.P_grid_net, styles{k}, 'LineWidth', cfg.figure.lineWidth);
end
yline(ax, 0, 'k:', 'LineWidth', 0.8);
hold(ax, 'off');
xlim(ax, [0 24-cfg.Dt]);
xticks(ax, 0:4:24);
xlabel(ax, 'Time (h)');
ylabel(ax, 'Grid power (kW)');
legend(ax, cfg.project.regimeLabels, 'Location', 'northoutside', ...
    'Orientation', 'horizontal', 'Box', 'off');
applyIEEEStyle(fig, cfg);

info = localInfo(fig, 'Fig03_grid_power_comparison', ...
    'Grid power comparison over time.');
end

function info = localInfo(fig, baseName, caption)
info = struct('handle', fig, 'baseName', string(baseName), 'caption', string(caption));
end

