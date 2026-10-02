function validDays = classifyValidDays(cfg, validDays)
%CLASSIFYVALIDDAYS Add simple day classifications and optional clusters.

if isempty(validDays)
    return
end

loadZ = localZ(validDays.LoadEnergy_kWh);
pvZ = localZ(validDays.PVEnergy_kWh);
ratioZ = localZ(validDays.PVToLoadRatio);
evZ = localZ(validDays.EVTripEnergy_kWh);
peakLoadZ = localZ(validDays.PeakLoad_kW);
peakPvZ = localZ(validDays.PeakPV_kW);

classification = strings(height(validDays), 1);
for i = 1:height(validDays)
    if pvZ(i) <= -0.75 && loadZ(i) >= 0.75
        classification(i) = "low PV / high load";
    elseif pvZ(i) >= 0.75 && loadZ(i) <= -0.25
        classification(i) = "high PV / low load";
    elseif evZ(i) >= 0.75
        classification(i) = "high EV-use";
    elseif evZ(i) <= -0.75
        classification(i) = "low EV-use";
    elseif peakLoadZ(i) >= 1
        classification(i) = "high peak load";
    elseif ratioZ(i) >= 0.75 || peakPvZ(i) >= 0.75
        classification(i) = "high export potential";
    else
        classification(i) = "average PV / average load";
    end
end

validDays.DayClassification = classification;

if cfg.analysis.representativeDayMethod == "cluster" && exist('kmeans', 'file') == 2
    X = [validDays.LoadEnergy_kWh, validDays.PVEnergy_kWh, validDays.PVToLoadRatio, ...
        validDays.EVAvailabilityHours, validDays.EVTripEnergy_kWh, validDays.PeakLoad_kW, validDays.PeakPV_kW];
    X = normalizeLocal(X);
    k = min(4, max(2, floor(sqrt(height(validDays)))));
    validDays.Cluster = kmeans(X, k, 'Replicates', 5, 'MaxIter', 200);
    if exist('silhouette', 'file') == 2
        try
            s = silhouette(X, validDays.Cluster);
            validDays.SilhouetteScore = s;
        catch
            validDays.SilhouetteScore = NaN(height(validDays), 1);
        end
    else
        validDays.SilhouetteScore = NaN(height(validDays), 1);
    end
else
    validDays.Cluster = NaN(height(validDays), 1);
    validDays.SilhouetteScore = NaN(height(validDays), 1);
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

function Xn = normalizeLocal(X)
Xn = X;
for k = 1:size(X, 2)
    Xn(:, k) = localZ(X(:, k));
end
end
