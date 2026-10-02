function info = plotEVPowerComparison(RESULTS, cfg)
%PLOTEVPOWERCOMPARISON Draw Fig. 4 EV net power over time.

fig = figure('Name', 'Fig. 4 EV Power Behaviour', 'Color', 'w', ...
    'Visible', 'off', 'Units', 'centimeters', ...
    'Position', [2, 2, cfg.figure.singleColumnWidthCm, 6.2]);
ax = axes(fig);
hold(ax, 'on');
styles = {':', '--', '-'};
fields = cfg.project.regimeOrder;
for k = 1:numel(fields)
    R = RESULTS.(fields(k));
    plot(ax, R.time_h, R.P_ev_net, styles{k}, 'LineWidth', cfg.figure.lineWidth);
end
yline(ax, 0, 'k:', 'LineWidth', 0.8);
hold(ax, 'off');
xlim(ax, [0 24-cfg.Dt]);
xticks(ax, 0:4:24);
xlabel(ax, 'Time (h)');
ylabel(ax, 'EV power (kW)');
legend(ax, cfg.project.regimeLabels, 'Location', 'northoutside', ...
    'Orientation', 'horizontal', 'Box', 'off');
applyIEEEStyle(fig, cfg);

info = localInfo(fig, 'Fig04_ev_power_behaviour', ...
    'EV net power behaviour over time.');
end

function info = localInfo(fig, baseName, caption)
info = struct('handle', fig, 'baseName', string(baseName), 'caption', string(caption));
end

