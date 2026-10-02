function Text = generateMultiDayText(MULTIDAY, cfg)
%GENERATEMULTIDAYTEXT Generate cautious IEEE-style text from computed values.

C = MULTIDAY.RegimeComparison;
V = MULTIDAY.ValidationSummary;
S = MULTIDAY.StatisticalEvidence;
selected = MULTIDAY.SelectedDays;

pairedDays = lookup(C, "Solved paired days");
meanBenefit = lookup(C, "Average V2G benefit vs V2H");
worstBenefit = lookup(C, "Worst-case V2G benefit vs V2H");
bestBenefit = lookup(C, "Best-case V2G benefit vs V2H");
lowestPct = lookup(C, "Percentage of days where V2G has the lowest net operating cost");
netExporterPct = lookup(C, "Percentage of days where V2G becomes net exporter");

Text = struct();
Text.methodology = sprintf(['The single-day case study is used to explain the dispatch mechanism in detail, ' ...
    'while the multi-day assessment tests whether the economic pattern remains consistent across different ' ...
    'demand, PV, and EV-availability conditions. The representative-day set contains %d day(s), selected using ' ...
    'the "%s" method from available House 1 profiles. The selected dates are: %s.'], ...
    height(selected), cfg.analysis.representativeDayMethod, strjoin(selected.DateLabel, ', '));

Text.results_paragraph = sprintf(['Across the solved paired representative days, the mean V2G benefit relative ' ...
    'to corrected V2H is %.3f GBP/day. The worst and best daily V2G benefits relative to V2H are %.3f and %.3f ' ...
    'GBP/day, respectively. V2G has the lowest net operating cost on %.1f%% of paired solved days and becomes a ' ...
    'net exporter on %.1f%% of paired solved days.'], ...
    meanBenefit, worstBenefit, bestBenefit, lowestPct, netExporterPct);

Text.economic_discussion = sprintf(['The multi-day results should be interpreted as robustness evidence rather ' ...
    'than a full annual performance estimate. A positive mean benefit indicates that export-enabled V2G can reduce ' ...
    'net operating cost relative to corrected V2H under the selected profiles, but the worst-case benefit should be ' ...
    'reported alongside the mean because individual days may have weaker export value or different EV availability.']);

Text.robustness_interpretation = buildRobustnessText(S);

Text.limitations = sprintf(['The single-day case shows the operating mechanism and is not an annual performance ' ...
    'estimate. Representative days improve robustness compared with a single day, but remain an approximation and ' ...
    'do not replace full-year optimisation. Full-year optimisation would provide stronger evidence, but at higher ' ...
    'computational cost. The tariff sensitivity is fixed-dispatch unless the model is re-optimised for each tariff ' ...
    'case. EV behaviour depends on the mobility profile available in the input data. Annualised values, when enabled, ' ...
    'should be labelled as annualised from representative-day mean and computed as mean daily value multiplied by 365.']);

Text.validation_note = sprintf(['Multi-day validation records solver status, power balance, bounds, grid logic, ' ...
    'and EV availability for each day and regime. Corrected V2H and V2G should pass EV availability checks; V2H-Old ' ...
    'is retained as a legacy baseline and may fail EV-availability validation by construction. Days used in summary ' ...
    'statistics must pass solver, power-balance, bounds, and grid-logic checks unless cfg.analysis.includeFailedDays ' ...
    'is set to true. V2G days used in summary: %.0f of %.0f.'], ...
    lookupValidation(V, "V2G", "DaysUsedInSummary"), lookupValidation(V, "V2G", "TotalDays"));
end

function text = buildRobustnessText(S)
idx = S.Comparison == "V2H net cost minus V2G net cost";
if ~any(idx)
    text = "No paired V2H-V2G statistical comparison was available because no paired solved days were found.";
    return
end
row = S(find(idx, 1), :);
text = sprintf(['For the paired V2H versus V2G comparison, the mean daily cost difference is %.3f GBP/day ' ...
    '(positive values favour V2G), with %d improving days, %d worsening days, and %d ties. The statistical method ' ...
    'reported is: %s.'], row.MeanDifference_GBP_per_day, row.ImprovedDays, row.WorsenedDays, ...
    row.TieDays, row.Method);
end

function x = lookup(T, metric)
idx = T.Metric == metric;
if any(idx)
    x = T.Value(find(idx, 1));
else
    x = NaN;
end
end

function x = lookupValidation(T, regime, variableName)
idx = T.Regime == regime;
if any(idx)
    x = T.(variableName)(find(idx, 1));
else
    x = NaN;
end
end
