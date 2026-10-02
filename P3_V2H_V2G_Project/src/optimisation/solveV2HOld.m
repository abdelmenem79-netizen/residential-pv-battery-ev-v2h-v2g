function Result = solveV2HOld(cfg, inputs)
%SOLVEV2HOLD Solve the restrictive legacy V2H baseline.

flags = struct();
flags.name = "V2HOld";
flags.label = "V2H-Old";
flags.exportEnabled = false;
flags.exportRevenueEnabled = false;
flags.evAvailabilityGated = false;
flags.evDischargeInBalanceGated = true;
flags.evToGridAllowed = false;
flags.batteryToGridAllowed = false;
flags.useLegacyReserveAbs = true;

Result = solveStorageRegimeCVX(cfg, inputs, flags);
end

