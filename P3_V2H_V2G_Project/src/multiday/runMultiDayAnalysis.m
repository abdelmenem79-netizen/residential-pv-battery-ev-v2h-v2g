function MULTIDAY = runMultiDayAnalysis(cfg)
%RUNMULTIDAYANALYSIS Run V2H-Old, V2H, and V2G across selected days.

ticRun = tic;
Screening = screenCandidateDays(cfg);
Screening.ValidDays = classifyValidDays(cfg, Screening.ValidDays);
Screening.T_valid_days = Screening.ValidDays;
selectedDays = selectRepresentativeDays(cfg, Screening.ValidDays);
regimes = cfg.project.regimeOrder;

fprintf('Selected %d representative day(s) using method "%s".\n', ...
    height(selectedDays), cfg.analysis.representativeDayMethod);
fprintf('Candidate days: %d | valid days: %d | excluded before solving: %d\n', ...
    numel(Screening.CandidateDays), height(Screening.ValidDays), height(Screening.ExcludedDays));
deleteOldDailyResultFiles(cfg);

results = initialiseResultsArray(height(selectedDays), regimes);
runLog = initialiseRunLog();

for d = 1:height(selectedDays)
    dateValue = selectedDays.Date(d);
    fprintf('\nMulti-day case %d/%d: date %.0f (%s, %s)\n', ...
        d, height(selectedDays), dateValue, selectedDays.DateLabel(d), selectedDays.SelectionReason(d));

    dayCfg = cfg;
    dayCfg.case.date = dateValue;
    results(d).date = dateValue;
    results(d).dateLabel = selectedDays.DateLabel(d);
    results(d).selectionReason = selectedDays.SelectionReason(d);
    results(d).classification = selectedDays.DayClassification(d);

    try
        inputs = prepareInputs(dayCfg);
        results(d).inputs = inputs;
    catch ME
        warningText = "Input preparation failed: " + string(ME.message);
        fprintf('  %s\n', warningText);
        for r = 1:numel(regimes)
            regime = regimes(r);
            results(d).(char(regime)) = makeFailedResult(regime, dayCfg, struct(), ME);
            runLog = appendRunLog(runLog, dateValue, selectedDays.DateLabel(d), ...
                regime, "INPUT_FAILED", false, false, warningText);
        end
        continue
    end

    for r = 1:numel(regimes)
        regime = regimes(r);
        try
            fprintf('  Running %s...', regime);
            R = runRegime(dayCfg, inputs, regime);
            R.validation.powerBalance = validatePowerBalance(R, dayCfg);
            R.validation.bounds = validateBounds(R, dayCfg);
            R.validation.gridLogic = validateGridLogic(R, dayCfg);
            R.validation.evAvailability = validateEVAvailability(R, dayCfg);
            R.metadata.analysisDate = dateValue;
            R.metadata.dateLabel = selectedDays.DateLabel(d);
            R.metadata.selectionReason = selectedDays.SelectionReason(d);
            R.metadata.classification = selectedDays.DayClassification(d);

            validationPass = allValidationPass(R);
            corePass = coreValidationPass(R);
            results(d).(char(regime)) = R;
            runLog = appendRunLog(runLog, dateValue, selectedDays.DateLabel(d), ...
                regime, string(R.solver.status), solverSolved(R), validationPass, "");
            fprintf(' %s, net cost %.4f GBP/day\n', R.solver.status, R.cost.total);
            if ~corePass
                fprintf('    Core validation warning recorded for %s on %.0f.\n', regime, dateValue);
            end
        catch ME
            fprintf(' FAILED\n');
            results(d).(char(regime)) = makeFailedResult(regime, dayCfg, inputs, ME);
            runLog = appendRunLog(runLog, dateValue, selectedDays.DateLabel(d), ...
                regime, "FAILED", false, false, string(ME.message));
        end
    end

    dayFile = fullfile(cfg.paths.outputs.multiday.results, ...
        sprintf('MULTIDAY_day_%0.f.mat', dateValue));
    DayResult = results(d); %#ok<NASGU>
    save(dayFile, 'DayResult', '-v7.3');
end

MULTIDAY = struct();
MULTIDAY.Screening = Screening;
MULTIDAY.SelectedDays = selectedDays;
MULTIDAY.Results = results;
MULTIDAY.RunLog = runLog;
MULTIDAY.DailyMetrics = buildDailyMetricsTable(results, selectedDays, cfg);
MULTIDAY.SummaryMetrics = buildMultiDaySummaryTable(MULTIDAY.DailyMetrics, Screening, cfg);
MULTIDAY.RegimeComparison = buildRobustnessTable(MULTIDAY.DailyMetrics, cfg);
MULTIDAY.ValidationSummary = buildMultiDayValidationSummary(MULTIDAY.DailyMetrics, cfg);
MULTIDAY.StatisticalResults = buildStatisticalComparison(MULTIDAY, cfg);
MULTIDAY.StatisticalEvidence = MULTIDAY.StatisticalResults;
MULTIDAY.TariffSensitivity = buildMultiDayTariffSensitivity(MULTIDAY.DailyMetrics, cfg);
MULTIDAY.Tables = buildMultiDayPaperTables(MULTIDAY, cfg);
MULTIDAY.PaperTables = MULTIDAY.Tables;
MULTIDAY.QualityControl = validateMultiDayResults(MULTIDAY, cfg);
MULTIDAY.Figures = plotMultiDayFigures(MULTIDAY, cfg);
MULTIDAY.GeneratedText = generateMultiDayResultsText(MULTIDAY, cfg);
MULTIDAY.Text = MULTIDAY.GeneratedText;
MULTIDAY.ElapsedSeconds = toc(ticRun);
MULTIDAY.Export = exportMultiDayResults(MULTIDAY, cfg);
MULTIDAY.WordReportPath = "";

resultsFile = fullfile(cfg.paths.outputs.multiday.results, 'MULTIDAY_complete_results.mat');
save(resultsFile, 'MULTIDAY', 'cfg', '-v7.3');

fprintf('\nMulti-day robustness assessment complete in %.1f seconds.\n', MULTIDAY.ElapsedSeconds);
fprintf('Multi-day MAT file: %s\n', resultsFile);
end

function deleteOldDailyResultFiles(cfg)
files = dir(fullfile(cfg.paths.outputs.multiday.results, 'MULTIDAY_day_*.mat'));
for k = 1:numel(files)
    delete(fullfile(files(k).folder, files(k).name));
end
end

function results = initialiseResultsArray(n, regimes)
template = struct();
template.date = NaN;
template.dateLabel = "";
template.selectionReason = "";
template.inputs = struct();
for r = 1:numel(regimes)
    template.(char(regimes(r))) = struct();
end
results = repmat(template, n, 1);
end

function T = initialiseRunLog()
T = table('Size', [0 8], ...
    'VariableTypes', {'double','string','string','string','string','logical','logical','string'}, ...
    'VariableNames', {'Date','DateLabel','Regime','SolverStatus','RunStatus','SolverSolved','ValidationPass','Message'});
end

function T = appendRunLog(T, dateValue, dateLabel, regime, solverStatus, solved, validationPass, message)
runStatus = "OK";
if ~solved
    runStatus = "FAILED";
elseif ~validationPass
    runStatus = "VALIDATION_WARNING";
end
row = table(dateValue, string(dateLabel), string(regime), string(solverStatus), ...
    runStatus, logical(solved), logical(validationPass), string(message), ...
    'VariableNames', T.Properties.VariableNames);
T = [T; row];
end

function tf = solverSolved(R)
tf = isfield(R, 'solver') && isfield(R.solver, 'status') && ...
    contains(lower(string(R.solver.status)), "solved");
end

function tf = allValidationPass(R)
tf = isfield(R, 'validation') && ...
    R.validation.powerBalance.pass && ...
    R.validation.bounds.pass && ...
    R.validation.gridLogic.pass && ...
    R.validation.evAvailability.pass;
end

function tf = coreValidationPass(R)
tf = isfield(R, 'validation') && ...
    R.validation.powerBalance.pass && ...
    R.validation.bounds.pass && ...
    R.validation.gridLogic.pass;
end

function R = makeFailedResult(regime, cfg, inputs, ME)
D = cfg.DPoints;
if isstruct(inputs) && isfield(inputs, 'time_h')
    time_h = inputs.time_h(:);
    if numel(time_h) ~= D
        time_h = (0:D-1).'*cfg.Dt;
    end
else
    time_h = (0:D-1).'*cfg.Dt;
end
nanVec = NaN(D, 1);

R = struct();
R.name = regime;
R.regime = regime;
R.time_h = time_h;
R.P_load = nanVec;
R.P_pv = nanVec;
R.P_app = nanVec;
R.P_grid_net = nanVec;
R.P_grid_import = nanVec;
R.P_grid_export = nanVec;
R.P_ev_net = nanVec;
R.P_ev_charge = nanVec;
R.P_ev_discharge = nanVec;
R.P_batt_net = nanVec;
R.P_batt_charge = nanVec;
R.P_batt_discharge = nanVec;
R.SOC_batt = nanVec;
R.SOC_ev = nanVec;
R.EV_available = nanVec;
R.P_balance_LHS = nanVec;
R.P_balance_RHS = nanVec;
R.cost.import = NaN;
R.cost.exportRevenue = NaN;
R.cost.batteryDegradation = NaN;
R.cost.evDegradation = NaN;
R.cost.total = NaN;
R.cost.unit = "GBP/day";
R.validation.powerBalance.pass = false;
R.validation.powerBalance.maxAbs_kW = NaN;
R.validation.powerBalance.rms_kW = NaN;
R.validation.bounds.pass = false;
R.validation.bounds.lowerBoundViolation = NaN;
R.validation.bounds.upperBoundViolation = NaN;
R.validation.gridLogic.pass = false;
R.validation.gridLogic.simultaneousImportExport_kW = NaN;
R.validation.gridLogic.gridBinarySumMax = NaN;
R.validation.evAvailability.pass = false;
R.validation.evAvailability.evDischargeWhileAway_kW = NaN;
R.validation.evAvailability.evChargeWhileAway_kW = NaN;
R.solver.status = "FAILED";
R.solver.objective = NaN;
R.solver.name = cfg.optimization.solver;
R.error.message = string(ME.message);
R.error.identifier = string(ME.identifier);
end
