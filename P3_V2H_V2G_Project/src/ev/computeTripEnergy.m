function trip = computeTripEnergy(cfg, availability, distance)
%COMPUTETRIPENERGY Convert EV distance records into trip energy events.

availability = availability(:);
distance = distance(:);
nRaw = numel(distance);
tripIdx = find(distance ~= 0);

trip = struct();
trip.deltaEnergy_kWh = zeros(0, 1);
trip.timeComeIn_h = zeros(0, 1);
trip.timeGoIndex = zeros(0, 1);
trip.timeComeIndex = zeros(0, 1);
trip.energyEvent_kWh = zeros(cfg.DPoints, 1);

if isempty(tripIdx)
    return
end

deltaEnergy = distance(tripIdx) * cfg.ev.consumption;
timeComeIn_h = floor(tripIdx ./ nRaw * 24);
timeComeIndex = max(1, min(cfg.DPoints, floor(timeComeIn_h ./ cfg.Dt)));

countBack = zeros(numel(tripIdx), 1);
startIdx = 1;
for k = 1:numel(tripIdx)
    if k > 1
        startIdx = tripIdx(k-1);
        countBack(k) = tripIdx(k-1) - 1;
    end

    for j = startIdx:tripIdx(k)-1
        if availability(j) == 1
            countBack(k) = countBack(k) + 1;
        end
    end
end

timeGoIndex = floor(countBack * cfg.DPoints / nRaw);
timeGoIndex = max(1, min(cfg.DPoints, timeGoIndex));

energyEvent = zeros(cfg.DPoints, 1);
for k = 1:numel(timeGoIndex)
    eventIndex = min(cfg.DPoints, timeGoIndex(k) + 1);
    energyEvent(eventIndex) = energyEvent(eventIndex) + deltaEnergy(k);
end

trip.deltaEnergy_kWh = deltaEnergy(:);
trip.timeComeIn_h = timeComeIn_h(:);
trip.timeGoIndex = timeGoIndex(:);
trip.timeComeIndex = timeComeIndex(:);
trip.energyEvent_kWh = energyEvent(:);
end

