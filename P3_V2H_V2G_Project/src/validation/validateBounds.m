function out = validateBounds(Result, cfg)
%VALIDATEBOUNDS Check finite values, vector consistency, and SOC limits.

required = [
    "time_h"
    "P_load"
    "P_pv"
    "P_grid_net"
    "P_grid_import"
    "P_grid_export"
    "P_ev_net"
    "P_ev_charge"
    "P_ev_discharge"
    "P_batt_net"
    "P_batt_charge"
    "P_batt_discharge"
    "SOC_batt"
    "SOC_ev"
    "cost"
    "solver"
    ];

missing = required(~isfield(Result, cellstr(required)));
n = numel(Result.time_h);
series = ["P_load","P_pv","P_grid_net","P_grid_import","P_grid_export", ...
    "P_ev_net","P_ev_charge","P_ev_discharge","P_batt_net","P_batt_charge", ...
    "P_batt_discharge","SOC_batt","SOC_ev"];

lengthMismatch = strings(0, 1);
hasBadValue = false;
for k = 1:numel(series)
    values = Result.(series(k));
    if numel(values) ~= n
        lengthMismatch(end+1, 1) = series(k); %#ok<AGROW>
    end
    if any(~isfinite(values(:)))
        hasBadValue = true;
    end
end

socBattLower = max(0, cfg.soc.min - min(Result.SOC_batt(:)));
socBattUpper = max(0, max(Result.SOC_batt(:)) - cfg.soc.max);
socEvLower = max(0, cfg.ev.soc.min - min(Result.SOC_ev(:)));
socEvUpper = max(0, max(Result.SOC_ev(:)) - cfg.ev.soc.max);

lbViolation = max([socBattLower, socEvLower]);
ubViolation = max([socBattUpper, socEvUpper]);

out = struct();
out.missingFields = missing(:);
out.lengthMismatch = lengthMismatch(:);
out.hasNaNOrInf = hasBadValue;
out.lowerBoundViolation = lbViolation;
out.upperBoundViolation = ubViolation;
out.batterySOCLowerViolation = socBattLower;
out.batterySOCUpperViolation = socBattUpper;
out.evSOCLowerViolation = socEvLower;
out.evSOCUpperViolation = socEvUpper;
out.pass = isempty(missing) && isempty(lengthMismatch) && ~hasBadValue && ...
    lbViolation <= cfg.optimization.boundTolerance && ...
    ubViolation <= cfg.optimization.boundTolerance;
end

