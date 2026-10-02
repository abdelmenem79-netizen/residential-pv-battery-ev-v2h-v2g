function aligned = alignEVAvailability(rawAvailability, nTarget)
%ALIGNEVAVAILABILITY Align raw EV availability to the optimisation grid.

rawAvailability = rawAvailability(:);
if numel(rawAvailability) == nTarget
    aligned = rawAvailability;
else
    idx = round(linspace(1, numel(rawAvailability), nTarget));
    aligned = rawAvailability(idx);
end

aligned = double(aligned(:) > 0.5);
end

