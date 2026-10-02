function status = exportWordReport(RESULTS, TABLES, TEXT, FIGURES, EXPORT, TESTS, cfg)
%EXPORTWORDREPORT Create one complete Word document for all P3 outputs.
%
% The exporter writes a DOCX directly with OpenXML so the project does not
% depend on MATLAB Report Generator. The document contains the workflow
% diagram, solver summary, generated text, all figures, all paper tables,
% validation/evaluation tables, and an output manifest.

docxFile = fullfile(cfg.paths.outputs.word, 'P3_full_results_report.docx');
status = table(string(docxFile), false, "", ...
    'VariableNames', {'FileName', 'SavedDOCX', 'Message'});

try
    if exist(docxFile, 'file')
        delete(docxFile);
    end

    tempRoot = tempname(cfg.paths.outputs.word);
    mkdir(tempRoot);
    mkdir(fullfile(tempRoot, '_rels'));
    mkdir(fullfile(tempRoot, 'word'));
    mkdir(fullfile(tempRoot, 'word', '_rels'));
    mkdir(fullfile(tempRoot, 'word', 'media'));
    cleanupTemp = onCleanup(@() localRemoveFolder(tempRoot));

    imageRels = strings(0, 1);
    body = strings(0, 1);

    body(end+1) = paragraph(cfg.project.paperTitle, "title");
    body(end+1) = paragraph("Complete MATLAB Results Report", "subtitle");
    body(end+1) = paragraph("Generated: " + string(datetime('now')), "meta");
    body(end+1) = paragraph("Project root: " + string(cfg.paths.projectRoot), "meta");
    body(end+1) = paragraph("This Word document is generated automatically by run_P3_all.m and collects the optimisation results, figures, tables, explanations, evaluations, and workflow diagrams needed to support P3.", "body");

    body(end+1) = paragraph("1. Executive Run Summary", "h1");
    body(end+1) = paragraph(buildRunSummaryText(RESULTS, cfg), "body");
    body(end+1) = tableXml(buildSolverSummaryTable(RESULTS, cfg));

    body(end+1) = paragraph("2. Project Workflow Diagram", "h1");
    body(end+1) = paragraph("The workflow below shows how the reproducible P3 code converts the case-study inputs into optimisation outputs, validation evidence, paper tables, figures, generated text, and the final Word report.", "body");
    body(end+1) = flowDiagramXml();

    body(end+1) = paragraph("3. Regime Design and Economic Interpretation", "h1");
    body(end+1) = tableXml(buildRegimeTable());
    body(end+1) = paragraph("Cost sign convention", "h2");
    body(end+1) = paragraph(TEXT.Results.sign_convention, "body");
    body(end+1) = paragraph(TEXT.Results.unit_note, "body");

    body(end+1) = paragraph("4. Generated Results Text", "h1");
    body = appendStructText(body, TEXT.Results, "Results");

    body(end+1) = paragraph("5. Generated Discussion and Evaluation Text", "h1");
    body = appendStructText(body, TEXT.Discussion, "Discussion");

    body(end+1) = paragraph("6. Figures and Diagrams", "h1");
    for k = 1:numel(FIGURES)
        baseName = string(FIGURES(k).baseName);
        pngFile = fullfile(cfg.paths.outputs.figures.png, baseName + ".png");
        if exist(pngFile, 'file')
            body(end+1) = pageBreak();
            [imageXml, relXml] = imageParagraphXml(pngFile, "rId" + string(numel(imageRels) + 1), baseName, tempRoot);
            imageRels(end+1) = relXml; %#ok<AGROW>
            body(end+1) = imageXml;
            body(end+1) = paragraph("Figure " + string(k) + ". " + string(FIGURES(k).caption), "caption");
        else
            body(end+1) = paragraph("Missing figure PNG: " + string(pngFile), "warning");
        end
    end

    body(end+1) = paragraph("7. Paper Tables", "h1");
    body = appendNamedTable(body, TABLES, "Operational", "Table I. Operational comparison.");
    body = appendNamedTable(body, TABLES, "Economic", "Table II. Economic comparison.");
    body = appendNamedTable(body, TABLES, "Validation", "Table III. Validation comparison.");
    body = appendNamedTable(body, TABLES, "TariffSensitivity", "Table IV. Tariff sensitivity.");
    body = appendNamedTable(body, TABLES, "CombinedMetrics", "Combined operational and economic metrics.");

    body(end+1) = paragraph("8. Captions", "h1");
    body(end+1) = paragraph("Figure captions", "h2");
    body(end+1) = tableXml(TEXT.FigureCaptions);
    body(end+1) = paragraph("Table captions", "h2");
    body(end+1) = tableXml(TEXT.TableCaptions);

    body(end+1) = paragraph("9. Validation and Sanity Evaluations", "h1");
    testNames = string(fieldnames(TESTS));
    for k = 1:numel(testNames)
        body(end+1) = paragraph(testNames(k), "h2"); %#ok<AGROW>
        body(end+1) = tableXml(TESTS.(testNames(k))); %#ok<AGROW>
    end

    body(end+1) = paragraph("10. Export Manifest", "h1");
    body(end+1) = paragraph("The following export status tables document the reproducibility artifacts created by the run.", "body");
    body(end+1) = paragraph("Figure export status", "h2");
    body(end+1) = tableXml(EXPORT.Figures);
    body(end+1) = paragraph("Table export status", "h2");
    body(end+1) = tableXml(EXPORT.Tables);
    body(end+1) = paragraph("Text export status", "h2");
    body(end+1) = tableXml(EXPORT.Text);

    documentXml = makeDocumentXml(strjoin(body, newline));
    writeText(fullfile(tempRoot, 'word', 'document.xml'), documentXml);
    writeText(fullfile(tempRoot, '_rels', '.rels'), rootRelsXml());
    writeText(fullfile(tempRoot, 'word', '_rels', 'document.xml.rels'), documentRelsXml(imageRels));
    writeText(fullfile(tempRoot, '[Content_Types].xml'), contentTypesXml());

    zipFile = fullfile(tempRoot, 'P3_full_results_report.zip');
    currentFolder = pwd;
    cd(tempRoot);
    cleanupCd = onCleanup(@() cd(currentFolder));
    zip(zipFile, {'[Content_Types].xml', '_rels', 'word'});
    clear cleanupCd
    movefile(zipFile, docxFile, 'f');

    status.SavedDOCX(1) = true;
catch ME
    status.Message(1) = string(getReport(ME, 'extended', 'hyperlinks', 'off'));
end
end

function text = buildRunSummaryText(RESULTS, cfg)
text = sprintf(['The P3 workflow solved %s, %s, and %s with solver statuses %s, %s, and %s. ', ...
    'The daily net operating costs are %.4f, %.4f, and %.4f GBP/day. ', ...
    'The report therefore presents the restrictive V2H-Old baseline, the corrected household-centred V2H case, and the export-enabled V2G case in one consistent economic narrative.'], ...
    cfg.project.regimeLabels(1), cfg.project.regimeLabels(2), cfg.project.regimeLabels(3), ...
    RESULTS.V2HOld.solver.status, RESULTS.V2H.solver.status, RESULTS.V2G.solver.status, ...
    RESULTS.V2HOld.cost.total, RESULTS.V2H.cost.total, RESULTS.V2G.cost.total);
end

function T = buildSolverSummaryTable(RESULTS, cfg)
regimes = cfg.project.regimeOrder;
labels = cfg.project.regimeLabels;
SolverStatus = strings(numel(regimes), 1);
Objective = zeros(numel(regimes), 1);
ImportCost_GBP_per_day = zeros(numel(regimes), 1);
ExportRevenue_GBP_per_day = zeros(numel(regimes), 1);
NetCost_GBP_per_day = zeros(numel(regimes), 1);
for k = 1:numel(regimes)
    R = RESULTS.(regimes(k));
    SolverStatus(k) = string(R.solver.status);
    Objective(k) = R.solver.objective;
    ImportCost_GBP_per_day(k) = R.cost.import;
    ExportRevenue_GBP_per_day(k) = R.cost.exportRevenue;
    NetCost_GBP_per_day(k) = R.cost.total;
end
T = table(labels(:), SolverStatus, Objective, ImportCost_GBP_per_day, ...
    ExportRevenue_GBP_per_day, NetCost_GBP_per_day, ...
    'VariableNames', {'Regime', 'SolverStatus', 'Objective', ...
    'ImportCost_GBP_per_day', 'ExportRevenue_GBP_per_day', 'NetCost_GBP_per_day'});
end

function T = buildRegimeTable()
Regime = ["V2H-Old"; "V2H"; "V2G"];
RoleInP3 = [
    "Restrictive legacy baseline"
    "Physically corrected household-centred case"
    "Export-enabled market-aware case"
    ];
EconomicMeaning = [
    "Shows the cost of the restrictive baseline before export value is introduced"
    "Shows how corrected V2H changes import, export, EV dispatch, and cost"
    "Shows how export revenue changes grid exchange and net operating cost"
    ];
ExportLogic = [
    "Grid export disabled"
    "Export allowed only from household surplus; EV-to-grid export blocked"
    "Export enabled with EV-supported V2G operation"
    ];
T = table(Regime, RoleInP3, EconomicMeaning, ExportLogic);
end

function body = appendStructText(body, S, prefix)
names = string(fieldnames(S));
for k = 1:numel(names)
    value = S.(names(k));
    if istable(value)
        body(end+1) = paragraph(prefix + " - " + names(k), "h2"); %#ok<AGROW>
        body(end+1) = tableXml(value); %#ok<AGROW>
    else
        body(end+1) = paragraph(prettyLabel(names(k)), "h2"); %#ok<AGROW>
        body(end+1) = paragraph(string(value), "body"); %#ok<AGROW>
    end
end
end

function body = appendNamedTable(body, TABLES, name, caption)
if isfield(TABLES, name)
    body(end+1) = paragraph(caption, "caption");
    body(end+1) = tableXml(TABLES.(name));
end
end

function label = prettyLabel(name)
label = replace(string(name), "_", " ");
end

function xml = makeDocumentXml(bodyXml)
sectPr = ['<w:sectPr>' ...
    '<w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/>' ...
    '<w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="360" w:footer="360" w:gutter="0"/>' ...
    '</w:sectPr>'];
xml = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' ...
    '<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" ' ...
    'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" ' ...
    'xmlns:o="urn:schemas-microsoft-com:office:office" ' ...
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ' ...
    'xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" ' ...
    'xmlns:v="urn:schemas-microsoft-com:vml" ' ...
    'xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" ' ...
    'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" ' ...
    'xmlns:w10="urn:schemas-microsoft-com:office:word" ' ...
    'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" ' ...
    'xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" ' ...
    'xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" ' ...
    'xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk" ' ...
    'xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" ' ...
    'xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" ' ...
    'mc:Ignorable="w14 wp14"><w:body>' bodyXml sectPr '</w:body></w:document>'];
end

function xml = paragraph(text, style)
text = string(text);
style = string(style);
switch style
    case "title"
        pPr = '<w:pPr><w:jc w:val="center"/><w:spacing w:after="220"/></w:pPr>';
        rPr = runProps(32, true, false, '1F4E79');
    case "subtitle"
        pPr = '<w:pPr><w:jc w:val="center"/><w:spacing w:after="180"/></w:pPr>';
        rPr = runProps(22, false, false, '4F6272');
    case "meta"
        pPr = '<w:pPr><w:jc w:val="center"/><w:spacing w:after="80"/></w:pPr>';
        rPr = runProps(18, false, false, '5D6670');
    case "h1"
        pPr = '<w:pPr><w:spacing w:before="280" w:after="120"/><w:outlineLvl w:val="0"/></w:pPr>';
        rPr = runProps(24, true, false, '1F4E79');
    case "h2"
        pPr = '<w:pPr><w:spacing w:before="180" w:after="80"/><w:outlineLvl w:val="1"/></w:pPr>';
        rPr = runProps(19, true, false, '2D3740');
    case "caption"
        pPr = '<w:pPr><w:spacing w:before="120" w:after="60"/></w:pPr>';
        rPr = runProps(17, false, true, '4F6272');
    case "warning"
        pPr = '<w:pPr><w:spacing w:after="100"/></w:pPr>';
        rPr = runProps(18, true, false, 'B00020');
    otherwise
        pPr = '<w:pPr><w:spacing w:after="110" w:line="276" w:lineRule="auto"/></w:pPr>';
        rPr = runProps(19, false, false, '000000');
end
xml = "<w:p>" + string(pPr) + "<w:r>" + string(rPr) + textRuns(text) + "</w:r></w:p>";
end

function xml = pageBreak()
xml = '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';
end

function xml = textRuns(text)
parts = splitlines(string(text));
xmlParts = strings(numel(parts), 1);
for i = 1:numel(parts)
    xmlParts(i) = "<w:t xml:space=""preserve"">" + escapeXml(parts(i)) + "</w:t>";
    if i < numel(parts)
        xmlParts(i) = xmlParts(i) + "<w:br/>";
    end
end
xml = strjoin(xmlParts, '');
end

function xml = runProps(sizeHalfPt, bold, italic, color)
xml = "<w:rPr><w:rFonts w:ascii=""Times New Roman"" w:hAnsi=""Times New Roman"" w:cs=""Times New Roman""/>";
xml = xml + "<w:color w:val=""" + string(color) + """/><w:sz w:val=""" + string(sizeHalfPt) + """/><w:szCs w:val=""" + string(sizeHalfPt) + """/>";
if bold
    xml = xml + "<w:b/><w:bCs/>";
end
if italic
    xml = xml + "<w:i/><w:iCs/>";
end
xml = xml + "</w:rPr>";
end

function xml = tableXml(T)
if ~istable(T)
    xml = paragraph("No table data available.", "warning");
    return
end

headers = string(T.Properties.VariableNames);
rows = strings(0, 1);
rows(end+1) = "<w:tbl><w:tblPr><w:tblW w:w=""5000"" w:type=""pct""/><w:tblLayout w:type=""autofit""/>" + ...
    "<w:tblBorders><w:top w:val=""single"" w:sz=""6"" w:color=""A6B3C2""/>" + ...
    "<w:left w:val=""single"" w:sz=""6"" w:color=""A6B3C2""/>" + ...
    "<w:bottom w:val=""single"" w:sz=""6"" w:color=""A6B3C2""/>" + ...
    "<w:right w:val=""single"" w:sz=""6"" w:color=""A6B3C2""/>" + ...
    "<w:insideH w:val=""single"" w:sz=""4"" w:color=""D7DEE8""/>" + ...
    "<w:insideV w:val=""single"" w:sz=""4"" w:color=""D7DEE8""/></w:tblBorders>" + ...
    "<w:tblCellMar><w:top w:w=""80"" w:type=""dxa""/><w:left w:w=""80"" w:type=""dxa""/><w:bottom w:w=""80"" w:type=""dxa""/><w:right w:w=""80"" w:type=""dxa""/></w:tblCellMar>" + ...
    "</w:tblPr>";

rows(end+1) = tableRowXml(headers, true);
for i = 1:height(T)
    vals = strings(1, width(T));
    for j = 1:width(T)
        vals(j) = valueToString(T{i, j});
    end
    rows(end+1) = tableRowXml(vals, false); %#ok<AGROW>
end
rows(end+1) = '</w:tbl>';
xml = strjoin(rows, newline);
end

function xml = tableRowXml(values, isHeader)
cells = strings(1, numel(values));
for j = 1:numel(values)
    if isHeader
        shade = '<w:shd w:fill="EAF0F6"/>';
        rPr = runProps(16, true, false, '1F4E79');
    else
        shade = '';
        rPr = runProps(15, false, false, '000000');
    end
    cellText = escapeXml(values(j));
    cells(j) = ['<w:tc><w:tcPr><w:tcW w:w="0" w:type="auto"/><w:vAlign w:val="center"/>' shade '</w:tcPr>' ...
        '<w:p><w:pPr><w:spacing w:after="0"/></w:pPr><w:r>' char(rPr) '<w:t xml:space="preserve">' char(cellText) '</w:t></w:r></w:p></w:tc>'];
end
if isHeader
    rowPr = '<w:trPr><w:tblHeader/></w:trPr>';
else
    rowPr = '';
end
xml = ['<w:tr>' rowPr char(strjoin(cells, '')) '</w:tr>'];
end

function xml = flowDiagramXml()
steps = ["Configuration"; "Input data"; "Three-regime optimisation"; "Validation"; "Metrics"; "Figures and tables"; "Word report"];
arrows = repmat("->", numel(steps)-1, 1);
T = table(steps(1), arrows(1), steps(2), arrows(2), steps(3), arrows(3), steps(4), ...
    'VariableNames', {'Step1', 'Arrow1', 'Step2', 'Arrow2', 'Step3', 'Arrow3', 'Step4'});
T2 = table(steps(4), arrows(4), steps(5), arrows(5), steps(6), arrows(6), steps(7), ...
    'VariableNames', {'Step4', 'Arrow4', 'Step5', 'Arrow5', 'Step6', 'Arrow6', 'Step7'});
xml = tableXml(T) + paragraph("", "body") + tableXml(T2);
end

function [xml, relXml] = imageParagraphXml(pngFile, relId, baseName, tempRoot)
mediaName = "image" + extractAfter(relId, "rId") + ".png";
targetMediaFile = fullfile(tempRoot, 'word', 'media', mediaName);
copyfile(pngFile, targetMediaFile);

info = imfinfo(pngFile);
maxWidthEmu = round(8.4 * 914400);
cx = maxWidthEmu;
cy = round(cx * info.Height / info.Width);
maxHeightEmu = round(5.4 * 914400);
if cy > maxHeightEmu
    cy = maxHeightEmu;
    cx = round(cy * info.Width / info.Height);
end

nameEsc = escapeXml(baseName);
xml = ['<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:after="120"/></w:pPr><w:r><w:drawing>' ...
    '<wp:inline distT="0" distB="0" distL="0" distR="0">' ...
    '<wp:extent cx="' num2str(cx) '" cy="' num2str(cy) '"/>' ...
    '<wp:effectExtent l="0" t="0" r="0" b="0"/>' ...
    '<wp:docPr id="' char(extractAfter(relId, "rId")) '" name="' char(nameEsc) '"/>' ...
    '<wp:cNvGraphicFramePr><a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/></wp:cNvGraphicFramePr>' ...
    '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">' ...
    '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">' ...
    '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">' ...
    '<pic:nvPicPr><pic:cNvPr id="0" name="' char(nameEsc) '"/><pic:cNvPicPr/></pic:nvPicPr>' ...
    '<pic:blipFill><a:blip r:embed="' char(relId) '"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>' ...
    '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="' num2str(cx) '" cy="' num2str(cy) '"/></a:xfrm>' ...
    '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>' ...
    '</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>'];
relXml = "<Relationship Id=""" + relId + """ Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"" Target=""media/" + mediaName + """/>";
end

function xml = rootRelsXml()
xml = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' ...
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' ...
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' ...
    '</Relationships>'];
end

function xml = documentRelsXml(imageRels)
xml = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' ...
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' ...
    char(strjoin(imageRels, '')) ...
    '</Relationships>'];
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

function s = valueToString(v)
if isnumeric(v)
    if isscalar(v)
        s = string(compose('%.6g', v));
    else
        s = strjoin(string(compose('%.6g', v(:).')), ", ");
    end
elseif islogical(v)
    if isscalar(v)
        s = string(v);
    else
        s = strjoin(string(v(:).'), ", ");
    end
elseif iscell(v)
    if isempty(v)
        s = "";
    else
        s = valueToString(v{1});
    end
else
    s = string(v);
end
end

function txt = escapeXml(txt)
txt = string(txt);
txt = replace(txt, "&", "&amp;");
txt = replace(txt, "<", "&lt;");
txt = replace(txt, ">", "&gt;");
txt = replace(txt, """", "&quot;");
txt = replace(txt, "'", "&apos;");
end

function writeText(fileName, txt)
fid = fopen(fileName, 'w');
if fid < 0
    error('Could not open %s for writing.', fileName);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', txt);
end

function localRemoveFolder(folderName)
if exist(folderName, 'dir')
    rmdir(folderName, 's');
end
end
