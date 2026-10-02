function Text = generateMultiDayResultsText(MULTIDAY, cfg)
%GENERATEMULTIDAYRESULTSTEXT Generate IEEE-style multi-day result text.

C = MULTIDAY.RegimeComparison;
V = MULTIDAY.ValidationSummary;
S = MULTIDAY.StatisticalResults;
selected = MULTIDAY.SelectedDays;
screening = MULTIDAY.Screening.Summary;

candidateDays = screening.CandidateDays(1);
validDays = screening.ValidDays(1);
excludedDays = screening.ExcludedDays(1);
pairedDays = lookup(C, "Solved paired days");
meanBenefit = lookup(C, "Average V2G benefit vs V2H");
worstBenefit = lookup(C, "Worst-case V2G benefit vs V2H");
bestBenefit = lookup(C, "Best-case V2G benefit vs V2H");
lowestPct = lookup(C, "Percentage of days where V2G has the lowest net operating cost");
netExporterPct = lookup(C, "Percentage of days where V2G becomes net exporter");

Text = struct();
Text.methodology_paragraph = sprintf(['The single-day case study is retained to explain the dispatch mechanism in detail. ' ...
    'The multi-day analysis then screens %d candidate day(s), excludes %d day(s) before optimisation, and selects %d valid day(s) ' ...
    'using the "%s" method. The multi-day assessment tests whether the same economic pattern is observed across valid days with ' ...
    'different load, PV-generation, EV-availability, and EV-use conditions.'], ...
    candidateDays, excludedDays, height(selected), cfg.analysis.representativeDayMethod);

Text.data_screening_text = sprintf(['The data-screening stage identified %d valid day(s) from %d candidate day(s). ' ...
    'Excluded days are not silently skipped; each excluded date is recorded with the failed check, reason, sample count, and action. ' ...
    'The valid-day table records daily load energy, PV energy, PV-to-load ratio, EV availability, EV trip energy, initial SOC values, ' ...
    'and day classification before optimisation.'], validDays, candidateDays);

Text.multi_day_results_text = sprintf(['Across the solved paired days used for the main comparison, the mean V2G benefit relative ' ...
    'to corrected V2H is %s GBP/day. The worst and best daily V2G benefits relative to V2H are %s and %s GBP/day, respectively. ' ...
    'V2G has the lowest net operating cost on %s%% of paired solved days and becomes a net exporter on %s%% of paired solved days.'], ...
    fmt(meanBenefit), fmt(worstBenefit), fmt(bestBenefit), fmt(lowestPct), fmt(netExporterPct));

Text.economic_discussion_text = sprintf(['The multi-day economic result is treated as robustness evidence rather than a full annual ' ...
    'performance estimate. A positive V2G benefit indicates that export-enabled operation can reduce the net daily operating cost ' ...
    'relative to corrected V2H within the tested dataset. The worst-case daily benefit is reported together with the mean because ' ...
    'the economic value of export depends on PV surplus, household demand, EV availability, and trip-energy requirements.']);

Text.statistical_results_text = generateStatisticalResultsText(MULTIDAY, cfg);

Text.tariff_sensitivity_text = sprintf(['The tariff sensitivity values are reported as daily values. By default the calculation is ' ...
    'an ex-post fixed-dispatch sensitivity: the solved dispatch is held fixed and the import and export prices are varied. If ' ...
    'cfg.tariff.reoptimiseSensitivity is enabled in a future run, tariff results should be labelled separately as re-optimised ' ...
    'tariff sensitivity and not mixed with fixed-dispatch values in the same table.']);

Text.validation_text = sprintf(['Validation is evaluated for each day and each regime. Corrected V2H and V2G must pass the EV ' ...
    'availability checks to be included in the main statistical comparison. V2H-Old is retained as a restrictive legacy baseline and ' ...
    'may fail EV-availability validation without excluding the day from the corrected V2H/V2G paired comparison. V2G days used in ' ...
    'summary statistics: %.0f of %.0f.'], ...
    lookupValidation(V, "V2G", "DaysUsedInSummary"), lookupValidation(V, "V2G", "TotalDays"));

Text.limitations_text = sprintf(['The single-day case shows the operating mechanism and is not an annual performance estimate. ' ...
    'The multi-day results improve robustness relative to a single-day case, but they should not be read as a full annual estimate ' ...
    'unless the full valid year is simulated or representative-day weighting is introduced. Full-year optimisation would provide ' ...
    'stronger evidence, but at higher computational cost. Tariff sensitivity is fixed-dispatch unless re-optimisation is explicitly ' ...
    'enabled. EV outcomes depend on the available mobility profile. Annualised values are disabled by default and, when enabled, are ' ...
    'labelled as annualised from the mean daily simulated value using daily value multiplied by 365.']);

Text.figure_captions = buildFigureCaptions(MULTIDAY);
Text.table_captions = buildTableCaptions();

% Backwards-compatible aliases used by earlier export code.
Text.methodology = Text.methodology_paragraph;
Text.results_paragraph = Text.multi_day_results_text;
Text.economic_discussion = Text.economic_discussion_text;
Text.robustness_interpretation = Text.statistical_results_text;
Text.limitations = Text.limitations_text;
Text.validation_note = Text.validation_text;
end

function text = buildFigureCaptions(MULTIDAY)
lines = strings(0, 1);
if isfield(MULTIDAY, 'Figures')
    for k = 1:numel(MULTIDAY.Figures)
        lines(end+1) = sprintf('%s: %s', MULTIDAY.Figures(k).baseName, MULTIDAY.Figures(k).caption); %#ok<AGROW>
    end
end
if isempty(lines)
    text = "No multi-day figures were generated.";
else
    text = strjoin(lines, newline);
end
end

function text = buildTableCaptions()
lines = [
    "Table A. Data screening summary."
    "Table B. Excluded-days log."
    "Table C. Valid-days classification."
    "Table D. Single-day operational comparison."
    "Table E. Single-day economic comparison."
    "Table F. Single-day validation summary."
    "Table G. Multi-day operational summary."
    "Table H. Multi-day economic summary."
    "Table I. Robustness comparison."
    "Table J. Statistical paired comparison."
    "Table K. Tariff sensitivity summary."
    "Table L. Word report export manifest."
    ];
text = strjoin(lines, newline);
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

function s = fmt(x)
if isfinite(x)
    s = char(compose('%.3f', x));
else
    s = 'not available';
end
end
