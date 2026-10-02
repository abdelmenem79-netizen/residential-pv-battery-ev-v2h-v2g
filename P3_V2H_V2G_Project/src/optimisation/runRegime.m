function Result = runRegime(cfg, inputs, regime)
%RUNREGIME Dispatch one optimisation regime and return a standard result.

regime = string(regime);
switch regime
    case "V2HOld"
        Result = solveV2HOld(cfg, inputs);
    case "V2H"
        Result = solveV2H(cfg, inputs);
    case "V2G"
        Result = solveV2G(cfg, inputs);
    otherwise
        error('Unknown optimisation regime: %s', regime);
end
end

