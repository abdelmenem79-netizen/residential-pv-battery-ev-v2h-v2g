function reportPath = generateWordReportP3(RESULTS, TABLES, TEXT, FIGURES, TESTS, EXPORT, MULTIDAY, cfg)
%GENERATEWORDREPORTP3 Create the complete P3 multi-day IEEE Word report.
%
% The implementation writes a standards-compliant OpenXML DOCX package
% directly from MATLAB so the report can be produced even when MATLAB Report
% Generator is not installed.

if nargin < 8
    error('generateWordReportP3 requires RESULTS, TABLES, TEXT, FIGURES, TESTS, EXPORT, MULTIDAY, and cfg.');
end

reportDir = cfg.paths.outputs.multiday.reports;
if ~exist(reportDir, 'dir')
    mkdir(reportDir);
end
reportPath = fullfile(reportDir, char(cfg.analysis.wordReportName));
if exist(reportPath, 'file')
    delete(reportPath);
end

tmpRoot = tempname;
mkdir(tmpRoot);
mkdir(fullfile(tmpRoot, '_rels'));
mkdir(fullfile(tmpRoot, 'word'));
mkdir(fullfile(tmpRoot, 'word', '_rels'));
mkdir(fullfile(tmpRoot, 'word', 'media'));
cleanup = onCleanup(@() removeTempDir(tmpRoot));

doc = strings(0, 1);
rels = strings(0, 1);
imageCounter = 0;

doc(end+1) = paragraph("P3 Multi-Day Results and Statistical Report", "title");
doc(end+1) = paragraph("Economic Impact of Export Revenue in Residential V2H and V2G Optimisation", "subtitle");
doc(end+1) = paragraph("Generated: " + string(datetime('now')), "normal");
doc(end+1) = paragraph("Project root: " + string(cfg.paths.projectRoot), "normal");
doc(end+1) = paragraph(sprintf('Candidate days: %d | valid days: %d | excluded days: %d | regimes: %d | solver: %s', ...
    MULTIDAY.Screening.Summary.CandidateDays(1), MULTIDAY.Screening.Summary.ValidDays(1), ...
    MULTIDAY.Screening.Summary.ExcludedDays(1), numel(cfg.project.regimeOrder), cfg.optimization.solver), "normal");
doc(end+1) = pageBreak();

doc(end+1) = heading("Executive Summary", 1);
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "methodology_paragraph"), "normal");
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "multi_day_results_text"), "normal");
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "validation_text"), "normal");
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "limitations_text"), "normal");

doc(end+1) = heading("Workflow Diagram", 1);
doc(end+1) = workflowTable();
doc(end+1) = paragraph("Configuration leads to transparent data screening, valid-day selection, three-regime optimisation, validation, metrics, statistical comparison, figure/table export, and final Word reporting.", "caption");

doc(end+1) = heading("Data Screening", 1);
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "data_screening_text"), "normal");
doc(end+1) = heading("Table A. Data Screening Summary", 2);
doc(end+1) = wordTable(MULTIDAY.Tables.TableA_DataScreeningSummary);
doc(end+1) = heading("Table B. Excluded Days Log", 2);
doc(end+1) = wordTable(MULTIDAY.Tables.TableB_ExcludedDaysLog);
doc(end+1) = heading("Table C. Valid Days Classification", 2);
doc(end+1) = wordTable(MULTIDAY.Tables.TableC_ValidDaysClassification);
[doc, rels, imageCounter] = addFigureByToken(doc, rels, imageCounter, MULTIDAY.Figures, cfg.paths.outputs.multiday.figures.png, ...
    "representative_day_map", "Figure M8. Representative-day classification map.");

doc(end+1) = heading("Single-Day Operational Case Study", 1);
if ~isempty(fieldnames(RESULTS))
    doc(end+1) = paragraph(getSingleDayText(TEXT, "Results"), "normal");
    doc(end+1) = heading("Table D. Single-Day Operational Comparison", 2);
    doc(end+1) = wordTable(tableOrEmpty(TABLES, "Operational"));
    doc(end+1) = heading("Table E. Single-Day Economic Comparison", 2);
    doc(end+1) = wordTable(tableOrEmpty(TABLES, "Economic"));
    doc(end+1) = heading("Table F. Single-Day Validation Summary", 2);
    doc(end+1) = wordTable(tableOrEmpty(TABLES, "Validation"));
    [doc, rels, imageCounter] = addFigureSet(doc, rels, imageCounter, FIGURES, cfg.paths.outputs.figures.png, ...
        "Single-day IEEE figures");
else
    doc(end+1) = paragraph("Single-day analysis was not executed in this run because cfg.analysis.mode did not request it.", "normal");
end

doc(end+1) = heading("Multi-Day Robustness Results", 1);
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "multi_day_results_text"), "normal");
[doc, rels, imageCounter] = addFigureByToken(doc, rels, imageCounter, MULTIDAY.Figures, cfg.paths.outputs.multiday.figures.png, ...
    "valid_excluded_summary", "Figure M1. Valid and excluded day summary.");
[doc, rels, imageCounter] = addFigureByToken(doc, rels, imageCounter, MULTIDAY.Figures, cfg.paths.outputs.multiday.figures.png, ...
    "daily_net_operating_cost", "Figure M2. Daily net operating cost by regime.");
[doc, rels, imageCounter] = addFigureByToken(doc, rels, imageCounter, MULTIDAY.Figures, cfg.paths.outputs.multiday.figures.png, ...
    "cost_distribution", "Figure M3. Distribution of daily net operating cost.");
[doc, rels, imageCounter] = addFigureByToken(doc, rels, imageCounter, MULTIDAY.Figures, cfg.paths.outputs.multiday.figures.png, ...
    "daily_export_energy", "Figure M5. Daily export energy by regime.");
[doc, rels, imageCounter] = addFigureByToken(doc, rels, imageCounter, MULTIDAY.Figures, cfg.paths.outputs.multiday.figures.png, ...
    "daily_net_grid_energy", "Figure M6. Daily net grid energy by regime.");
doc(end+1) = heading("Table G. Multi-Day Operational Summary", 2);
doc(end+1) = wordTable(MULTIDAY.Tables.TableG_MultiDayOperationalSummary);
doc(end+1) = heading("Table H. Multi-Day Economic Summary", 2);
doc(end+1) = wordTable(MULTIDAY.Tables.TableH_MultiDayEconomicSummary);
doc(end+1) = heading("Table I. Robustness Comparison", 2);
doc(end+1) = wordTable(MULTIDAY.Tables.TableI_RobustnessComparison);

doc(end+1) = heading("Statistical Comparison", 1);
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "statistical_results_text"), "normal");
[doc, rels, imageCounter] = addFigureByToken(doc, rels, imageCounter, MULTIDAY.Figures, cfg.paths.outputs.multiday.figures.png, ...
    "v2g_benefit", "Figure M4. Daily V2G benefit relative to corrected V2H.");
[doc, rels, imageCounter] = addFigureByToken(doc, rels, imageCounter, MULTIDAY.Figures, cfg.paths.outputs.multiday.figures.png, ...
    "ev_throughput", "Figure M7. EV throughput and degradation-cost trade-off.");
[doc, rels, imageCounter] = addFigureByToken(doc, rels, imageCounter, MULTIDAY.Figures, cfg.paths.outputs.multiday.figures.png, ...
    "statistical_comparison", "Figure M9. Statistical comparison summary.");
doc(end+1) = heading("Table J. Statistical Paired Comparison", 2);
doc(end+1) = wordTable(MULTIDAY.Tables.TableJ_StatisticalPairedComparison);

doc(end+1) = heading("Tariff Sensitivity", 1);
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "tariff_sensitivity_text"), "normal");
doc(end+1) = heading("Table K. Tariff Sensitivity Summary", 2);
doc(end+1) = wordTable(MULTIDAY.Tables.TableK_TariffSensitivitySummary);

doc(end+1) = heading("Validation and Quality Control", 1);
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "validation_text"), "normal");
doc(end+1) = wordTable(MULTIDAY.ValidationSummary);
if isfield(MULTIDAY, 'QualityControl')
    doc(end+1) = heading("Quality-Control Checks", 2);
    doc(end+1) = wordTable(MULTIDAY.QualityControl);
end

doc(end+1) = heading("Paper-Ready Interpretation", 1);
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "economic_discussion_text"), "normal");
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "statistical_results_text"), "normal");
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "limitations_text"), "normal");

doc(end+1) = heading("Captions", 1);
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "figure_captions"), "normal");
doc(end+1) = paragraph(getText(MULTIDAY.GeneratedText, "table_captions"), "normal");

doc(end+1) = heading("Export Manifest", 1);
manifest = buildManifestTable(MULTIDAY, cfg, reportPath);
doc(end+1) = heading("Table L. Word Report Export Manifest", 2);
doc(end+1) = wordTable(manifest);

doc(end+1) = heading("Reproducibility Notes", 1);
doc(end+1) = paragraph("MATLAB version: " + string(version), "normal");
doc(end+1) = paragraph("Random seed: " + string(cfg.analysis.randomSeed), "normal");
doc(end+1) = paragraph("Date range/list: selected valid days are shown in Table C; excluded days are shown in Table B.", "normal");
doc(end+1) = paragraph("Configuration file: " + fullfile(cfg.paths.projectRoot, 'config', 'defaultConfig.m'), "normal");
doc(end+1) = paragraph("Complete multi-day MAT file: " + fullfile(cfg.paths.outputs.multiday.results, 'MULTIDAY_complete_results.mat'), "normal");

writePackage(tmpRoot, reportPath, doc, rels);
end

function [doc, rels, imageCounter] = addFigureSet(doc, rels, imageCounter, figures, imageDir, sectionTitle)
if isempty(figures)
    return
end
doc(end+1) = heading(sectionTitle, 2);
for k = 1:numel(figures)
    [doc, rels, imageCounter] = addFigure(doc, rels, imageCounter, figures(k), imageDir, figures(k).caption);
end
end

function [doc, rels, imageCounter] = addFigureByToken(doc, rels, imageCounter, figures, imageDir, token, captionPrefix)
if isempty(figures)
    return
end
idx = find(contains([figures.baseName], token), 1);
if isempty(idx)
    return
end
caption = captionPrefix + " " + string(figures(idx).caption);
[doc, rels, imageCounter] = addFigure(doc, rels, imageCounter, figures(idx), imageDir, caption);
end

function writePackage(tmpRoot, reportPath, docParts, relParts)
% Rebuild image references after document body is known.
mediaDir = fullfile(tmpRoot, 'word', 'media');
body = strings(0, 1);
rels = strings(0, 1);
imageId = 0;
for i = 1:numel(docParts)
    part = docParts(i);
    if startsWith(part, "__IMAGE__")
        tokens = split(part, "|");
        sourcePath = tokens(2);
        caption = tokens(3);
        if exist(sourcePath, 'file')
            imageId = imageId + 1;
            targetName = sprintf('image%d.png', imageId);
            copyfile(sourcePath, fullfile(mediaDir, targetName));
            rId = sprintf('rId%d', imageId);
            rels(end+1) = sprintf('<Relationship Id="%s" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/%s"/>', rId, targetName); %#ok<AGROW>
            body(end+1) = imageXml(rId, imageId); %#ok<AGROW>
            body(end+1) = paragraph(caption, "caption"); %#ok<AGROW>
        end
    else
        body(end+1) = part; %#ok<AGROW>
    end
end

writeUtf8(fullfile(tmpRoot, '[Content_Types].xml'), contentTypesXml());
writeUtf8(fullfile(tmpRoot, '_rels', '.rels'), packageRelsXml());
writeUtf8(fullfile(tmpRoot, 'word', '_rels', 'document.xml.rels'), documentRelsXml(rels));
writeUtf8(fullfile(tmpRoot, 'word', 'document.xml'), documentXml(body));

zipPath = [char(reportPath) '.zip'];
if exist(zipPath, 'file')
    delete(zipPath);
end
zip(zipPath, {'[Content_Types].xml', '_rels', 'word'}, tmpRoot);
movefile(zipPath, reportPath);
end

function [doc, rels, imageCounter] = addFigureOld(doc, rels, imageCounter, figInfo, imageDir, caption) %#ok<DEFNU>
% Kept for compatibility if older generated code calls this name.
[doc, rels, imageCounter] = addFigure(doc, rels, imageCounter, figInfo, imageDir, caption);
end

function [doc, rels, imageCounter] = addFigure(doc, rels, imageCounter, figInfo, imageDir, caption)
sourcePath = fullfile(imageDir, [char(figInfo.baseName) '.png']);
if exist(sourcePath, 'file')
    doc(end+1) = "__IMAGE__|" + string(sourcePath) + "|" + string(caption);
else
    doc(end+1) = paragraph("Figure image not found: " + string(sourcePath), "caption");
end
end

function xml = documentXml(body)
xml = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' newline ...
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" ' ...
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ' ...
    'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" ' ...
    'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" ' ...
    'xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">' newline ...
    '<w:body>' newline ...
    char(strjoin(body, newline)) newline ...
    '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/></w:sectPr>' newline ...
    '</w:body></w:document>'];
end

function xml = contentTypesXml()
xml = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' ...
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' ...
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' ...
    '<Default Extension="xml" ContentType="application/xml"/>' ...
    '<Default Extension="png" ContentType="image/png"/>' ...
    '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' ...
    '</Types>'];
end

function xml = packageRelsXml()
xml = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' ...
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' ...
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' ...
    '</Relationships>'];
end

function xml = documentRelsXml(rels)
xml = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' ...
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' ...
    char(strjoin(rels, '')) ...
    '</Relationships>'];
end

function xml = paragraph(text, style)
text = xmlEscape(joinString(text));
switch string(style)
    case "title"
        props = '<w:rPr><w:b/><w:sz w:val="36"/></w:rPr>';
        align = '<w:jc w:val="center"/>';
    case "subtitle"
        props = '<w:rPr><w:i/><w:sz w:val="24"/></w:rPr>';
        align = '<w:jc w:val="center"/>';
    case "caption"
        props = '<w:rPr><w:i/><w:sz w:val="18"/></w:rPr>';
        align = '';
    otherwise
        props = '<w:rPr><w:sz w:val="20"/></w:rPr>';
        align = '';
end
xml = sprintf('<w:p><w:pPr>%s</w:pPr><w:r>%s<w:t xml:space="preserve">%s</w:t></w:r></w:p>', align, props, text);
end

function xml = heading(text, level)
if level == 1
    size = 28;
else
    size = 23;
end
xml = sprintf('<w:p><w:pPr><w:spacing w:before="220" w:after="80"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="%d"/></w:rPr><w:t xml:space="preserve">%s</w:t></w:r></w:p>', ...
    size, xmlEscape(joinString(text)));
end

function xml = pageBreak()
xml = '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';
end

function xml = workflowTable()
steps = ["Configuration","Data screening","Valid-day selection","V2H-Old/V2H/V2G optimisation", ...
    "Validation","Metrics","Statistics","Figures/tables","Word report"];
T = table(steps(:), 'VariableNames', {'Workflow'});
xml = wordTable(T);
end

function xml = wordTable(T)
if ~istable(T) || width(T) == 0
    xml = paragraph("No table data available.", "caption");
    return
end
headers = string(T.Properties.VariableNames);
rows = strings(0, 1);
cellWidth = max(650, floor(10000/max(1, width(T))));
if width(T) > 7
    fontSize = 12;
else
    fontSize = 15;
end
rows(end+1) = tableRow(headers, true, cellWidth, fontSize);
for i = 1:height(T)
    values = strings(1, width(T));
    for j = 1:width(T)
        values(j) = valueToString(T{i,j});
    end
    rows(end+1) = tableRow(values, false, cellWidth, fontSize); %#ok<AGROW>
end
xml = ['<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders>' ...
    '<w:top w:val="single" w:sz="4"/><w:left w:val="single" w:sz="4"/>' ...
    '<w:bottom w:val="single" w:sz="4"/><w:right w:val="single" w:sz="4"/>' ...
    '<w:insideH w:val="single" w:sz="4"/><w:insideV w:val="single" w:sz="4"/>' ...
    '</w:tblBorders></w:tblPr>' char(strjoin(rows, '')) '</w:tbl>'];
end

function xml = tableRow(values, isHeader, cellWidth, fontSize)
cells = strings(1, numel(values));
for k = 1:numel(values)
    text = xmlEscape(values(k));
    if isHeader
        runProps = sprintf('<w:rPr><w:b/><w:sz w:val="%d"/></w:rPr>', fontSize);
    else
        runProps = sprintf('<w:rPr><w:sz w:val="%d"/></w:rPr>', fontSize);
    end
    cells(k) = sprintf('<w:tc><w:tcPr><w:tcW w:w="%d" w:type="dxa"/><w:tcMar><w:top w:w="60" w:type="dxa"/><w:left w:w="60" w:type="dxa"/><w:bottom w:w="60" w:type="dxa"/><w:right w:w="60" w:type="dxa"/></w:tcMar></w:tcPr><w:p><w:r>%s<w:t xml:space="preserve">%s</w:t></w:r></w:p></w:tc>', ...
        cellWidth, runProps, text);
end
xml = '<w:tr>' + strjoin(cells, '') + '</w:tr>';
end

function xml = imageXml(rId, imageId)
cx = 914400*6.2;
cy = 914400*3.6;
xml = sprintf(['<w:p><w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0">' ...
    '<wp:extent cx="%.0f" cy="%.0f"/><wp:docPr id="%d" name="Figure%d"/>' ...
    '<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">' ...
    '<pic:pic><pic:nvPicPr><pic:cNvPr id="%d" name="Figure%d.png"/><pic:cNvPicPr/></pic:nvPicPr>' ...
    '<pic:blipFill><a:blip r:embed="%s"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>' ...
    '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="%.0f" cy="%.0f"/></a:xfrm>' ...
    '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic>' ...
    '</a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>'], ...
    cx, cy, imageId, imageId, imageId, imageId, rId, cx, cy);
end

function T = tableOrEmpty(S, fieldName)
if isstruct(S) && isfield(S, fieldName) && istable(S.(fieldName))
    T = S.(fieldName);
else
    T = table("not available", 'VariableNames', {'Status'});
end
end

function text = getText(S, fieldName)
if isstruct(S) && isfield(S, fieldName)
    text = string(S.(fieldName));
else
    text = "Text section not available.";
end
end

function text = getSingleDayText(TEXT, fieldName)
if isstruct(TEXT) && isfield(TEXT, fieldName)
    value = TEXT.(fieldName);
    if isstruct(value)
        parts = strings(0, 1);
        names = string(fieldnames(value));
        for k = 1:numel(names)
            parts(end+1) = string(value.(names(k))); %#ok<AGROW>
        end
        text = strjoin(parts, newline);
    else
        text = string(value);
    end
else
    text = "Single-day text was not generated in this run.";
end
end

function manifest = buildManifestTable(MULTIDAY, cfg, reportPath)
figCount = 0;
tableCount = 0;
textCount = 0;
if isfield(MULTIDAY, 'Export')
    if isfield(MULTIDAY.Export, 'Figures') && istable(MULTIDAY.Export.Figures)
        figCount = height(MULTIDAY.Export.Figures);
    end
    if isfield(MULTIDAY.Export, 'Tables') && istable(MULTIDAY.Export.Tables)
        tableCount = height(MULTIDAY.Export.Tables);
    end
    if isfield(MULTIDAY.Export, 'Text') && istable(MULTIDAY.Export.Text)
        textCount = height(MULTIDAY.Export.Text);
    end
end
Item = [
    "figures exported";
    "tables exported";
    "text sections exported";
    "MAT files saved";
    "logs saved";
    "Word report"
    ];
Value = [
    string(figCount)
    string(tableCount)
    string(textCount)
    fullfile(cfg.paths.outputs.multiday.results, 'MULTIDAY_complete_results.mat')
    fullfile(cfg.paths.outputs.multiday.logs, 'MULTIDAY_run_log.txt')
    string(reportPath)
    ];
manifest = table(Item, Value);
end

function s = valueToString(v)
if iscell(v)
    v = v{1};
end
if isnumeric(v)
    if isempty(v)
        s = "";
    elseif isscalar(v)
        if isnan(v)
            s = "NaN";
        else
            s = string(compose('%.6g', v));
        end
    else
        s = "[" + strjoin(compose('%.6g', v(:).'), ", ") + "]";
    end
elseif islogical(v)
    s = string(v);
elseif isdatetime(v)
    s = string(v);
else
    s = string(v);
end
end

function s = joinString(x)
x = string(x);
if numel(x) > 1
    s = strjoin(x(:), newline);
else
    s = x;
end
end

function s = xmlEscape(s)
s = string(s);
s = replace(s, "&", "&amp;");
s = replace(s, "<", "&lt;");
s = replace(s, ">", "&gt;");
s = replace(s, """", "&quot;");
s = replace(s, "'", "&apos;");
end

function writeUtf8(path, txt)
fid = fopen(path, 'w', 'n', 'UTF-8');
if fid < 0
    error('Could not open %s for writing.', path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', txt);
end

function removeTempDir(path)
if exist(path, 'dir')
    try
        rmdir(path, 's');
    catch
    end
end
end
