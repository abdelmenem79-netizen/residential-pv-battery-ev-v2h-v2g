function info = plotV2GBenefitDistribution(MULTIDAY, cfg)
%PLOTV2GBENEFITDISTRIBUTION Create the daily V2G benefit figure.
info = selectFigure(plotMultiDayFigures(MULTIDAY, cfg), "v2g_benefit");
end

function info = selectFigure(figures, token)
idx = find(contains([figures.baseName], token), 1);
if isempty(idx), info = figures(1); else, info = figures(idx); end
end
