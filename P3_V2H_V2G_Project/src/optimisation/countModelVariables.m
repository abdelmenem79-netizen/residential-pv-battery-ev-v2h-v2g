function modelStats = countModelVariables(dv, D)
%COUNTMODELVARIABLES Count scalar decision variables from declared sizes.
%
% The shared MILP declares one continuous vector x(dv.n), one binary
% operating-mode vector isOn(dv.n), appliance on/off binaries POn(2*D), and
% appliance start-up binaries startupp(2*D).

continuousCount = numel((1:dv.n).');
binaryIsOnCount = numel((1:dv.n).');
binaryApplianceOnCount = numel((1:2*D).');
binaryStartupCount = numel((1:2*D).');

modelStats = struct();
modelStats.timeSteps = D;
modelStats.continuousVariables = continuousCount;
modelStats.binaryVariables = binaryIsOnCount + binaryApplianceOnCount + binaryStartupCount;
modelStats.binaryBreakdown = struct( ...
    'storageGridMode', binaryIsOnCount, ...
    'applianceOnOff', binaryApplianceOnCount, ...
    'applianceStartup', binaryStartupCount);
end
