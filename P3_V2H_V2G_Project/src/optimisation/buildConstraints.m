function model = buildConstraints(cfg, inputs, flags, dv)
%BUILDCONSTRAINTS Build deterministic matrices used by the CVX model.

D = cfg.DPoints;
I = eye(D);

evDisCoeff = ones(D, 1);
evChargeCoeff = ones(D, 1);
if flags.evDischargeInBalanceGated
    evDisCoeff = inputs.ev.available(:);
end

model = struct();
model.A1 = [I, I, diag(evDisCoeff), diag(evChargeCoeff), I, -I];
model.b1 = inputs.P_load(:) - inputs.P_pv(:);

dishP = cfg.appliances.dishwasher.power;
washP = cfg.appliances.washingMachine.power;
model.A10 = [-dishP * I, -washP * I];

netForecast = inputs.P_load_forecast(:) - inputs.P_pv_forecast(:);
samplesPerHour = round(D/24);
idxStart = 16*samplesPerHour + 1;
idxEnd = 20*samplesPerHour;
idxStart = max(1, min(idxStart, D));
idxEnd = max(idxStart, min(idxEnd, D));
peakForecast = max(cfg.Dt * sum(netForecast(idxStart:idxEnd)), 0);

if flags.useLegacyReserveAbs
    % Legacy V2H-Old used abs() around this reserve expression. It is kept
    % only for the old baseline so the corrected cases remain physically
    % interpretable and do not inherit the historical reserve sign bug.
    peakReserveMode = "legacy_abs";
else
    peakReserveMode = "physical";
end

model.peakForecast_kWh = peakForecast;
model.peakReserveMode = peakReserveMode;
model.lb = dv.lb;
model.ub = dv.ub;
model.evDisCoeff = evDisCoeff;
model.evChargeCoeff = evChargeCoeff;
model.flags = flags;
end

