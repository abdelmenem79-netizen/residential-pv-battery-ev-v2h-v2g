function dv = buildDecisionVariables(cfg, inputs, flags)
%BUILDDECISIONVARIABLES Define common decision-vector indexing and bounds.

D = cfg.DPoints;
dv = struct();
dv.n = 6*D;
dv.idx.P_batt_discharge = (1:D).';
dv.idx.P_batt_charge = (D+1:2*D).';
dv.idx.P_ev_discharge = (2*D+1:3*D).';
dv.idx.P_ev_charge = (3*D+1:4*D).';
dv.idx.P_grid_import = (4*D+1:5*D).';
dv.idx.P_grid_export = (5*D+1:6*D).';

ubExport = cfg.grid.Pmax * ones(D, 1);
if ~flags.exportEnabled
    ubExport(:) = 0;
end

dv.ub = [
    cfg.battery.Pmax * ones(D, 1)
    zeros(D, 1)
    cfg.ev.Pmax * ones(D, 1)
    zeros(D, 1)
    cfg.grid.Pmax * ones(D, 1)
    ubExport
    ];

dv.lb = [
    zeros(D, 1)
    -cfg.battery.Pmax * ones(D, 1)
    zeros(D, 1)
    -cfg.ev.Pmax * ones(D, 1)
    zeros(D, 1)
    zeros(D, 1)
    ];

dv.evAvailable = inputs.ev.available(:);
dv.regime = flags.name;
end

