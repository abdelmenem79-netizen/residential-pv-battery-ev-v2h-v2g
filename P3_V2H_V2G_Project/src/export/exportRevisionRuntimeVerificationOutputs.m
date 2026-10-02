function status = exportRevisionRuntimeVerificationOutputs(verificationSummary, TABLES, cfg)
%EXPORTREVISIONRUNTIMEVERIFICATIONOUTPUTS Save reviewer-requested outputs.

outDir = cfg.paths.revisionRuntimeVerification;
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

summaryTable = TABLES.RevisionVerificationSummary;
performanceTable = TABLES.ComputationalPerformance;
physicalTable = TABLES.PhysicalConsistency;
detailedValidationTable = TABLES.Validation;

summaryCSV = fullfile(outDir, 'verificationSummary.csv');
performanceCSV = fullfile(outDir, 'TABLE_X_computational_performance_and_verification_summary.csv');
physicalCSV = fullfile(outDir, 'TABLE_Y_physical_consistency_checks.csv');
detailedValidationCSV = fullfile(outDir, 'corrected_detailed_validation_table.csv');
xlsxFile = fullfile(outDir, 'revision_runtime_verification_summary.xlsx');
matFile = fullfile(outDir, 'revision_runtime_verification_summary.mat');
tableXText = fullfile(outDir, 'TABLE_X_computational_performance_and_verification_summary.txt');
tableYText = fullfile(outDir, 'TABLE_Y_physical_consistency_checks.txt');
detailedValidationText = fullfile(outDir, 'corrected_detailed_validation_table.txt');
paragraphFile = fullfile(outDir, 'IEEE_ready_computational_overhead_paragraph.txt');
readmeFile = fullfile(outDir, 'README.md');

writetable(summaryTable, summaryCSV);
writetable(performanceTable, performanceCSV);
writetable(physicalTable, physicalCSV);
writetable(detailedValidationTable, detailedValidationCSV);

if exist(xlsxFile, 'file')
    delete(xlsxFile);
end
writetable(summaryTable, xlsxFile, 'Sheet', 'verificationSummary');
writetable(performanceTable, xlsxFile, 'Sheet', 'TABLE_X');
writetable(physicalTable, xlsxFile, 'Sheet', 'TABLE_Y');
writetable(detailedValidationTable, xlsxFile, 'Sheet', 'DetailedValidation');

save(matFile, 'verificationSummary', 'summaryTable', 'performanceTable', 'physicalTable', 'detailedValidationTable', 'cfg', '-v7.3');

writeText(tableXText, performanceTableText(performanceTable));
writeText(tableYText, physicalTableText(physicalTable));
writeText(detailedValidationText, markdownTable(detailedValidationTable));
writeText(paragraphFile, ieeeRuntimeParagraph(performanceTable));
writeText(readmeFile, revisionReadme(outDir));

status = struct();
status.outputFolder = outDir;
status.summaryCSV = summaryCSV;
status.performanceCSV = performanceCSV;
status.physicalCSV = physicalCSV;
status.detailedValidationCSV = detailedValidationCSV;
status.excelWorkbook = xlsxFile;
status.matFile = matFile;
status.tableXText = tableXText;
status.tableYText = tableYText;
status.detailedValidationText = detailedValidationText;
status.paragraphText = paragraphFile;
status.readme = readmeFile;
end

function txt = performanceTableText(T)
lines = strings(0, 1);
lines(end+1) = "TABLE X";
lines(end+1) = "COMPUTATIONAL PERFORMANCE AND VERIFICATION SUMMARY";
lines(end+1) = "";
lines(end+1) = "| Regime | T | Continuous variables | Binary variables | Solver status | Optimisation time (s) | Verification time (s) | Max residual (kW) | RMS residual (kW) |";
lines(end+1) = "|---|---:|---:|---:|---|---:|---:|---:|---:|";
for i = 1:height(T)
    lines(end+1) = sprintf('| %s | %.0f | %.0f | %.0f | %s | %s | %s | %s | %s |', ...
        char(string(T.Regime(i))), T.T(i), T.ContinuousVariables(i), T.BinaryVariables(i), ...
        char(string(T.SolverStatus(i))), char(formatNumber(T.OptimisationTime_s(i), 'time')), ...
        char(formatNumber(T.VerificationTime_s(i), 'time')), ...
        char(formatNumber(T.MaxResidual_kW(i), 'residual')), ...
        char(formatNumber(T.RMSResidual_kW(i), 'residual')));
end
txt = strjoin(lines, newline);
end

function txt = physicalTableText(T)
lines = strings(0, 1);
lines(end+1) = "TABLE Y";
lines(end+1) = "PHYSICAL CONSISTENCY CHECKS";
lines(end+1) = "";
lines(end+1) = "| Regime | Bound check | Grid exclusivity | EV availability | EV charge away (kW) | EV discharge away (kW) | Cost reconstruction error |";
lines(end+1) = "|---|---|---|---|---:|---:|---:|";
for i = 1:height(T)
    lines(end+1) = sprintf('| %s | %s | %s | %s | %s | %s | %s |', ...
        char(string(T.Regime(i))), char(string(T.BoundCheck(i))), char(string(T.GridExclusivity(i))), ...
        char(string(T.EVAvailability(i))), char(formatNumber(T.EVChargeAway_kW(i), 'residual')), ...
        char(formatNumber(T.EVDischargeAway_kW(i), 'residual')), ...
        char(formatNumber(T.CostReconstructionError(i), 'residual')));
end
txt = strjoin(lines, newline);
end

function txt = ieeeRuntimeParagraph(T)
if any(~isfinite(T.OptimisationTime_s)) || any(~isfinite(T.VerificationTime_s))
    txt = "TODO: Runtime values were not calculated because at least one optimisation/verification run did not complete.";
    return
end

uniqueT = unique(T.T);
uniqueCont = unique(T.ContinuousVariables);
uniqueBin = unique(T.BinaryVariables);
maxResidual = max(T.MaxResidual_kW);
rmsResidual = max(T.RMSResidual_kW);

if numel(uniqueT) == 1 && numel(uniqueCont) == 1 && numel(uniqueBin) == 1
    sizeText = sprintf('Each single-day MILP used T = %.0f ten-minute intervals, %.0f continuous variables, and %.0f binary variables.', ...
        uniqueT(1), uniqueCont(1), uniqueBin(1));
else
    sizeText = sprintf('Across the three regimes, the single-day MILPs used T = %.0f-%.0f intervals, %.0f-%.0f continuous variables, and %.0f-%.0f binary variables.', ...
        min(T.T), max(T.T), min(T.ContinuousVariables), max(T.ContinuousVariables), min(T.BinaryVariables), max(T.BinaryVariables));
end

txt = sprintf(['%s Using CVX with Gurobi, the optimisation solve times were %.3f-%.3f s, while the independent ' ...
    'post-solution verification checks required %.3f-%.3f s. The maximum solver-side power-balance residual across all regimes was %s kW ' ...
    'and the largest RMS residual was %s kW, confirming that the reported dispatch profiles satisfy the implemented balance equations to numerical precision. ' ...
    'Because the device set is fixed, the number of scalar decision variables scales linearly with the number of time steps T, so longer horizons increase the computational burden primarily through this linear growth in continuous and binary variables.'], ...
    sizeText, min(T.OptimisationTime_s), max(T.OptimisationTime_s), ...
    min(T.VerificationTime_s), max(T.VerificationTime_s), ...
    formatNumber(maxResidual, 'residual'), formatNumber(rmsResidual, 'residual'));
end

function txt = revisionReadme(outDir)
lines = strings(0, 1);
lines(end+1) = "# Revision Runtime And Verification Outputs";
lines(end+1) = "";
lines(end+1) = "This folder contains the corrected runtime, variable-count, and verification outputs for the IEEE Access revision.";
lines(end+1) = "";
lines(end+1) = "## Changed Files";
lines(end+1) = "";
lines(end+1) = "- `P3_V2H_V2G_Project/run_P3_all.m`";
lines(end+1) = "- `P3_V2H_V2G_Project/run_revision_runtime_verification.m`";
lines(end+1) = "- `P3_V2H_V2G_Project/src/setup/buildConfig.m`";
lines(end+1) = "- `P3_V2H_V2G_Project/src/optimisation/solveStorageRegimeCVX.m`";
lines(end+1) = "- `P3_V2H_V2G_Project/src/optimisation/reconstructResults.m`";
lines(end+1) = "- `P3_V2H_V2G_Project/src/optimisation/countModelVariables.m`";
lines(end+1) = "- `P3_V2H_V2G_Project/src/validation/validatePowerBalance.m`";
lines(end+1) = "- `P3_V2H_V2G_Project/src/validation/validateCostReconstruction.m`";
lines(end+1) = "- `P3_V2H_V2G_Project/src/validation/runPostSolutionVerification.m`";
lines(end+1) = "- `P3_V2H_V2G_Project/src/validation/buildVerificationSummary.m`";
lines(end+1) = "- `P3_V2H_V2G_Project/src/validation/buildRuntimeVerificationTables.m`";
lines(end+1) = "- `P3_V2H_V2G_Project/src/export/exportRevisionRuntimeVerificationOutputs.m`";
lines(end+1) = "- `V2H_optimise.m`";
lines(end+1) = "- `V2G.m`";
lines(end+1) = "- `V2H_old_V2H_vs_V2G_Results_Comparison_and_Energy_Script.m`";
lines(end+1) = "- `V2H_old_V2H_vs_V2G_Results_Comparison_and_Energy_Script_1.m`";
lines(end+1) = "";
lines(end+1) = "## How To Rerun";
lines(end+1) = "";
lines(end+1) = "From MATLAB, change to `P3_V2H_V2G_Project` and run:";
lines(end+1) = "";
lines(end+1) = "```matlab";
lines(end+1) = "run_revision_runtime_verification";
lines(end+1) = "```";
lines(end+1) = "";
lines(end+1) = "The full project workflow can also be rerun with `run_P3_all`; it now creates the same revision summary after the single-day regimes are verified.";
lines(end+1) = "";
lines(end+1) = "## Corrected Tables";
lines(end+1) = "";
lines(end+1) = "The corrected CSV, Excel, MAT, and text tables are saved in:";
lines(end+1) = "";
lines(end+1) = "`" + string(outDir) + "`";
lines(end+1) = "";
lines(end+1) = "Key files are `verificationSummary.csv`, `corrected_detailed_validation_table.txt`, `TABLE_X_computational_performance_and_verification_summary.txt`, and `TABLE_Y_physical_consistency_checks.txt`.";
lines(end+1) = "";
lines(end+1) = "## Residual Inconsistency";
lines(end+1) = "";
lines(end+1) = "The old compact text calculated `P_load - (P_pv + P_ev_net + P_batt_net + P_grid_net)`, which omitted scheduled appliance demand. Some legacy V2H/V2G post-processing also stored the plotted balance with `+P_app` instead of the solver convention. The detailed validation table used the model-level equality, so it reported residuals near numerical precision while the compact draft text reported the appliance-sized mismatch.";
lines(end+1) = "";
lines(end+1) = "## Residual Definition";
lines(end+1) = "";
lines(end+1) = "The paper now uses the authoritative solver-side residual:";
lines(end+1) = "";
lines(end+1) = "```matlab";
lines(end+1) = "balance_residual_kW = A1*x + A10*POn - b1;";
lines(end+1) = "maxAbsBalanceResidual_kW = max(abs(balance_residual_kW));";
lines(end+1) = "rmsBalanceResidual_kW = sqrt(mean(balance_residual_kW.^2));";
lines(end+1) = "```";
txt = strjoin(lines, newline);
end

function txt = markdownTable(T)
headers = string(T.Properties.VariableNames);
lines = strings(0, 1);
lines(end+1) = "| " + strjoin(headers, " | ") + " |";
lines(end+1) = "| " + strjoin(repmat("---", 1, width(T)), " | ") + " |";
for i = 1:height(T)
    row = strings(1, width(T));
    for j = 1:width(T)
        row(j) = valueToString(T{i,j});
    end
    lines(end+1) = "| " + strjoin(row, " | ") + " |";
end
txt = strjoin(lines, newline);
end

function s = valueToString(v)
if isnumeric(v)
    v(v == 0) = 0;
    s = string(compose('%.6g', v));
elseif islogical(v)
    s = string(v);
elseif iscell(v)
    s = string(v{1});
else
    s = string(v);
end
end

function s = formatNumber(x, mode)
mode = string(mode);
if ~isfinite(x)
    s = "TODO";
elseif x == 0
    s = "0.0000";
elseif mode == "time"
    s = string(sprintf('%.3f', x));
elseif abs(x) > 0 && abs(x) < 1e-3
    s = string(sprintf('%.3e', x));
else
    s = string(sprintf('%.4f', x));
end
end

function writeText(fileName, txt)
fid = fopen(fileName, 'w');
if fid < 0
    error('Could not open %s for writing.', fileName);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', string(txt));
end
