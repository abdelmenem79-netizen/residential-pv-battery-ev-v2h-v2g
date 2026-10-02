function cfg = buildConfig(cfg, projectRoot)
%BUILDCONFIG Attach project-relative paths and create output folders.

cfg.paths.projectRoot = projectRoot;
cfg.paths.config = fullfile(projectRoot, 'config');
cfg.paths.data.root = fullfile(projectRoot, 'data');
cfg.paths.data.raw = fullfile(cfg.paths.data.root, 'raw');
cfg.paths.data.processed = fullfile(cfg.paths.data.root, 'processed');
cfg.paths.data.results = fullfile(cfg.paths.data.root, 'results');

cfg.paths.data.rawHouseData = fullfile(cfg.paths.data.raw, 'Total_Data_house1.xlsx');
cfg.paths.data.processedHouseData = fullfile(cfg.paths.data.processed, 'House1_data_Struct.mat');
cfg.paths.data.socBattery = fullfile(cfg.paths.data.processed, 'SOCFinal.xlsx');
cfg.paths.data.socEV = fullfile(cfg.paths.data.processed, 'SOCFinalEV.xlsx');

cfg.paths.outputs.root = fullfile(projectRoot, 'outputs');
cfg.paths.outputs.figures.root = fullfile(cfg.paths.outputs.root, 'figures');
cfg.paths.outputs.figures.fig = fullfile(cfg.paths.outputs.figures.root, 'fig');
cfg.paths.outputs.figures.png = fullfile(cfg.paths.outputs.figures.root, 'png');
cfg.paths.outputs.figures.eps = fullfile(cfg.paths.outputs.figures.root, 'eps');
cfg.paths.outputs.figures.pdf = fullfile(cfg.paths.outputs.figures.root, 'pdf');
cfg.paths.outputs.tables = fullfile(cfg.paths.outputs.root, 'tables');
cfg.paths.outputs.text = fullfile(cfg.paths.outputs.root, 'text');
cfg.paths.outputs.word = fullfile(cfg.paths.outputs.root, 'word');
cfg.paths.outputs.logs = fullfile(cfg.paths.outputs.root, 'logs');
cfg.paths.outputs.results = fullfile(cfg.paths.outputs.root, 'results');
cfg.paths.revisionRuntimeVerification = fullfile(fileparts(projectRoot), 'revision_runtime_verification_outputs');
cfg.paths.outputs.multiday.root = fullfile(cfg.paths.outputs.root, 'multiday');
cfg.paths.outputs.multiday.tables = fullfile(cfg.paths.outputs.multiday.root, 'tables');
cfg.paths.outputs.multiday.text = fullfile(cfg.paths.outputs.multiday.root, 'text');
cfg.paths.outputs.multiday.reports = fullfile(cfg.paths.outputs.multiday.root, 'reports');
cfg.paths.outputs.multiday.results = fullfile(cfg.paths.outputs.multiday.root, 'results');
cfg.paths.outputs.multiday.logs = fullfile(cfg.paths.outputs.multiday.root, 'logs');
cfg.paths.outputs.multiday.diagnostics = fullfile(cfg.paths.outputs.multiday.root, 'diagnostics');
cfg.paths.outputs.multiday.figures.root = fullfile(cfg.paths.outputs.multiday.root, 'figures');
cfg.paths.outputs.multiday.figures.fig = fullfile(cfg.paths.outputs.multiday.figures.root, 'fig');
cfg.paths.outputs.multiday.figures.png = fullfile(cfg.paths.outputs.multiday.figures.root, 'png');
cfg.paths.outputs.multiday.figures.eps = fullfile(cfg.paths.outputs.multiday.figures.root, 'eps');
cfg.paths.outputs.multiday.figures.pdf = fullfile(cfg.paths.outputs.multiday.figures.root, 'pdf');

folders = [
    string(cfg.paths.data.raw)
    string(cfg.paths.data.processed)
    string(cfg.paths.data.results)
    string(cfg.paths.outputs.figures.fig)
    string(cfg.paths.outputs.figures.png)
    string(cfg.paths.outputs.figures.eps)
    string(cfg.paths.outputs.figures.pdf)
    string(cfg.paths.outputs.tables)
    string(cfg.paths.outputs.text)
    string(cfg.paths.outputs.word)
    string(cfg.paths.outputs.logs)
    string(cfg.paths.outputs.results)
    string(cfg.paths.revisionRuntimeVerification)
    string(cfg.paths.outputs.multiday.tables)
    string(cfg.paths.outputs.multiday.text)
    string(cfg.paths.outputs.multiday.reports)
    string(cfg.paths.outputs.multiday.results)
    string(cfg.paths.outputs.multiday.logs)
    string(cfg.paths.outputs.multiday.diagnostics)
    string(cfg.paths.outputs.multiday.figures.fig)
    string(cfg.paths.outputs.multiday.figures.png)
    string(cfg.paths.outputs.multiday.figures.eps)
    string(cfg.paths.outputs.multiday.figures.pdf)
    ];

for k = 1:numel(folders)
    folder = char(folders(k));
    if ~exist(folder, 'dir')
        mkdir(folder);
    end
end
end
