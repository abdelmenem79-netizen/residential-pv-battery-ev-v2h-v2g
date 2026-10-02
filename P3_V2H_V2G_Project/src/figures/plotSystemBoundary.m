function info = plotSystemBoundary(cfg)
%PLOTSYSTEMBOUNDARY Draw Fig. 1 system and economic boundary diagram.

fig = figure('Name', 'Fig. 1 System and Economic Boundary', 'Color', 'w', ...
    'Visible', 'off', 'Units', 'centimeters', ...
    'Position', [2, 2, cfg.figure.doubleColumnWidthCm, 7.4]);
ax = axes(fig);
axis(ax, [0 14 0 8]);
axis(ax, 'off');
hold(ax, 'on');

boxStyle = {'Curvature', 0.04, 'LineWidth', 1.0, 'FaceColor', [0.96 0.96 0.96]};
rectangle(ax, 'Position', [3.2 1.5 6.3 5.0], boxStyle{:});
text(ax, 6.35, 6.15, 'Household economic boundary', 'HorizontalAlignment', 'center', ...
    'FontName', cfg.figure.fontName, 'FontSize', cfg.figure.fontSize);

drawNode(ax, [0.8 5.3 1.7 0.8], 'PV');
drawNode(ax, [5.55 4.75 1.7 0.8], 'Load');
drawNode(ax, [4.05 2.35 1.9 0.8], 'Battery');
drawNode(ax, [7.1 2.35 1.5 0.8], 'EV');
drawNode(ax, [11.5 4.2 1.5 0.9], 'Grid');

drawArrow(ax, [2.5 5.7], [3.2 5.3], 'PV');
drawArrow(ax, [6.4 4.75], [6.4 3.15], 'demand');
drawArrow(ax, [5.0 3.15], [5.0 4.75], 'BESS');
drawArrow(ax, [7.85 3.15], [7.85 4.75], 'EV');
drawArrow(ax, [9.5 4.9], [11.5 4.9], 'export tariff');
drawArrow(ax, [11.5 4.35], [9.5 4.35], 'import tariff');

text(ax, 6.35, 0.95, 'Net cost = import cost + battery degradation + EV degradation - export revenue', ...
    'HorizontalAlignment', 'center', 'FontName', cfg.figure.fontName, ...
    'FontSize', cfg.figure.fontSize-1);

hold(ax, 'off');
applyIEEEStyle(fig, cfg);

info = localInfo(fig, 'Fig01_system_economic_boundary', ...
    'System and economic boundary diagram.');
end

function drawNode(ax, pos, label)
rectangle(ax, 'Position', pos, 'Curvature', 0.05, 'LineWidth', 1.0, ...
    'FaceColor', [1 1 1]);
text(ax, pos(1)+pos(3)/2, pos(2)+pos(4)/2, label, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontName', 'Times New Roman', 'FontSize', 9);
end

function drawArrow(ax, p1, p2, label)
quiver(ax, p1(1), p1(2), p2(1)-p1(1), p2(2)-p1(2), 0, ...
    'Color', [0.1 0.1 0.1], 'LineWidth', 1.0, 'MaxHeadSize', 0.45);
mid = (p1 + p2)/2;
text(ax, mid(1), mid(2)+0.18, label, 'HorizontalAlignment', 'center', ...
    'FontName', 'Times New Roman', 'FontSize', 7);
end

function info = localInfo(fig, baseName, caption)
info = struct('handle', fig, 'baseName', string(baseName), 'caption', string(caption));
end
