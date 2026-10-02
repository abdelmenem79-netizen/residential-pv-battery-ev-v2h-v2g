function Export = exportMultiDayOutputs(MULTIDAY, cfg)
%EXPORTMULTIDAYOUTPUTS Export multi-day tables, figures, text, and summary.

Export = struct();
Export.Tables = exportTablesLocal(MULTIDAY, cfg);
Export.Figures = exportFiguresLocal(MULTIDAY.Figures, cfg);
Export.Text = exportTextLocal(MULTIDAY.Text, cfg);
Export.SummaryText = exportRobustnessSummary(MULTIDAY, cfg);
end

function status = exportTablesLocal(MULTIDAY, cfg)
tablesDir = cfg.paths.outputs.multiday.tables;
cleanGeneratedTableFiles(tablesDir);
status = table('Size', [0 5], ...
    'VariableTypes', {'string','logical','logical','logical','string'}, ...
    'VariableNames', {'TableName','SavedXLSX','SavedCSV','SavedTEX','Message'});

tableSet = struct();
tableSet.ValidDays = MULTIDAY.Screening.ValidDays;
tableSet.ExcludedDays = MULTIDAY.Screening.ExcludedDays;
tableSet.SelectedDays = MULTIDAY.SelectedDays;
tableSet.DailyMetrics = MULTIDAY.DailyMetrics;
tableSet.SummaryMetrics = MULTIDAY.SummaryMetrics;
tableSet.RegimeComparison = MULTIDAY.RegimeComparison;
tableSet.ValidationSummary = MULTIDAY.ValidationSummary;
tableSet.StatisticalComparison = MULTIDAY.StatisticalResults;
tableSet.TariffSensitivity = MULTIDAY.TariffSensitivity;
if isfield(MULTIDAY, 'QualityControl')
    tableSet.QualityControl = MULTIDAY.QualityControl;
end
paperNames = string(fieldnames(MULTIDAY.PaperTables));
for p = 1:numel(paperNames)
    paperName = char(paperNames(p));
    tableSet.(paperName) = MULTIDAY.PaperTables.(paperName);
end

if cfg.analysis.annualise
    tableSet.AnnualisedFromRepresentativeMean = buildAnnualisedTable(MULTIDAY.SummaryMetrics, cfg);
end

names = string(fieldnames(tableSet));
combinedFile = fullfile(tablesDir, 'MULTIDAY_all_tables.xlsx');
dailyFile = fullfile(tablesDir, 'MULTIDAY_daily_metrics.xlsx');
summaryFile = fullfile(tablesDir, 'MULTIDAY_summary_metrics.xlsx');
statisticsFile = fullfile(tablesDir, 'MULTIDAY_statistical_comparison.xlsx');
excludedFile = fullfile(tablesDir, 'MULTIDAY_excluded_days.xlsx');
validFile = fullfile(tablesDir, 'MULTIDAY_valid_days.xlsx');
if exist(combinedFile, 'file'), delete(combinedFile); end
if exist(dailyFile, 'file'), delete(dailyFile); end
if exist(summaryFile, 'file'), delete(summaryFile); end
if exist(statisticsFile, 'file'), delete(statisticsFile); end
if exist(excludedFile, 'file'), delete(excludedFile); end
if exist(validFile, 'file'), delete(validFile); end

for k = 1:numel(names)
    name = names(k);
    T = tableSet.(name);
    row = table(name, false, false, false, "", 'VariableNames', status.Properties.VariableNames);
    try
        sheetName = char(extractBefore(name + "_______________________________", 32));
        writetable(T, combinedFile, 'Sheet', sheetName);
        writetable(T, fullfile(tablesDir, name + ".csv"));
        writeText(fullfile(tablesDir, name + ".md"), tableToMarkdown(T));
        writeText(fullfile(tablesDir, name + ".txt"), tableToMarkdown(T));
        writeText(fullfile(tablesDir, name + ".tex"), tableToLatex(T));
        row.SavedXLSX = true;
        row.SavedCSV = true;
        row.SavedTEX = true;
    catch ME
        row.Message = string(ME.message);
    end
    status = [status; row]; %#ok<AGROW>
end

writetable(MULTIDAY.DailyMetrics, dailyFile, 'Sheet', 'DailyMetrics');
writetable(MULTIDAY.SummaryMetrics, summaryFile, 'Sheet', 'SummaryMetrics');
writetable(MULTIDAY.StatisticalResults, statisticsFile, 'Sheet', 'StatisticalComparison');
writetable(MULTIDAY.Screening.ExcludedDays, excludedFile, 'Sheet', 'ExcludedDays');
writetable(MULTIDAY.Screening.ValidDays, validFile, 'Sheet', 'ValidDays');
end

function cleanGeneratedTableFiles(tablesDir)
patterns = ["*.xlsx","*.csv","*.md","*.txt","*.tex"];
for p = 1:numel(patterns)
    files = dir(fullfile(tablesDir, patterns(p)));
    for k = 1:numel(files)
        delete(fullfile(files(k).folder, files(k).name));
    end
end
end

function status = exportFiguresLocal(FIGURES, cfg)
cleanGeneratedFigureFiles(cfg);
status = table('Size', [numel(FIGURES), 6], ...
    'VariableTypes', {'string','logical','logical','logical','logical','string'}, ...
    'VariableNames', {'Figure','SavedFIG','SavedPNG','SavedEPS','SavedPDF','Message'});
for k = 1:numel(FIGURES)
    fig = FIGURES(k).handle;
    base = char(FIGURES(k).baseName);
    status.Figure(k) = string(base);
    status.Message(k) = "";
    try
        if cfg.export.saveFig
            savefig(fig, fullfile(cfg.paths.outputs.multiday.figures.fig, [base '.fig']));
            status.SavedFIG(k) = true;
        end
        if cfg.export.savePng
            exportgraphics(fig, fullfile(cfg.paths.outputs.multiday.figures.png, [base '.png']), ...
                'Resolution', cfg.figure.dpi);
            status.SavedPNG(k) = true;
        end
        if cfg.export.savePdf
            exportgraphics(fig, fullfile(cfg.paths.outputs.multiday.figures.pdf, [base '.pdf']), ...
                'ContentType', 'vector');
            status.SavedPDF(k) = true;
        end
        if cfg.export.saveEps
            print(fig, fullfile(cfg.paths.outputs.multiday.figures.eps, [base '.eps']), ...
                '-depsc', sprintf('-r%d', cfg.figure.dpi));
            status.SavedEPS(k) = true;
        end
    catch ME
        status.Message(k) = string(ME.message);
    end
end
end

function cleanGeneratedFigureFiles(cfg)
folders = [
    string(cfg.paths.outputs.multiday.figures.fig)
    string(cfg.paths.outputs.multiday.figures.png)
    string(cfg.paths.outputs.multiday.figures.eps)
    string(cfg.paths.outputs.multiday.figures.pdf)
    ];
patterns = ["Fig*_multiday_*.*"];
for f = 1:numel(folders)
    for p = 1:numel(patterns)
        files = dir(fullfile(folders(f), patterns(p)));
        for k = 1:numel(files)
            delete(fullfile(files(k).folder, files(k).name));
        end
    end
end
end

function status = exportTextLocal(Text, cfg)
textDir = cfg.paths.outputs.multiday.text;
names = string(fieldnames(Text));
status = table('Size', [numel(names), 3], ...
    'VariableTypes', {'string','logical','string'}, ...
    'VariableNames', {'TextName','SavedTXT','Message'});
combined = strings(0, 1);
for k = 1:numel(names)
    name = names(k);
    status.TextName(k) = name;
    status.Message(k) = "";
    try
        txt = string(Text.(name));
        writeText(fullfile(textDir, "MULTIDAY_" + name + ".txt"), txt);
        combined(end+1) = upper(name); %#ok<AGROW>
        combined(end+1) = txt; %#ok<AGROW>
        combined(end+1) = ""; %#ok<AGROW>
        status.SavedTXT(k) = true;
    catch ME
        status.Message(k) = string(ME.message);
    end
end
writeText(fullfile(textDir, 'MULTIDAY_all_generated_text.txt'), strjoin(combined, newline));
end

function fileName = exportRobustnessSummary(MULTIDAY, cfg)
fileName = fullfile(cfg.paths.outputs.multiday.text, 'MULTIDAY_robustness_summary.txt');
lines = strings(0, 1);
lines(end+1) = "P3 multi-day robustness summary";
lines(end+1) = "Generated: " + string(datetime('now'));
lines(end+1) = "";
lines(end+1) = "Selected dates:";
for i = 1:height(MULTIDAY.SelectedDays)
    lines(end+1) = sprintf('  %02d | %.0f | %s | %s', ...
        MULTIDAY.SelectedDays.DayIndex(i), MULTIDAY.SelectedDays.Date(i), ...
        MULTIDAY.SelectedDays.DateLabel(i), MULTIDAY.SelectedDays.SelectionReason(i));
end
lines(end+1) = "";
lines(end+1) = "Robustness comparison:";
lines(end+1) = tableToMarkdown(MULTIDAY.RegimeComparison);
lines(end+1) = "";
lines(end+1) = "Validation summary:";
lines(end+1) = tableToMarkdown(MULTIDAY.ValidationSummary);
lines(end+1) = "";
lines(end+1) = "Paper-ready interpretation:";
lines(end+1) = MULTIDAY.Text.results_paragraph;
lines(end+1) = MULTIDAY.Text.limitations;
writeText(fileName, strjoin(lines, newline));
writeText(fullfile(cfg.paths.outputs.multiday.logs, 'MULTIDAY_run_log.txt'), tableToMarkdown(MULTIDAY.RunLog));
end

function T = buildAnnualisedTable(Summary, cfg)
regimes = cfg.project.regimeOrder;
Metric = [
    "Annualised mean net operating cost from representative-day mean";
    "Annualised mean export revenue from representative-day mean"
    ];
Unit = [
    "GBP/year";
    "GBP/year"
    ];
values = NaN(numel(Metric), numel(regimes));
for r = 1:numel(regimes)
    values(:, r) = 365 * [
        lookupSummary(Summary, "Net operating cost (GBP/day)", regimes(r), "Mean")
        lookupSummary(Summary, "Export revenue (GBP/day)", regimes(r), "Mean")
        ];
end
T = table(Metric, Unit, values(:,1), values(:,2), values(:,3), ...
    'VariableNames', {'Metric','Unit','V2HOld','V2H','V2G'});
T.Properties.Description = "Annualised values from representative-day mean; not measured annual results.";
end

function x = lookupSummary(Summary, metric, regime, statName)
idx = Summary.Metric == metric & Summary.Regime == regime;
if any(idx)
    x = Summary.(statName)(find(idx, 1));
else
    x = NaN;
end
end

function writeText(fileName, txt)
fid = fopen(fileName, 'w');
if fid < 0
    error('Could not open %s for writing.', fileName);
end
cleanup = onCleanup(@() fclose(fid));
txt = string(txt);
if numel(txt) > 1
    txt = strjoin(txt(:), newline);
end
fprintf(fid, '%s', txt);
end

function txt = tableToMarkdown(T)
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

function txt = tableToLatex(T)
headers = string(T.Properties.VariableNames);
lines = strings(0, 1);
lines(end+1) = "\\begin{tabular}{" + strjoin(repmat("l", 1, width(T)), "") + "}";
lines(end+1) = "\\hline";
lines(end+1) = strjoin(escapeLatex(headers), " & ") + " \\";
lines(end+1) = "\\hline";
for i = 1:height(T)
    row = strings(1, width(T));
    for j = 1:width(T)
        row(j) = escapeLatex(valueToString(T{i,j}));
    end
    lines(end+1) = strjoin(row, " & ") + " \\";
end
lines(end+1) = "\\hline";
lines(end+1) = "\\end{tabular}";
txt = strjoin(lines, newline);
end

function s = escapeLatex(s)
s = string(s);
s = replace(s, string(char(92)), "\\textbackslash{}");
s = replace(s, "_", "\_");
s = replace(s, "%", "\%");
s = replace(s, "&", "\&");
s = replace(s, "#", "\#");
s = replace(s, "{", "\{");
s = replace(s, "}", "\}");
end

function s = valueToString(v)
if iscell(v)
    v = v{1};
end
if isnumeric(v)
    if isscalar(v)
        s = string(compose('%.6g', v));
    else
        s = "[" + strjoin(compose('%.6g', v(:).'), ", ") + "]";
    end
elseif islogical(v)
    s = string(v);
else
    s = string(v);
end
end
