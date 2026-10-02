function info = plotCumulativeGridEnergy(RESULTS, cfg)
%PLOTCUMULATIVEGRIDENERGY Optional cumulative absolute grid energy plot.

fig = figure('Name', 'Optional Cumulative Grid Energy', 'Color', 'w', ...
    'Visible', 'off', 'Units', 'centimeters', ...
    'Position', [2, 2, cfg.figure.singleColumnWidthCm, 6.2]);
ax = axes(fig);
hold(ax, 'on');
styles = {':', '--', '-'};
fields = cfg.project.regimeOrder;
for k = 1:numel(fields)
    R = RESULTS.(fields(k));
    energy = cumtrapz(R.time_h(:), abs(R.P_grid_net(:)));
    plot(ax, R.time_h, energy, styles{k}, 'LineWidth', cfg.figure.lineWidth);
end
hold(ax, 'off');
xlabel(ax, 'Time (h)');
ylabel(ax, 'Energy (kWh)');
legend(ax, cfg.project.regimeLabels, 'Location', 'northoutside', ...
    'Orientation', 'horizontal', 'Box', 'off');
applyIEEEStyle(fig, cfg);
info = struct('handle', fig, 'baseName', "Optional_cumulative_grid_energy", ...
    'caption', "Optional cumulative absolute grid energy.");
end

