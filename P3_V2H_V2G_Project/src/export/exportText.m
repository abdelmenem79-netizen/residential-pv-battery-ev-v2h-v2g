function status = exportText(TEXT, cfg)
%EXPORTTEXT Export generated paper-support text to TXT files.

entries = flattenText(TEXT);
names = string(fieldnames(entries));
status = table('Size', [numel(names), 3], ...
    'VariableTypes', {'string','logical','string'}, ...
    'VariableNames', {'TextName', 'SavedTXT', 'Message'});

combined = strings(0, 1);
for k = 1:numel(names)
    name = names(k);
    status.TextName(k) = name;
    status.Message(k) = "";
    try
        txt = string(entries.(name));
        fileName = fullfile(cfg.paths.outputs.text, name + ".txt");
        writeText(fileName, txt);
        combined(end+1) = upper(name); %#ok<AGROW>
        combined(end+1) = txt; %#ok<AGROW>
        combined(end+1) = ""; %#ok<AGROW>
        status.SavedTXT(k) = true;
    catch ME
        status.Message(k) = string(ME.message);
    end
end

writeText(fullfile(cfg.paths.outputs.text, 'P3_all_generated_text.txt'), strjoin(combined, newline));
end

function entries = flattenText(TEXT)
entries = struct();
top = string(fieldnames(TEXT));
for i = 1:numel(top)
    item = TEXT.(top(i));
    if isstruct(item)
        sub = string(fieldnames(item));
        for j = 1:numel(sub)
            entries.(top(i) + "_" + sub(j)) = string(item.(sub(j)));
        end
    elseif istable(item)
        entries.(top(i)) = regexprep(string(evalc('disp(item)')), '</?strong>', '');
    else
        entries.(top(i)) = string(item);
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
