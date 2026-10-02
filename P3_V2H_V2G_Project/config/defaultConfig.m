function cfg = defaultConfig()
%DEFAULTCONFIG Define paper-specific defaults for the P3 workflow.

cfg = struct();

cfg.project.name = "P3_V2H_V2G_Project";
cfg.project.paperTitle = "Economic Impact of Export Revenue in Residential Vehicle-to-Home and Vehicle-to-Grid Energy Optimisation";
cfg.project.regimeOrder = ["V2HOld", "V2H", "V2G"];
cfg.project.regimeLabels = ["V2H-Old", "V2H", "V2G"];

cfg.Dt = 10/60;
cfg.Tend = 24;
cfg.DPoints = round(cfg.Tend/cfg.Dt);
cfg.case.date = 43598;
cfg.case.houseId = 1;

cfg.analysis.mode = "both";                 % "singleDay", "multiDay", or "both"
cfg.analysis.singleDate = 43598;
cfg.analysis.dateRange = [];
cfg.analysis.dateList = [];                  % Prepared DayNum identifiers (not Excel serial dates) when method = "manual"
cfg.analysis.maxValidDays = 30;              % Use 7, 14, 21, 30, 60, or Inf
cfg.analysis.maxDays = cfg.analysis.maxValidDays; % Backwards-compatible alias
cfg.analysis.runAllValidDays = false;
cfg.analysis.excludeMissingDays = true;
cfg.analysis.minSamplesPerDay = cfg.DPoints;
cfg.analysis.allowPartialDays = false;
cfg.analysis.representativeDayMethod = "validSequential"; % "validSequential", "manual", "random", "extreme", or "cluster"
cfg.analysis.requireEVData = true;
cfg.analysis.requireSOCData = true;
cfg.analysis.skipFailedSolverDays = true;
cfg.analysis.includeFailedDaysInSummary = false;
cfg.analysis.includeFailedDays = false;      % Backwards-compatible alias
cfg.analysis.generateWordReport = true;
cfg.analysis.wordReportName = "P3_MultiDay_IEEE_Results_Report.docx";
cfg.analysis.significanceAlpha = 0.05;
cfg.analysis.annualise = false;
cfg.analysis.randomSeed = 1;
cfg.analysis.runTariffSensitivity = true;

cfg.tariff.import.offPeak = 4.99/100;
cfg.tariff.import.midPeak = 11.99/100;
cfg.tariff.import.peak = 24.99/100;
cfg.tariff.export.base = 3.79/100;
cfg.tariff.unit = "GBP/kWh";
cfg.tariff.costUnitDaily = "GBP/day";
cfg.tariff.costUnitAnnual = "GBP/year";
cfg.tariff.sensitivityCases = table( ...
    ["Low"; "Medium"; "High"], ...
    [0.08; 0.12; 0.18], ...
    [0.02; 0.05; 0.10], ...
    'VariableNames', {'TariffCase', 'ImportTariff_GBP_per_kWh', 'ExportTariff_GBP_per_kWh'});
cfg.tariff.exportSweep = linspace(0, 0.15, 16).';
cfg.tariff.reoptimiseSensitivity = false;

cfg.grid.Pmax = 500;
cfg.grid.Pmin = -500;

cfg.soc.min = 20;
cfg.soc.max = 95;

cfg.battery.price = 2600;
cfg.battery.capacity = 4;
cfg.battery.Pmax = 2.7;
cfg.battery.etaConverter = 0.95;
cfg.battery.etaCharge = 0.95;
cfg.battery.etaDischarge = 0.95;
cfg.battery.cycleLife = 5000;
cfg.battery.socStartPct = 90;

cfg.ev.price = 4400;
cfg.ev.capacity = 40;
cfg.ev.Pmax = 6.6;
cfg.ev.consumption = 0.28;
cfg.ev.eta = 0.90;
cfg.ev.soc.min = 10;
cfg.ev.soc.max = 100;
cfg.ev.socStartPct = 65;
cfg.ev.desiredBeforeFirstTripPct = 90;
cfg.ev.cycleLife = 5000;

cfg.appliances.dishwasher.power = 1.2;
cfg.appliances.dishwasher.startHour = 5;
cfg.appliances.dishwasher.waitHours = 5;
cfg.appliances.washingMachine.power = 0;
cfg.appliances.washingMachine.startHour = 19;
cfg.appliances.washingMachine.waitHours = 5;

cfg.optimization.solver = "gurobi";
cfg.optimization.minSwitchPower = 0.01;
cfg.optimization.powerBalanceTolerance = 1e-4;
cfg.optimization.boundTolerance = 1e-6;
cfg.optimization.useCachedIfSolverUnavailable = false;

cfg.validation.tolerance = 1e-4;
cfg.validation.correctedRegimes = ["V2H", "V2G"];
cfg.validation.costReconstructionTolerance = 1e-6;

cfg.figure.fontName = "Times New Roman";
cfg.figure.fontSize = 9;
cfg.figure.labelFontSize = 10;
cfg.figure.lineWidth = 1.3;
cfg.figure.singleColumnWidthCm = 8.8;
cfg.figure.doubleColumnWidthCm = 18.0;
cfg.figure.dpi = 300;
cfg.figure.includeOptional = false;

cfg.export.saveFig = true;
cfg.export.savePng = true;
cfg.export.saveEps = true;
cfg.export.savePdf = true;

cfg.paths = struct();
end
