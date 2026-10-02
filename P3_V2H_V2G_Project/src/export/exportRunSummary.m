function summaryFile = exportRunSummary(cfg, RESULTS, TABLES, EXPORT, TESTS)
%EXPORTRUNSUMMARY Write a concise reproducibility and validation summary.

summaryFile = fullfile(cfg.paths.outputs.logs, 'P3_run_summary.txt');

lines = strings(0, 1);
lines(end+1) = "P3 V2H/V2G reproducible run summary";
lines(end+1) = "Generated: " + string(datetime('now'));
lines(end+1) = "Project root: " + string(cfg.paths.projectRoot);
lines(end+1) = "";
lines(end+1) = "Regime results:";
regimes = cfg.project.regimeOrder;
for k = 1:numel(regimes)
    R = RESULTS.(regimes(k));
    lines(end+1) = sprintf('  %s: status=%s, net cost=%.6f GBP/day, import=%.6f GBP/day, export revenue=%.6f GBP/day', ...
        cfg.project.regimeLabels(k), R.solver.status, R.cost.total, R.cost.import, R.cost.exportRevenue);
end

lines(end+1) = "";
lines(end+1) = "Validation table:";
lines(end+1) = stripDisplayMarkup(string(evalc('disp(TABLES.Validation)')));

lines(end+1) = "";
lines(end+1) = "Export status:";
lines(end+1) = stripDisplayMarkup(string(evalc('disp(EXPORT.Figures)')));
lines(end+1) = stripDisplayMarkup(string(evalc('disp(EXPORT.Tables)')));
lines(end+1) = stripDisplayMarkup(string(evalc('disp(EXPORT.Text)')));
if isfield(EXPORT, 'Word')
    lines(end+1) = stripDisplayMarkup(string(evalc('disp(EXPORT.Word)')));
end

lines(end+1) = "";
lines(end+1) = "Sanity tests:";
testNames = string(fieldnames(TESTS));
for k = 1:numel(testNames)
    lines(end+1) = testNames(k) + ":";
    lines(end+1) = stripDisplayMarkup(string(evalc('disp(TESTS.(testNames(k)))')));
end

writeText(summaryFile, strjoin(lines, newline));

warningsFile = fullfile(cfg.paths.outputs.logs, 'P3_validation_warnings.txt');
warningLines = localValidationWarnings(TABLES.Validation);
writeText(warningsFile, strjoin(warningLines, newline));

fprintf('\nValidation summary written to: %s\n', summaryFile);
fprintf('Validation warnings written to: %s\n', warningsFile);
end

function txt = stripDisplayMarkup(txt)
txt = regexprep(txt, '</?strong>', '');
end

function lines = localValidationWarnings(T)
lines = strings(0, 1);
for i = 1:height(T)
    if any([contains(string(T.V2HOld(i)), "FAIL"), contains(string(T.V2H(i)), "FAIL"), contains(string(T.V2G(i)), "FAIL")])
        lines(end+1) = T.Metric(i) + ": V2HOld=" + string(T.V2HOld(i)) + ...
            ", V2H=" + string(T.V2H(i)) + ", V2G=" + string(T.V2G(i)); %#ok<AGROW>
    end
end
if isempty(lines)
    lines = "No validation failures reported.";
end
end

function writeText(fileName, txt)
fid = fopen(fileName, 'w');
if fid < 0
    error('Could not open %s for writing.', fileName);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', txt);
end
