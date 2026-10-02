function selected = selectRepresentativeDays(cfg, validDays)
%SELECTREPRESENTATIVEDAYS Choose days for the P3 robustness assessment.

if nargin < 2 || isempty(validDays)
    Screening = screenCandidateDays(cfg);
    validDays = classifyValidDays(cfg, Screening.ValidDays);
end
features = validDays;
method = string(cfg.analysis.representativeDayMethod);
if cfg.analysis.runAllValidDays
    maxDays = Inf;
elseif isfield(cfg.analysis, 'maxValidDays')
    maxDays = cfg.analysis.maxValidDays;
else
    maxDays = cfg.analysis.maxDays;
end

if method == "manual" && ~isempty(cfg.analysis.dateList)
    requested = unique(cfg.analysis.dateList(:), 'stable');
    [tf, idx] = ismember(requested, features.Date);
    if any(~tf)
        warning('Some manual dates are unavailable and will be skipped: %s', ...
            strjoin(string(requested(~tf)), ', '));
    end
    selected = features(idx(tf), :);
    selected.SelectionReason = repmat("manual date list", height(selected), 1);
else
    switch method
        case "validSequential"
            selected = features(1:min(height(features), maxDays), :);
            selected.SelectionReason = repmat("valid sequential selection", height(selected), 1);
        case "random"
            selected = selectRandomDays(features, maxDays, cfg.analysis.randomSeed);
        case "cluster"
            selected = selectClusterDays(features, maxDays);
        otherwise
            selected = selectExtremeDays(features, maxDays);
    end
end

if isfinite(maxDays) && height(selected) > maxDays
    selected = selected(1:maxDays, :);
end

selected = sortrows(selected, "Date");
selected.DayIndex = (1:height(selected)).';
selected = movevars(selected, "DayIndex", "Before", 1);
end

function selected = selectRandomDays(features, maxDays, randomSeed)
rng(randomSeed);
if ~isfinite(maxDays)
    selected = features;
else
    count = min(maxDays, height(features));
    selected = features(randperm(height(features), count), :);
end
selected.SelectionReason = repmat("random sample", height(selected), 1);
end

function selected = selectClusterDays(features, maxDays)
if ~isfinite(maxDays)
    maxDays = height(features);
end
count = min(maxDays, height(features));
availabilityFeature = availabilityColumn(features);
X = [features.LoadEnergy_kWh, features.PVEnergy_kWh, ...
    features.EVTripEnergy_kWh, availabilityFeature];
X = localNormalize(X);

if exist('kmeans', 'file') == 2 && count > 1
    idx = kmeans(X, count, 'Replicates', 5, 'MaxIter', 200);
    chosen = zeros(count, 1);
    for c = 1:count
        members = find(idx == c);
        centroid = mean(X(members, :), 1);
        [~, localIdx] = min(sum((X(members, :) - centroid).^2, 2));
        chosen(c) = members(localIdx);
    end
    selected = features(unique(chosen, 'stable'), :);
    selected.SelectionReason = repmat("cluster representative", height(selected), 1);
else
    selected = selectExtremeDays(features, count);
end

function x = availabilityColumn(features)
if ismember("EVAvailabilityRatio", string(features.Properties.VariableNames))
    x = features.EVAvailabilityRatio;
else
    x = features.EVAvailabilityHours;
end
end
end

function selected = selectExtremeDays(features, maxDays)
if ~isfinite(maxDays)
    selected = features;
    selected.SelectionReason = repmat("all available dates", height(selected), 1);
    return
end

targetCount = min(maxDays, height(features));
loadZ = localZ(features.LoadEnergy_kWh);
pvZ = localZ(features.PVEnergy_kWh);
evZ = localZ(features.EVTripEnergy_kWh);

chosen = zeros(0, 1);
reasons = strings(0, 1);

[chosen, reasons] = addBest(features, chosen, reasons, loadZ - pvZ, "low PV / high load day", "max");
[chosen, reasons] = addBest(features, chosen, reasons, pvZ - loadZ, "high PV / low load day", "max");
avgScore = abs(loadZ) + abs(pvZ) + abs(evZ);
[chosen, reasons] = addBest(features, chosen, reasons, avgScore, "average PV / average load day", "min");
[chosen, reasons] = addBest(features, chosen, reasons, features.EVTripEnergy_kWh, "high EV-use day", "max");
[chosen, reasons] = addBest(features, chosen, reasons, features.EVTripEnergy_kWh, "low EV-use day", "min");

weekdayRows = find(features.DayType == "weekday");
if ~isempty(weekdayRows)
    [~, localIdx] = min(avgScore(weekdayRows));
    [chosen, reasons] = addIndex(chosen, reasons, weekdayRows(localIdx), "weekday-type day");
end

weekendRows = find(features.DayType == "weekend");
if ~isempty(weekendRows)
    [~, localIdx] = min(avgScore(weekendRows));
    [chosen, reasons] = addIndex(chosen, reasons, weekendRows(localIdx), "weekend-type day");
end

if numel(chosen) < targetCount
    fillScore = abs(loadZ) + abs(pvZ) + abs(evZ);
    [~, order] = sort(fillScore, 'ascend');
    for k = 1:numel(order)
        [chosen, reasons] = addIndex(chosen, reasons, order(k), "balanced fill day");
        if numel(chosen) >= targetCount
            break
        end
    end
end

chosen = chosen(1:min(targetCount, numel(chosen)));
reasons = reasons(1:numel(chosen));
selected = features(chosen, :);
selected.SelectionReason = reasons(:);
end

function [chosen, reasons] = addBest(features, chosen, reasons, score, reason, mode)
if mode == "min"
    [~, order] = sort(score, 'ascend');
else
    [~, order] = sort(score, 'descend');
end
for k = 1:numel(order)
    [chosenNew, reasonsNew, added] = addIndex(chosen, reasons, order(k), reason);
    if added || numel(unique(chosen)) == height(features)
        chosen = chosenNew;
        reasons = reasonsNew;
        return
    end
end
end

function [chosen, reasons, added] = addIndex(chosen, reasons, idx, reason)
added = false;
if ~ismember(idx, chosen)
    chosen(end+1, 1) = idx;
    reasons(end+1, 1) = reason;
    added = true;
end
end

function z = localZ(x)
x = double(x(:));
s = std(x, 0, 'omitnan');
if ~isfinite(s) || s == 0
    s = 1;
end
z = (x - mean(x, 'omitnan')) ./ s;
end

function Xn = localNormalize(X)
Xn = X;
for k = 1:size(X, 2)
    Xn(:, k) = localZ(X(:, k));
end
end
