function out = validateCostReconstruction(Result, cfg)
%VALIDATECOSTRECONSTRUCTION Compare reconstructed reported cost to objective.

if isfield(Result, 'solver') && isfield(Result.solver, 'objective')
    objectiveValue = double(Result.solver.objective);
else
    objectiveValue = NaN;
end

if isfield(Result, 'cost') && isfield(Result.cost, 'total')
    reconstructedValue = double(Result.cost.total);
else
    reconstructedValue = NaN;
end

absError = abs(reconstructedValue - objectiveValue);
tol = 1e-6;
if isfield(cfg, 'validation') && isfield(cfg.validation, 'costReconstructionTolerance')
    tol = cfg.validation.costReconstructionTolerance;
end

out = struct();
out.objectiveValue = objectiveValue;
out.reconstructedCost = reconstructedValue;
out.absError = absError;
out.pass = isfinite(absError) && absError <= tol;
out.unit = "GBP/day";
out.definition = "abs(reconstructed net cost - solver objective)";
end
