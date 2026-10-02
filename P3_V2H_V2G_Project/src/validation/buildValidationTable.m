function T = buildValidationTable(RESULTS, cfg)
%BUILDVALIDATIONTABLE Build IEEE-ready validation comparison table.

regimes = cfg.project.regimeOrder;
labels = cfg.project.regimeLabels;

metric = [
    "Maximum power balance error"
    "RMS power balance error"
    "Lower-bound violation"
    "Upper-bound violation"
    "Simultaneous import/export indicator"
    "Maximum grid binary sum"
    "EV discharge while away"
    "EV charge while away"
    "EV SOC lower-bound violation"
    "EV SOC upper-bound violation"
    "Power balance pass"
    "Bounds pass"
    "Grid logic pass"
    "EV availability pass"
    "Cost reconstruction error"
    "Cost reconstruction pass"
    "Solver status"
    ];

unit = [
    "kW"
    "kW"
    "percentage point"
    "percentage point"
    "kW"
    "binary sum"
    "kW"
    "kW"
    "percentage point"
    "percentage point"
    "pass/fail"
    "pass/fail"
    "pass/fail"
    "pass/fail"
    "GBP/day"
    "pass/fail"
    "text"
    ];

values = strings(numel(metric), numel(regimes));
for k = 1:numel(regimes)
    R = RESULTS.(regimes(k));
    vals = [
        string(fmt(R.validation.powerBalance.maxAbs_kW))
        string(fmt(R.validation.powerBalance.rms_kW))
        string(fmt(R.validation.bounds.lowerBoundViolation))
        string(fmt(R.validation.bounds.upperBoundViolation))
        string(fmt(R.validation.gridLogic.simultaneousImportExport_kW))
        string(fmt(R.validation.gridLogic.gridBinarySumMax))
        string(fmt(R.validation.evAvailability.evDischargeWhileAway_kW))
        string(fmt(R.validation.evAvailability.evChargeWhileAway_kW))
        string(fmt(R.validation.bounds.evSOCLowerViolation))
        string(fmt(R.validation.bounds.evSOCUpperViolation))
        passText(R.validation.powerBalance.pass)
        passText(R.validation.bounds.pass)
        passText(R.validation.gridLogic.pass)
        passText(R.validation.evAvailability.pass)
        string(fmt(R.validation.costReconstruction.absError))
        passText(R.validation.costReconstruction.pass)
        string(R.solver.status)
        ];
    values(:, k) = vals;
end

T = table(metric, unit, values(:,1), values(:,2), values(:,3), ...
    'VariableNames', {'Metric', 'Unit', char(regimes(1)), char(regimes(2)), char(regimes(3))});
T.Properties.Description = "Table III. Validation comparison.";

for k = 1:numel(labels)
    T.Properties.VariableDescriptions{2+k} = char(labels(k));
end
end

function s = fmt(x)
if isnan(x)
    s = "NaN";
else
    x(x == 0) = 0;
    s = compose('%.6g', x);
end
end

function s = passText(tf)
if tf
    s = "PASS";
else
    s = "FAIL";
end
end
