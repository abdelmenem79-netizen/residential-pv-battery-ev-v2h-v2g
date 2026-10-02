function info = plotSOCComparison(RESULTS, cfg)
%PLOTSOCCOMPARISON Draw Fig. 5 battery and EV SOC comparison.

fig = figure('Name', 'Fig. 5 SOC Comparison', 'Color', 'w', ...
    'Visible', 'off', 'Units', 'centimeters', ...
    'Position', [2, 2, cfg.figure.singleColumnWidthCm, 8.6]);
tl = tiledlayout(fig, 2, 1, 'Padding', 'compact', 'TileSpacing', 'compact');

styles = {':', '--', '-'};
fields = cfg.project.regimeOrder;

ax1 = nexttile(tl);
hold(ax1, 'on');
for k = 1:numel(fields)
    R = RESULTS.(fields(k));
    plot(ax1, R.time_h, R.SOC_batt, styles{k}, 'LineWidth', cfg.figure.lineWidth);
end
hold(ax1, 'off');
ylabel(ax1, 'Battery SOC (%)');
xlim(ax1, [0 24-cfg.Dt]);
xticks(ax1, 0:4:24);
legend(ax1, cfg.project.regimeLabels, 'Location', 'northoutside', ...
    'Orientation', 'horizontal', 'Box', 'off');

ax2 = nexttile(tl);
hold(ax2, 'on');
for k = 1:numel(fields)
    R = RESULTS.(fields(k));
    plot(ax2, R.time_h, R.SOC_ev, styles{k}, 'LineWidth', cfg.figure.lineWidth);
end
hold(ax2, 'off');
xlabel(ax2, 'Time (h)');
ylabel(ax2, 'EV SOC (%)');
xlim(ax2, [0 24-cfg.Dt]);
xticks(ax2, 0:4:24);
applyIEEEStyle(fig, cfg);

info = localInfo(fig, 'Fig05_soc_comparison', ...
    'Battery and EV SOC comparison.');
end

function info = localInfo(fig, baseName, caption)
info = struct('handle', fig, 'baseName', string(baseName), 'caption', string(caption));
end

