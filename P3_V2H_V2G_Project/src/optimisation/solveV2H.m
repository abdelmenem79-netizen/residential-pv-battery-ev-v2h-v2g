function Result = solveV2H(cfg, inputs)
%SOLVEV2H Solve the physically corrected household-centred V2H case.

flags = struct();
flags.name = "V2H";
flags.label = "V2H";
flags.exportEnabled = true;
flags.exportRevenueEnabled = true;
flags.evAvailabilityGated = true;
flags.evDischargeInBalanceGated = false;
flags.evToGridAllowed = false;
flags.batteryToGridAllowed = false;
flags.useLegacyReserveAbs = false;

Result = solveStorageRegimeCVX(cfg, inputs, flags);
end

