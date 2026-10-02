function applyIEEEStyle(fig, cfg)
%APPLYIEEESTYLE Apply common IEEE-style typography and line settings.

if nargin < 1 || isempty(fig)
    fig = gcf;
end

set(fig, 'Color', 'w');
axesList = findall(fig, 'Type', 'axes');
for k = 1:numel(axesList)
    ax = axesList(k);
    set(ax, ...
        'FontName', cfg.figure.fontName, ...
        'FontSize', cfg.figure.fontSize, ...
        'LineWidth', 0.9, ...
        'Box', 'on');
    grid(ax, 'on');
    ax.GridAlpha = 0.18;
    ax.MinorGridAlpha = 0.08;
    if isgraphics(ax.XLabel)
        ax.XLabel.FontName = cfg.figure.fontName;
        ax.XLabel.FontSize = cfg.figure.labelFontSize;
    end
    if isgraphics(ax.YLabel)
        ax.YLabel.FontName = cfg.figure.fontName;
        ax.YLabel.FontSize = cfg.figure.labelFontSize;
    end
    if isgraphics(ax.Title)
        ax.Title.FontName = cfg.figure.fontName;
        ax.Title.FontSize = cfg.figure.labelFontSize;
        ax.Title.FontWeight = 'normal';
    end
end

lines = findall(fig, 'Type', 'line');
for k = 1:numel(lines)
    if lines(k).LineWidth < cfg.figure.lineWidth
        lines(k).LineWidth = cfg.figure.lineWidth;
    end
end
end

