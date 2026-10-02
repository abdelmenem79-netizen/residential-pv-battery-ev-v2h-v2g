function QC = validateMultiDayResults(MULTIDAY, cfg)
%VALIDATEMULTIDAYRESULTS Build quality-control checks for the multi-day run.

QC = table('Size', [0 4], ...
    'VariableTypes', {'string','logical','string','string'}, ...
    'VariableNames', {'Check','Pass','Details','Severity'});

QC = addCheck(QC, "required output fields", hasRequiredFields(MULTIDAY), ...
    "MULTIDAY contains screening, results, metrics, summary, statistics, validation, tariff, tables, and text fields.", "error");
QC = addCheck(QC, "screening tables present", istable(MULTIDAY.Screening.ValidDays) && istable(MULTIDAY.Screening.ExcludedDays), ...
    sprintf('valid days=%d, excluded days=%d', height(MULTIDAY.Screening.ValidDays), height(MULTIDAY.Screening.ExcludedDays)), "error");
QC = addCheck(QC, "daily metrics complete", istable(MULTIDAY.DailyMetrics) && height(MULTIDAY.DailyMetrics) >= 3*height(MULTIDAY.SelectedDays), ...
    sprintf('daily metric rows=%d', height(MULTIDAY.DailyMetrics)), "error");
QC = addCheck(QC, "finite cost values used in summary", allFinite(MULTIDAY.DailyMetrics.NetOperatingCost_GBP_per_day(MULTIDAY.DailyMetrics.UseInSummary)), ...
    "Net operating costs are finite for rows included in summary statistics.", "error");
QC = addCheck(QC, "non-negative import and export energy", nonnegativeEnergy(MULTIDAY.DailyMetrics), ...
    "Grid import/export energy is non-negative where finite.", "error");
QC = addCheck(QC, "V2H-Old export near zero", oldExportNearZero(MULTIDAY.DailyMetrics, cfg), ...
    "Restrictive V2H-Old export energy is zero or within tolerance.", "warning");
QC = addCheck(QC, "corrected EV availability", correctedEVAvailabilityPass(MULTIDAY.DailyMetrics), ...
    "Corrected V2H and V2G rows used in summaries pass EV availability.", "error");
QC = addCheck(QC, "SOC values finite", socFinite(MULTIDAY.DailyMetrics), ...
    "Battery and EV SOC summary values are finite for rows used in summary statistics.", "warning");
QC = addCheck(QC, "statistical paired comparison rows", istable(MULTIDAY.StatisticalResults) && height(MULTIDAY.StatisticalResults) >= 7, ...
    sprintf('statistical rows=%d', height(MULTIDAY.StatisticalResults)), "warning");
QC = addCheck(QC, "table set created", isstruct(MULTIDAY.Tables) && numel(fieldnames(MULTIDAY.Tables)) >= 8, ...
    sprintf('paper table fields=%d', numel(fieldnames(MULTIDAY.Tables))), "warning");

diagnosticFile = fullfile(cfg.paths.outputs.multiday.diagnostics, 'MULTIDAY_quality_control.csv');
writetable(QC, diagnosticFile);
end

function tf = hasRequiredFields(M)
required = ["Screening","Results","DailyMetrics","SummaryMetrics","StatisticalResults", ...
    "ValidationSummary","TariffSensitivity","Tables","GeneratedText","RunLog"];
tf = all(arrayfun(@(s) isfield(M, char(s)), required));
end

function T = addCheck(T, name, pass, details, severity)
row = table(string(name), logical(pass), string(details), string(severity), ...
    'VariableNames', T.Properties.VariableNames);
T = [T; row];
end

function tf = allFinite(x)
tf = isempty(x) || all(isfinite(x));
end

function tf = nonnegativeEnergy(T)
values = [T.GridImportEnergy_kWh_per_day; T.GridExportEnergy_kWh_per_day];
values = values(isfinite(values));
tf = isempty(values) || all(values >= -1e-6);
end

function tf = oldExportNearZero(T, cfg)
rows = T.Regime == "V2HOld" & T.SolverSolved;
if ~any(rows)
    tf = true;
    return
end
tf = max(abs(T.GridExportEnergy_kWh_per_day(rows)), [], 'omitnan') <= max(1e-5, cfg.validation.tolerance);
end

function tf = correctedEVAvailabilityPass(T)
rows = (T.Regime == "V2H" | T.Regime == "V2G") & T.UseInSummary;
tf = ~any(rows) || all(T.EVAvailabilityPass(rows));
end

function tf = socFinite(T)
rows = T.UseInSummary;
values = [T.BatterySOCMin_pct(rows); T.BatterySOCMax_pct(rows); T.EVSOCMin_pct(rows); T.EVSOCMax_pct(rows)];
values = values(:);
tf = isempty(values) || all(isfinite(values));
end
