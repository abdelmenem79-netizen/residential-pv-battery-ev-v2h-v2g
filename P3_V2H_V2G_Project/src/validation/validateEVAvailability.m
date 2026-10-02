function out = validateEVAvailability(Result, cfg)
%VALIDATEEVAVAILABILITY Check EV charge/discharge commands while away.

away = Result.EV_available(:) < 0.5;
if any(away)
    dischargeAway = max(Result.P_ev_discharge(away));
    chargeAway = max(Result.P_ev_charge(away));
else
    dischargeAway = 0;
    chargeAway = 0;
end

out = struct();
out.evDischargeWhileAway_kW = dischargeAway;
out.evChargeWhileAway_kW = chargeAway;
out.pass = dischargeAway <= cfg.optimization.boundTolerance && ...
    chargeAway <= cfg.optimization.boundTolerance;
end

