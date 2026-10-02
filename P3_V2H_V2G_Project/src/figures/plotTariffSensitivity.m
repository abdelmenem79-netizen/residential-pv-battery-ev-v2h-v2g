function info = plotTariffSensitivity(Tsens, cfg)
%PLOTTARIFFSENSITIVITY Draw Fig. 7 low/medium/high tariff benefit bars.

fig = figure('Name', 'Fig. 7 Tariff Sensitivity', 'Color', 'w', ...
    'Visible', 'off', 'Units', 'centimeters', ...
    'Position', [2, 2, cfg.figure.singleColumnWidthCm, 6.4]);
ax = axes(fig);

data = [ ...
    Tsens.V2HBenefitAgainstV2HOld_GBP_per_day, ...
    Tsens.V2GBenefitAgainstV2H_GBP_per_day ...
    ];
bar(ax, data, 'grouped');
set(ax, 'XTickLabel', Tsens.TariffCase);
ylabel(ax, 'Benefit (GBP/day)');
legend(ax, {'V2H vs V2H-Old', 'V2G vs V2H'}, 'Location', 'northoutside', ...
    'Orientation', 'horizontal', 'Box', 'off');
applyIEEEStyle(fig, cfg);

info = localInfo(fig, 'Fig07_tariff_sensitivity', ...
    'Tariff sensitivity of V2H and V2G economic benefits.');
end

function info = localInfo(fig, baseName, caption)
info = struct('handle', fig, 'baseName', string(baseName), 'caption', string(caption));
end

