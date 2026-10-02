function info = plotMultiDayNetGridEnergy(MULTIDAY, cfg)
%PLOTMULTIDAYNETGRIDENERGY Create the daily net-grid-energy figure.
info = selectFigure(plotMultiDayFigures(MULTIDAY, cfg), "daily_net_grid_energy");
end

function info = selectFigure(figures, token)
idx = find(contains([figures.baseName], token), 1);
if isempty(idx), info = figures(1); else, info = figures(idx); end
end
