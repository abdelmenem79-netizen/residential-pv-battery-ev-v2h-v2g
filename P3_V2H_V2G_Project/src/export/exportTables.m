function status = exportTables(TABLES, cfg)
%EXPORTTABLES Export paper tables to XLSX, CSV, LaTeX, Markdown, and TXT.

names = string(fieldnames(TABLES));
status = table('Size', [numel(names), 6], ...
    'VariableTypes', {'string','logical','logical','logical','logical','string'}, ...
    'VariableNames', {'TableName', 'SavedXLSX', 'SavedCSV', 'SavedTEX', 'SavedMD', 'Message'});

xlsxFile = fullfile(cfg.paths.outputs.tables, 'P3_tables.xlsx');
if exist(xlsxFile, 'file')
    delete(xlsxFile);
end

for k = 1:numel(names)
    name = names(k);
    status.TableName(k) = name;
    status.Message(k) = "";
    T = TABLES.(name);

    if ~istable(T)
        status.Message(k) = "Skipped non-table field.";
        continue
    end

    try
        sheetName = char(extractBefore(name + "_______________________________", 32));
        writetable(T, xlsxFile, 'Sheet', sheetName);
        status.SavedXLSX(k) = true;

        writetable(T, fullfile(cfg.paths.outputs.tables, name + ".csv"));
        status.SavedCSV(k) = true;

        writeText(fullfile(cfg.paths.outputs.tables, name + ".tex"), tableToLatex(T, name));
        status.SavedTEX(k) = true;

        writeText(fullfile(cfg.paths.outputs.tables, name + ".md"), tableToMarkdown(T));
        status.SavedMD(k) = true;

        writeText(fullfile(cfg.paths.outputs.tables, name + ".txt"), tableToMarkdown(T));
    catch ME
        status.Message(k) = string(ME.message);
    end
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

function txt = tableToLatex(T, label)
headers = string(T.Properties.VariableNames);
lines = strings(0, 1);
lines(end+1) = "\begin{table}[!t]";
lines(end+1) = "\centering";
lines(end+1) = "\caption{" + strrep(string(T.Properties.Description), "_", "\_") + "}";
lines(end+1) = "\label{tab:" + lower(regexprep(string(label), '[^A-Za-z0-9]+', '_')) + "}";
lines(end+1) = "\begin{tabular}{" + strjoin(repmat("l", 1, width(T)), "") + "}";
lines(end+1) = "\hline";
lines(end+1) = strjoin(escapeLatex(headers), " & ") + " \\";
lines(end+1) = "\hline";
for i = 1:height(T)
    row = strings(1, width(T));
    for j = 1:width(T)
        row(j) = escapeLatex(valueToString(T{i,j}));
    end
    lines(end+1) = strjoin(row, " & ") + " \\";
end
lines(end+1) = "\hline";
lines(end+1) = "\end{tabular}";
lines(end+1) = "\end{table}";
txt = strjoin(lines, newline);
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

function s = valueToString(v)
if isnumeric(v)
    s = string(compose('%.6g', v));
elseif islogical(v)
    s = string(v);
elseif iscell(v)
    s = string(v{1});
else
    s = string(v);
end
end

function s = escapeLatex(s)
s = string(s);
s = replace(s, "\", "\textbackslash{}");
s = replace(s, "_", "\_");
s = replace(s, "%", "\%");
s = replace(s, "&", "\&");
end
