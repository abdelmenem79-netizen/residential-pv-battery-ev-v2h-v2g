function Screening = screenCandidateDays(cfg)
%SCREENCANDIDATEDAYS Screen all candidate days before optimisation.

S = load(cfg.paths.data.processedHouseData, 'House1_data_Struct');
house = S.House1_data_Struct;
candidateDates = buildCandidateDateList(house, cfg);

socBattery = readFirstScalar(cfg.paths.data.socBattery);
socEV = readFirstScalar(cfg.paths.data.socEV);

validRows = initialiseValidTable();
excludedRows = initialiseExcludedTable();

for i = 1:numel(candidateDates)
    dateValue = candidateDates(i);
    [day, samplesFound] = getDayWindow(house, dateValue, cfg.DPoints);
    [forecastDay, forecastSamples] = getDayWindow(house, dateValue + 1, cfg.DPoints);
    dateLabel = excelDateLabel(dateValue);

    failed = strings(0, 1);
    reason = strings(0, 1);
    missingVariable = "";

    if samplesFound < 2*cfg.DPoints
        failed(end+1) = "complete_profile";
        reason(end+1) = "analysis day does not contain the required legacy two-day window";
    end
    if forecastSamples < 2*cfg.DPoints
        failed(end+1) = "forecast_profile";
        reason(end+1) = "next-day forecast window is incomplete";
    end
    if numel(day.load_kW) ~= cfg.DPoints
        failed(end+1) = "load_length";
        reason(end+1) = "load vector length is inconsistent";
        missingVariable = "PL1";
    end
    if numel(day.pv_kW) ~= cfg.DPoints
        failed(end+1) = "pv_length";
        reason(end+1) = "PV vector length is inconsistent";
        missingVariable = "PV1";
    end
    if cfg.analysis.requireEVData && numel(day.evAvailableRaw) ~= cfg.DPoints
        failed(end+1) = "ev_availability_length";
        reason(end+1) = "EV availability vector length is inconsistent";
        missingVariable = "EV1S";
    end
    if cfg.analysis.requireEVData && numel(day.evDistanceRaw) ~= cfg.DPoints
        failed(end+1) = "ev_distance_length";
        reason(end+1) = "EV distance vector length is inconsistent";
        missingVariable = "EV1D";
    end

    if isempty(failed)
        vectors = {day.load_kW, day.pv_kW, day.evAvailableRaw, day.evDistanceRaw, ...
            forecastDay.load_kW, forecastDay.pv_kW};
        names = ["PL1","PV1","EV1S","EV1D","forecast PL1","forecast PV1"];
        for v = 1:numel(vectors)
            x = vectors{v};
            if any(isnan(x(:)))
                failed(end+1) = "nan_values"; %#ok<AGROW>
                reason(end+1) = "NaN values found"; %#ok<AGROW>
                missingVariable = names(v);
            end
            if any(isinf(x(:)))
                failed(end+1) = "inf_values"; %#ok<AGROW>
                reason(end+1) = "Inf values found"; %#ok<AGROW>
                missingVariable = names(v);
            end
        end

        if any(day.pv_kW(:) < -cfg.validation.tolerance)
            failed(end+1) = "negative_pv";
            reason(end+1) = "PV generation contains negative values";
        end
        if all(abs(day.load_kW(:)) <= cfg.validation.tolerance)
            failed(end+1) = "zero_load";
            reason(end+1) = "load profile is fully zero";
        end
        if cfg.analysis.requireEVData && isempty(day.evAvailableRaw)
            failed(end+1) = "empty_ev_availability";
            reason(end+1) = "EV availability profile is empty";
        end
        if cfg.analysis.requireEVData && any(~ismember(round(day.evAvailableRaw(:)), [0; 1]))
            failed(end+1) = "ev_availability_not_binary";
            reason(end+1) = "EV availability is not safely convertible to binary";
        end
        if cfg.analysis.requireEVData && any(day.evDistanceRaw(:) < -cfg.validation.tolerance)
            failed(end+1) = "negative_trip_energy";
            reason(end+1) = "EV trip distance or energy is negative";
        end
        if cfg.analysis.requireSOCData && (~isfinite(socBattery) || isempty(socBattery))
            failed(end+1) = "missing_battery_soc";
            reason(end+1) = "initial battery SOC is unavailable";
            missingVariable = "SOCFinal.xlsx";
        end
        if cfg.analysis.requireSOCData && (~isfinite(socEV) || isempty(socEV))
            failed(end+1) = "missing_ev_soc";
            reason(end+1) = "initial EV SOC is unavailable";
            missingVariable = "SOCFinalEV.xlsx";
        end
        if hasDuplicateOrMissingSteps(house, dateValue, cfg)
            failed(end+1) = "time_step_consistency";
            reason(end+1) = "missing or duplicate time steps detected";
        end
        if cfg.analysis.requireEVData && createsInfeasibleEVTarget(day, socEV, cfg)
            failed(end+1) = "ev_target_infeasible_before_departure";
            reason(end+1) = "EV cannot reach requested pre-trip target with available charging time";
        end
    end

    if isempty(failed)
        validRows = [validRows; buildValidRow(dateValue, dateLabel, day, socBattery, socEV, cfg)]; %#ok<AGROW>
    else
        excludedRows = [excludedRows; buildExcludedRow(dateValue, dateLabel, failed, reason, ...
            missingVariable, samplesFound, 2*cfg.DPoints)]; %#ok<AGROW>
    end
end

Screening = struct();
Screening.CandidateDays = candidateDates(:);
Screening.ValidDays = validRows;
Screening.ExcludedDays = excludedRows;
Screening.Summary = table(numel(candidateDates), height(validRows), height(excludedRows), ...
    'VariableNames', {'CandidateDays','ValidDays','ExcludedDays'});
Screening.T_valid_days = validRows;
Screening.T_excluded_days = excludedRows;
end

function dates = buildCandidateDateList(house, cfg)
allDates = unique(floor(house.DayNum(:)));
if ~isempty(cfg.analysis.dateList)
    dates = unique(cfg.analysis.dateList(:), 'stable');
elseif ~isempty(cfg.analysis.dateRange)
    dates = (cfg.analysis.dateRange(1):cfg.analysis.dateRange(2)).';
else
    dates = allDates(:);
end
dates = dates(ismember(dates, allDates));
end

function [day, samplesFound] = getDayWindow(house, dateValue, DPoints)
idx = house.DayNum >= dateValue - 1 & floor(house.DayNum) <= dateValue;
samplesFound = nnz(idx);
day.load_kW = house.PL1(idx);
day.pv_kW = house.PV1(idx);
day.evAvailableRaw = house.EV1S(idx);
day.evDistanceRaw = house.EV1D(idx);
if samplesFound >= 2*DPoints
    day.load_kW = day.load_kW(DPoints+1:2*DPoints);
    day.pv_kW = day.pv_kW(DPoints+1:2*DPoints);
    day.evAvailableRaw = day.evAvailableRaw(DPoints+1:2*DPoints);
    day.evDistanceRaw = day.evDistanceRaw(DPoints+1:2*DPoints);
end
end

function T = initialiseValidTable()
T = table('Size', [0 14], ...
    'VariableTypes', {'double','string','string','double','double','double','double','double','double','double','double','double','string','logical'}, ...
    'VariableNames', {'Date','DateLabel','DayType','LoadEnergy_kWh','PVEnergy_kWh','PVToLoadRatio', ...
    'EVAvailabilityHours','EVTripEnergy_kWh','PeakLoad_kW','PeakPV_kW', ...
    'InitialBatterySOC_pct','InitialEVSOC_pct','DayClassification','Included'});
end

function T = initialiseExcludedTable()
T = table('Size', [0 8], ...
    'VariableTypes', {'double','string','string','string','string','double','double','string'}, ...
    'VariableNames', {'Date','DateLabel','Reason','FailedCheck','MissingVariable','SamplesFound','ExpectedSamples','ActionTaken'});
end

function row = buildValidRow(dateValue, dateLabel, day, socBattery, socEV, cfg)
loadEnergy = sum(abs(day.load_kW(:)))*cfg.Dt;
pvEnergy = sum(max(abs(day.pv_kW(:)), 0))*cfg.Dt;
evTripEnergy = sum(max(day.evDistanceRaw(:), 0))*cfg.ev.consumption;
evAvailabilityHours = sum(round(day.evAvailableRaw(:)) >= 0.5)*cfg.Dt;
dayType = classifyWeekday(dateValue);
row = table(dateValue, string(dateLabel), dayType, loadEnergy, pvEnergy, pvEnergy/max(loadEnergy, eps), ...
    evAvailabilityHours, evTripEnergy, max(abs(day.load_kW(:))), max(max(abs(day.pv_kW(:)), 0)), ...
    socBattery, socEV, "unclassified", true, ...
    'VariableNames', initialiseValidTable().Properties.VariableNames);
end

function dayType = classifyWeekday(dateValue)
d = datetime(dateValue, 'ConvertFrom', 'excel');
dayNumber = weekday(d);
if dayNumber == 1 || dayNumber == 7
    dayType = "weekend";
else
    dayType = "weekday";
end
end

function row = buildExcludedRow(dateValue, dateLabel, failed, reason, missingVariable, samplesFound, expectedSamples)
row = table(dateValue, string(dateLabel), strjoin(reason, "; "), strjoin(failed, "; "), ...
    string(missingVariable), samplesFound, expectedSamples, "excluded before optimisation", ...
    'VariableNames', initialiseExcludedTable().Properties.VariableNames);
end

function tf = hasDuplicateOrMissingSteps(house, dateValue, cfg)
idx = house.DayNum >= dateValue - 1 & floor(house.DayNum) <= dateValue;
tf = false;
if nnz(idx) < 2*cfg.DPoints
    tf = true;
    return
end
hour = house.Hour(idx);
minute = house.Minute(idx);
values = double(hour(cfg.DPoints+1:2*cfg.DPoints))*60 + double(minute(cfg.DPoints+1:2*cfg.DPoints));
if numel(unique(values)) ~= numel(values)
    tf = true;
    return
end
dt = diff(values);
expectedMinutes = cfg.Dt*60;
if any(abs(dt - expectedMinutes) > 1e-8)
    tf = true;
end
end

function tf = createsInfeasibleEVTarget(day, socEV, cfg)
distance = max(day.evDistanceRaw(:), 0);
firstTrip = find(distance > 0, 1, 'first');
tf = false;
if isempty(firstTrip)
    return
end
available = round(day.evAvailableRaw(:)) >= 0.5;
energyStart = cfg.ev.capacity*socEV/100;
energyTarget = cfg.ev.capacity*cfg.ev.desiredBeforeFirstTripPct/100;
chargeSlots = available(1:max(firstTrip-1, 1));
maxChargeEnergy = sum(chargeSlots)*cfg.Dt*cfg.ev.Pmax*cfg.ev.eta;
tf = energyStart + maxChargeEnergy + 1e-6 < energyTarget;
end

function x = readFirstScalar(path)
if exist(path, 'file')
    data = readmatrix(path);
    if ~isempty(data)
        x = data(1, 1);
    else
        x = NaN;
    end
else
    x = NaN;
end
end

function label = excelDateLabel(dateValue)
label = string(datetime(dateValue, 'ConvertFrom', 'excel'), 'yyyy-MM-dd');
end
