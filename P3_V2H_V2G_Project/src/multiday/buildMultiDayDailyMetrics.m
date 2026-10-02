function T = buildMultiDayDailyMetrics(results, selectedDays, cfg)
%BUILDMULTIDAYDAILYMETRICS Build one row per date and regime.

regimes = cfg.project.regimeOrder;
T = initialiseDailyTable();

for d = 1:numel(results)
    dayRows = initialiseDailyTable();
    for r = 1:numel(regimes)
        regime = regimes(r);
        R = results(d).(char(regime));
        row = buildOneRow(R, selectedDays(d, :), regime, cfg);
        dayRows = [dayRows; row]; %#ok<AGROW>
    end

    oldCost = valueForRegime(dayRows, "V2HOld", "NetOperatingCost_GBP_per_day");
    v2hCost = valueForRegime(dayRows, "V2H", "NetOperatingCost_GBP_per_day");
    for i = 1:height(dayRows)
        dayRows.ImprovementVsV2HOld_GBP_per_day(i) = oldCost - dayRows.NetOperatingCost_GBP_per_day(i);
        dayRows.ImprovementVsV2H_GBP_per_day(i) = v2hCost - dayRows.NetOperatingCost_GBP_per_day(i);
    end
    T = [T; dayRows]; %#ok<AGROW>
end
end

function T = initialiseDailyTable()
names = {'Date','DateLabel','DayType','SelectionReason','Regime', ...
    'GridImportEnergy_kWh_per_day','GridExportEnergy_kWh_per_day','NetGridEnergy_kWh_per_day', ...
    'PeakGridImport_kW','PeakGridExport_kW', ...
    'EVChargeEnergy_kWh_per_day','EVDischargeEnergy_kWh_per_day','EVThroughput_kWh_per_day', ...
    'BatteryThroughput_kWh_per_day','BatterySOCMin_pct','BatterySOCMax_pct','BatterySOCFinal_pct', ...
    'EVSOCMin_pct','EVSOCMax_pct','EVSOCFinal_pct', ...
    'PVGeneration_kWh_per_day','LoadEnergy_kWh_per_day','PVToLoadRatio','EVAvailabilityHours_h','EVTripEnergy_kWh_per_day', ...
    'ImportCost_GBP_per_day','ExportRevenue_GBP_per_day', ...
    'BatteryDegradationCost_GBP_per_day','EVDegradationCost_GBP_per_day', ...
    'NetOperatingCost_GBP_per_day','ImprovementVsV2HOld_GBP_per_day','ImprovementVsV2H_GBP_per_day', ...
    'ExportRevenueShare_pct','DegradationShare_pct','AnnualisedNetCost_GBP_per_year', ...
    'EVChargeWhileAway_kW','EVDischargeWhileAway_kW','MaxPowerBalanceError_kW','RMSPowerBalanceError_kW', ...
    'SolverStatus', ...
    'SolverSolved','PowerBalancePass','BoundsPass','GridLogicPass','EVAvailabilityPass', ...
    'CoreValidationPass','UseInSummary','Message'};
types = [{'double','string','string','string','string'}, ...
    repmat({'double'}, 1, 34), {'string'}, repmat({'logical'}, 1, 7), {'string'}];
T = table('Size', [0 numel(names)], ...
    'VariableTypes', types, ...
    'VariableNames', names);
end

function row = buildOneRow(R, selectedDay, regime, cfg)
Dt = cfg.Dt;
if isfield(R, 'time_h') && numel(R.time_h) > 1
    dtCandidate = mean(diff(R.time_h(:)));
    if isfinite(dtCandidate) && dtCandidate > 0
        Dt = dtCandidate;
    end
end

solverStatus = "MISSING";
message = "";
if isfield(R, 'solver') && isfield(R.solver, 'status')
    solverStatus = string(R.solver.status);
end
if isfield(R, 'error') && isfield(R.error, 'message')
    message = string(R.error.message);
end

powerPass = validationFlag(R, "powerBalance");
boundsPass = validationFlag(R, "bounds");
gridPass = validationFlag(R, "gridLogic");
evPass = validationFlag(R, "evAvailability");
solverSolved = contains(lower(solverStatus), "solved");
corePass = powerPass && boundsPass && gridPass;
if regime == "V2HOld"
    useInSummary = solverSolved && corePass;
else
    useInSummary = solverSolved && corePass && evPass;
end
if cfg.analysis.includeFailedDaysInSummary || cfg.analysis.includeFailedDays
    useInSummary = solverSolved;
end

row = table( ...
    selectedDay.Date, string(selectedDay.DateLabel), string(selectedDay.DayType), ...
    string(selectedDay.SelectionReason), string(regime), ...
    energy(R, "P_grid_import", Dt), energy(R, "P_grid_export", Dt), energy(R, "P_grid_net", Dt), ...
    peak(R, "P_grid_import"), peak(R, "P_grid_export"), ...
    energy(R, "P_ev_charge", Dt), energy(R, "P_ev_discharge", Dt), ...
    energy(R, "P_ev_charge", Dt) + energy(R, "P_ev_discharge", Dt), ...
    energy(R, "P_batt_charge", Dt) + energy(R, "P_batt_discharge", Dt), ...
    vecMin(R, "SOC_batt"), vecMax(R, "SOC_batt"), vecFinal(R, "SOC_batt"), ...
    vecMin(R, "SOC_ev"), vecMax(R, "SOC_ev"), vecFinal(R, "SOC_ev"), ...
    selectedDay.PVEnergy_kWh, selectedDay.LoadEnergy_kWh, selectedDay.PVToLoadRatio, ...
    selectedDay.EVAvailabilityHours, selectedDay.EVTripEnergy_kWh, ...
    costValue(R, "import"), costValue(R, "exportRevenue"), ...
    costValue(R, "batteryDegradation"), costValue(R, "evDegradation"), costValue(R, "total"), ...
    NaN, NaN, exportRevenueShare(R), degradationShare(R), annualisedCost(R, cfg), ...
    evAwayValue(R, "charge"), evAwayValue(R, "discharge"), pbValue(R, "max"), pbValue(R, "rms"), ...
    solverStatus, ...
    solverSolved, powerPass, boundsPass, gridPass, evPass, corePass, useInSummary, message, ...
    'VariableNames', initialiseDailyTable().Properties.VariableNames);
end

function x = valueForRegime(T, regime, variable)
idx = T.Regime == regime;
if any(idx)
    x = T.(variable)(find(idx, 1));
else
    x = NaN;
end
end

function x = energy(R, fieldName, Dt)
if isfield(R, fieldName)
    values = R.(fieldName);
    if isnumeric(values) && any(isfinite(values(:)))
        x = sum(values(:), 'omitnan')*Dt;
    else
        x = NaN;
    end
else
    x = NaN;
end
end

function x = peak(R, fieldName)
if isfield(R, fieldName)
    values = R.(fieldName);
    if isnumeric(values) && any(isfinite(values(:)))
        x = max(values(:), [], 'omitnan');
    else
        x = NaN;
    end
else
    x = NaN;
end
end

function x = vecMin(R, fieldName)
if isfield(R, fieldName) && any(isfinite(R.(fieldName)(:)))
    x = min(R.(fieldName)(:), [], 'omitnan');
else
    x = NaN;
end
end

function x = vecMax(R, fieldName)
if isfield(R, fieldName) && any(isfinite(R.(fieldName)(:)))
    x = max(R.(fieldName)(:), [], 'omitnan');
else
    x = NaN;
end
end

function x = vecFinal(R, fieldName)
if isfield(R, fieldName) && ~isempty(R.(fieldName))
    values = R.(fieldName);
    x = values(find(isfinite(values(:)), 1, 'last'));
    if isempty(x)
        x = NaN;
    end
else
    x = NaN;
end
end

function x = costValue(R, fieldName)
if isfield(R, 'cost') && isfield(R.cost, fieldName)
    x = R.cost.(fieldName);
else
    x = NaN;
end
end

function x = exportRevenueShare(R)
if isfield(R, 'cost') && isfinite(R.cost.exportRevenue)
    denom = abs(R.cost.import) + abs(R.cost.batteryDegradation) + abs(R.cost.evDegradation) + eps;
    x = 100*R.cost.exportRevenue/denom;
else
    x = NaN;
end
end

function x = degradationShare(R)
if isfield(R, 'cost') && isfinite(R.cost.batteryDegradation) && isfinite(R.cost.evDegradation)
    denom = abs(R.cost.import) + abs(R.cost.batteryDegradation) + abs(R.cost.evDegradation) + eps;
    x = 100*(R.cost.batteryDegradation + R.cost.evDegradation)/denom;
else
    x = NaN;
end
end

function x = annualisedCost(R, cfg)
if cfg.analysis.annualise && isfield(R, 'cost') && isfinite(R.cost.total)
    x = 365*R.cost.total;
else
    x = NaN;
end
end

function x = evAwayValue(R, mode)
x = NaN;
if ~isfield(R, 'validation') || ~isfield(R.validation, 'evAvailability')
    return
end
if mode == "charge"
    x = R.validation.evAvailability.evChargeWhileAway_kW;
else
    x = R.validation.evAvailability.evDischargeWhileAway_kW;
end
end

function x = pbValue(R, mode)
x = NaN;
if ~isfield(R, 'validation') || ~isfield(R.validation, 'powerBalance')
    return
end
if mode == "max"
    x = R.validation.powerBalance.maxAbs_kW;
else
    x = R.validation.powerBalance.rms_kW;
end
end

function tf = validationFlag(R, fieldName)
tf = false;
if isfield(R, 'validation') && isfield(R.validation, fieldName) && ...
        isfield(R.validation.(fieldName), 'pass')
    tf = logical(R.validation.(fieldName).pass);
end
end
