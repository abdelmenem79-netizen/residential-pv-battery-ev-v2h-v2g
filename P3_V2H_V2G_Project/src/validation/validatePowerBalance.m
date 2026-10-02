function out = validatePowerBalance(Result, cfg)
%VALIDATEPOWERBALANCE Check the model-level power balance residual.

% Revision residual correction: use the exact solver-side equality whenever
% the raw optimisation matrices are available:
%     A1*x + A10*POn - b1 = 0
% This prevents plotted/reconstructed component balances from being mixed
% with the authoritative MILP residual.
if isfield(Result, 'raw') && ...
        isfield(Result.raw, 'powerBalanceMatrix') && ...
        isfield(Result.raw, 'applianceMatrix') && ...
        isfield(Result.raw, 'powerBalanceRHS') && ...
        isfield(Result.raw, 'x') && ...
        isfield(Result.raw, 'POn')
    residual = Result.raw.powerBalanceMatrix * Result.raw.x(:) + ...
        Result.raw.applianceMatrix * Result.raw.POn(:) - ...
        Result.raw.powerBalanceRHS(:);
    residualDefinition = "A1*x + A10*POn - b1";
else
    residual = Result.P_balance_LHS(:) - Result.P_balance_RHS(:);
    residualDefinition = "P_balance_LHS - P_balance_RHS";
end

out = struct();
out.residual_kW = residual(:);
out.maxAbs_kW = max(abs(residual));
out.rms_kW = sqrt(mean(residual.^2));
out.pass = out.maxAbs_kW <= cfg.optimization.powerBalanceTolerance;
out.unit = "kW";
out.definition = residualDefinition;
end
