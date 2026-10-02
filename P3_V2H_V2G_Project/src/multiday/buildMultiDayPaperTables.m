function Tables = buildMultiDayPaperTables(MULTIDAY, cfg)
%BUILDMULTIDAYPAPERTABLES Build Word/IEEE-ready multi-day tables.

Tables = struct();
Tables.TableA_DataScreeningSummary = buildTableA(MULTIDAY);
Tables.TableB_ExcludedDaysLog = MULTIDAY.Screening.ExcludedDays;
Tables.TableC_ValidDaysClassification = buildTableC(MULTIDAY.SelectedDays);
Tables.TableG_MultiDayOperationalSummary = buildTableG(MULTIDAY.SummaryMetrics, MULTIDAY.DailyMetrics, cfg);
Tables.TableH_MultiDayEconomicSummary = buildTableH(MULTIDAY.SummaryMetrics, cfg);
Tables.TableI_RobustnessComparison = buildTableI(MULTIDAY, cfg);
Tables.TableJ_StatisticalPairedComparison = MULTIDAY.StatisticalResults;
Tables.TableK_TariffSensitivitySummary = MULTIDAY.TariffSensitivity;
Tables.TableL_ExportManifest = buildTableLPlaceholder();

% Backwards-compatible names used by the first multi-day implementation.
Tables.TableV_EconomicSummary = Tables.TableH_MultiDayEconomicSummary;
Tables.TableVI_OperationalSummary = Tables.TableG_MultiDayOperationalSummary;
Tables.TableVII_RobustnessComparison = Tables.TableI_RobustnessComparison;
end

function T = buildTableA(MULTIDAY)
screen = MULTIDAY.Screening.Summary;
validation = MULTIDAY.ValidationSummary;
candidate = screen.CandidateDays(1);
valid = screen.ValidDays(1);
excluded = screen.ExcludedDays(1);
solverFailed = sum(~MULTIDAY.RunLog.SolverSolved);
usedStats = min(validation.DaysUsedInSummary);
Metric = [
    "candidate days";
    "valid days";
    "excluded days";
    "solver-failed regime runs";
    "days used in statistics"
    ];
Value = [candidate; valid; excluded; solverFailed; usedStats];
Unit = ["days"; "days"; "days"; "regime-days"; "paired days"];
T = table(Metric, Value, Unit);
T.Properties.Description = "Table A. Data screening summary.";
end

function T = buildTableC(selected)
names = ["Date","DateLabel","DayType","LoadEnergy_kWh","PVEnergy_kWh","PVToLoadRatio", ...
    "EVAvailabilityHours","EVTripEnergy_kWh","DayClassification","SelectionReason"];
names = names(ismember(names, string(selected.Properties.VariableNames)));
T = selected(:, names);
T.Properties.Description = "Table C. Valid-days classification.";
end

function T = buildTableG(Summary, DailyMetrics, cfg)
regimes = cfg.project.regimeOrder;
Metric = [
    "mean grid import";
    "mean grid export";
    "mean net grid energy";
    "mean peak import";
    "mean peak export";
    "mean EV throughput";
    "mean EV SOC minimum";
    "percentage of net-export days"
    ];
Unit = [
    "kWh/day";
    "kWh/day";
    "kWh/day";
    "kW";
    "kW";
    "kWh/day";
    "%";
    "%"
    ];
values = strings(numel(Metric), numel(regimes));
for r = 1:numel(regimes)
    regime = regimes(r);
    rows = DailyMetrics.Regime == regime & DailyMetrics.UseInSummary;
    meanValues = [
        lookupSummary(Summary, "Grid import energy (kWh/day)", regime, "Mean")
        lookupSummary(Summary, "Grid export energy (kWh/day)", regime, "Mean")
        lookupSummary(Summary, "Net grid energy (kWh/day)", regime, "Mean")
        lookupSummary(Summary, "Peak grid import (kW)", regime, "Mean")
        lookupSummary(Summary, "Peak grid export (kW)", regime, "Mean")
        lookupSummary(Summary, "EV throughput (kWh/day)", regime, "Mean")
        lookupSummary(Summary, "EV SOC minimum (%)", regime, "Mean")
        100*mean(DailyMetrics.NetGridEnergy_kWh_per_day(rows) < 0)
        ];
    stdValues = [
        lookupSummary(Summary, "Grid import energy (kWh/day)", regime, "Std")
        lookupSummary(Summary, "Grid export energy (kWh/day)", regime, "Std")
        lookupSummary(Summary, "Net grid energy (kWh/day)", regime, "Std")
        lookupSummary(Summary, "Peak grid import (kW)", regime, "Std")
        lookupSummary(Summary, "Peak grid export (kW)", regime, "Std")
        lookupSummary(Summary, "EV throughput (kWh/day)", regime, "Std")
        lookupSummary(Summary, "EV SOC minimum (%)", regime, "Std")
        NaN
        ];
    for i = 1:numel(Metric)
        if isfinite(stdValues(i))
            values(i, r) = sprintf('%.3f +/- %.3f', meanValues(i), stdValues(i));
        else
            values(i, r) = sprintf('%.3f', meanValues(i));
        end
    end
end
v2gMedian = [
    lookupSummary(Summary, "Grid import energy (kWh/day)", "V2G", "Median")
    lookupSummary(Summary, "Grid export energy (kWh/day)", "V2G", "Median")
    lookupSummary(Summary, "Net grid energy (kWh/day)", "V2G", "Median")
    lookupSummary(Summary, "Peak grid import (kW)", "V2G", "Median")
    lookupSummary(Summary, "Peak grid export (kW)", "V2G", "Median")
    lookupSummary(Summary, "EV throughput (kWh/day)", "V2G", "Median")
    lookupSummary(Summary, "EV SOC minimum (%)", "V2G", "Median")
    NaN
    ];
v2gRange = strings(numel(Metric), 1);
sourceMetrics = [
    "Grid import energy (kWh/day)"
    "Grid export energy (kWh/day)"
    "Net grid energy (kWh/day)"
    "Peak grid import (kW)"
    "Peak grid export (kW)"
    "EV throughput (kWh/day)"
    "EV SOC minimum (%)"
    ""
    ];
for i = 1:numel(Metric)
    if sourceMetrics(i) == ""
        v2gRange(i) = "";
    else
        v2gRange(i) = sprintf('%.3f to %.3f', ...
            lookupSummary(Summary, sourceMetrics(i), "V2G", "Minimum"), ...
            lookupSummary(Summary, sourceMetrics(i), "V2G", "Maximum"));
    end
end
T = table(Metric, Unit, values(:,1), values(:,2), values(:,3), string(compose('%.3f', v2gMedian)), v2gRange, ...
    'VariableNames', {'Metric','Unit','V2HOld_MeanSD','V2H_MeanSD','V2G_MeanSD','V2G_Median','V2G_MinMax'});
T.Properties.Description = "Table G. Multi-day operational summary.";
end

function T = buildTableH(Summary, cfg)
regimes = cfg.project.regimeOrder;
Metric = [
    "net operating cost";
    "import cost";
    "export revenue";
    "battery degradation cost";
    "EV degradation cost";
    "improvement vs V2H"
    ];
Unit = [
    "GBP/day";
    "GBP/day";
    "GBP/day";
    "GBP/day";
    "GBP/day";
    "GBP/day"
    ];
source = [
    "Net operating cost (GBP/day)"
    "Import cost (GBP/day)"
    "Export revenue (GBP/day)"
    "Battery degradation cost (GBP/day)"
    "EV degradation cost (GBP/day)"
    "Improvement vs V2H (GBP/day)"
    ];
values = strings(numel(Metric), numel(regimes));
for r = 1:numel(regimes)
    for i = 1:numel(Metric)
        mu = lookupSummary(Summary, source(i), regimes(r), "Mean");
        sd = lookupSummary(Summary, source(i), regimes(r), "Std");
        if isfinite(sd)
            values(i, r) = sprintf('%.3f +/- %.3f', mu, sd);
        else
            values(i, r) = sprintf('%.3f', mu);
        end
    end
end
T = table(Metric, Unit, values(:,1), values(:,2), values(:,3), ...
    'VariableNames', {'Metric','Unit','V2HOld_MeanSD','V2H_MeanSD','V2G_MeanSD'});
T.Properties.Description = "Table H. Multi-day economic summary.";
end

function T = buildTableI(MULTIDAY, cfg)
V = MULTIDAY.ValidationSummary;
C = MULTIDAY.RegimeComparison;
Metric = [
    "days solved";
    "days passed validation";
    "days V2G lowest cost";
    "days V2G net exporter";
    "mean V2G benefit vs V2H";
    "worst V2G benefit vs V2H";
    "best V2G benefit vs V2H";
    "percentage V2G lowest cost";
    "percentage V2G passes validation";
    "percentage V2H-Old fails EV availability"
    ];
Unit = [
    "days";
    "days";
    "days";
    "days";
    "GBP/day";
    "GBP/day";
    "GBP/day";
    "%";
    "%";
    "%"
    ];
pairedDays = lookupComparison(C, "Solved paired days");
Value = [
    lookupValidation(V, "V2G", "SolverSolvedDays")
    lookupValidation(V, "V2G", "FullValidationPassDays")
    pairedDays*lookupComparison(C, "Percentage of days where V2G has the lowest net operating cost")/100
    pairedDays*lookupComparison(C, "Percentage of days where V2G becomes net exporter")/100
    lookupComparison(C, "Average V2G benefit vs V2H")
    lookupComparison(C, "Worst-case V2G benefit vs V2H")
    lookupComparison(C, "Best-case V2G benefit vs V2H")
    lookupComparison(C, "Percentage of days where V2G has the lowest net operating cost")
    lookupComparison(C, "Percentage of days where V2G passes all validation checks")
    lookupComparison(C, "Percentage of days where V2H-Old fails EV availability")
    ];
T = table(Metric, Unit, Value);
T.Properties.Description = "Table I. Robustness comparison.";
end

function T = buildTableLPlaceholder()
Item = [
    "figures exported";
    "tables exported";
    "text sections exported";
    "MAT files saved";
    "logs saved"
    ];
Status = repmat("created during export/report stage", numel(Item), 1);
T = table(Item, Status);
T.Properties.Description = "Table L. Word report export manifest.";
end

function x = lookupSummary(Summary, metric, regime, statName)
idx = Summary.Metric == metric & Summary.Regime == regime;
if any(idx)
    x = Summary.(statName)(find(idx, 1));
else
    x = NaN;
end
end

function x = lookupComparison(C, metric)
idx = C.Metric == metric;
if any(idx)
    x = C.Value(find(idx, 1));
else
    x = NaN;
end
end

function x = lookupValidation(V, regime, fieldName)
idx = V.Regime == regime;
if any(idx)
    x = V.(fieldName)(find(idx, 1));
else
    x = NaN;
end
end
