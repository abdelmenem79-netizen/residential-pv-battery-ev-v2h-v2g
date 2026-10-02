function info = plotPowerBalanceComparison(RESULTS, cfg)
%PLOTPOWERBALANCECOMPARISON Optional power-balance component comparison.

fig = figure('Name', 'Optional Power Balance Comparison', 'Color', 'w', ...
    'Visible', 'off', 'Units', 'centimeters', ...
    'Position', [2, 2, cfg.figure.doubleColumnWidthCm, 12.0]);
tl = tiledlayout(fig, 3, 1, 'Padding', 'compact', 'TileSpacing', 'compact');
fields = cfg.project.regimeOrder;
for k = 1:numel(fields)
    R = RESULTS.(fields(k));
    ax = nexttile(tl);
    plot(ax, R.time_h, [R.P_load(:), R.P_pv(:), R.P_ev_net(:), R.P_batt_net(:), R.P_grid_net(:)], ...
        'LineWidth', cfg.figure.lineWidth);
    ylabel(ax, 'Power (kW)');
    xlim(ax, [0 24-cfg.Dt]);
    title(ax, cfg.project.regimeLabels(k));
    if k == 1
        legend(ax, {'Load', 'PV', 'EV net', 'Battery net', 'Grid net'}, ...
            'Location', 'northoutside', 'Orientation', 'horizontal', 'Box', 'off');
    end
end
xlabel(nexttile(tl, 3), 'Time (h)');
applyIEEEStyle(fig, cfg);
info = struct('handle', fig, 'baseName', "Optional_power_balance_comparison", ...
    'caption', "Optional power balance comparison.");
end

