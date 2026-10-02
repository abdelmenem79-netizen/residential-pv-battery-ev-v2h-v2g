function info = plotMultiDayCost(MULTIDAY, cfg)
%PLOTMULTIDAYCOST Create the daily net operating cost figure.
info = selectFigure(plotMultiDayFigures(MULTIDAY, cfg), "daily_net_operating_cost");
end

function info = selectFigure(figures, token)
idx = find(contains([figures.baseName], token), 1);
if isempty(idx), info = figures(1); else, info = figures(idx); end
end
