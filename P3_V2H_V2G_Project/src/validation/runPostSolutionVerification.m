function Result = runPostSolutionVerification(Result, cfg)
%RUNPOSTSOLUTIONVERIFICATION Run all reviewer-requested validation checks.

% Revision runtime logging: verification timer covers post-solution checks
% only, from immediately before residual/logic/SOC/cost checks to after the
% final cost-reconstruction check.
verificationTimer = tic;
Result.validation.powerBalance = validatePowerBalance(Result, cfg);
Result.validation.bounds = validateBounds(Result, cfg);
Result.validation.gridLogic = validateGridLogic(Result, cfg);
Result.validation.evAvailability = validateEVAvailability(Result, cfg);
Result.validation.costReconstruction = validateCostReconstruction(Result, cfg);
Result.runtime.verification_s = toc(verificationTimer);
end
