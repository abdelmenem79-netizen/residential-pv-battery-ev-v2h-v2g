function info = plotMultiDayExportEnergy(MULTIDAY, cfg)
%PLOTMULTIDAYEXPORTENERGY Create the daily export-energy figure.
info = selectFigure(plotMultiDayFigures(MULTIDAY, cfg), "daily_export_energy");
end

function info = selectFigure(figures, token)
idx = find(contains([figures.baseName], token), 1);
if isempty(idx), info = figures(1); else, info = figures(idx); end
end
