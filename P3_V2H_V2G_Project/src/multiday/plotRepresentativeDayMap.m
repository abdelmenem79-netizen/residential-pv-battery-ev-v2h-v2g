function info = plotRepresentativeDayMap(MULTIDAY, cfg)
%PLOTREPRESENTATIVEDAYMAP Create the representative-day classification map.
info = selectFigure(plotMultiDayFigures(MULTIDAY, cfg), "representative_day_map");
end

function info = selectFigure(figures, token)
idx = find(contains([figures.baseName], token), 1);
if isempty(idx), info = figures(1); else, info = figures(idx); end
end
