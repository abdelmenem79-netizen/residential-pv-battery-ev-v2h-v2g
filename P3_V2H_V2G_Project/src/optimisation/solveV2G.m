function Result = solveV2G(cfg, inputs)
%SOLVEV2G Solve the export-enabled, market-aware V2G case.

flags = struct();
flags.name = "V2G";
flags.label = "V2G";
flags.exportEnabled = true;
flags.exportRevenueEnabled = true;
flags.evAvailabilityGated = true;
flags.evDischargeInBalanceGated = false;
flags.evToGridAllowed = true;
flags.batteryToGridAllowed = false;
flags.useLegacyReserveAbs = false;

Result = solveStorageRegimeCVX(cfg, inputs, flags);
end

