function S = buildVerificationSummary(Result, cfg)
%BUILDVERIFICATIONSUMMARY Flatten runtime, model-size, and validation data.

S = struct();
S.regime = paperRegimeLabel(Result, cfg);
S.solverStatus = string(Result.solver.status);
S.objectiveValue = scalarField(Result.solver, "objective", NaN);
S.optimisationRuntime_s = scalarField(Result.runtime, "optimisation_s", NaN);
S.verificationRuntime_s = scalarField(Result.runtime, "verification_s", NaN);
S.totalRuntime_s = scalarField(Result.runtime, "total_s", NaN);
S.timeSteps = scalarField(Result.model, "timeSteps", numel(Result.time_h));
S.continuousVariables = scalarField(Result.model, "continuousVariables", NaN);
S.binaryVariables = scalarField(Result.model, "binaryVariables", NaN);
S.maxAbsBalanceResidual_kW = scalarField(Result.validation.powerBalance, "maxAbs_kW", NaN);
S.rmsBalanceResidual_kW = scalarField(Result.validation.powerBalance, "rms_kW", NaN);
S.boundViolation = ~logicalField(Result.validation.bounds, "pass", false);
S.gridSimultaneityViolation = ~logicalField(Result.validation.gridLogic, "pass", false);
S.evAvailabilityViolation = ~logicalField(Result.validation.evAvailability, "pass", false);
S.evChargeAway_kW = scalarField(Result.validation.evAvailability, "evChargeWhileAway_kW", NaN);
S.evDischargeAway_kW = scalarField(Result.validation.evAvailability, "evDischargeWhileAway_kW", NaN);
S.costReconstructionError = scalarField(Result.validation.costReconstruction, "absError", NaN);
end

function label = paperRegimeLabel(Result, cfg)
regime = string(Result.regime);
labels = cfg.project.regimeLabels;
order = cfg.project.regimeOrder;
idx = find(order == regime, 1);
if isempty(idx)
    label = string(Result.name);
elseif regime == "V2H"
    label = "Corrected V2H";
else
    label = labels(idx);
end
end

function value = scalarField(S, name, fallback)
if isfield(S, char(name))
    value = S.(char(name));
    if ~isscalar(value)
        value = value(1);
    end
else
    value = fallback;
end
end

function value = logicalField(S, name, fallback)
if isfield(S, char(name))
    value = logical(S.(char(name)));
else
    value = fallback;
end
end
