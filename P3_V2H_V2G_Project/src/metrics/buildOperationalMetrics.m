function T = buildOperationalMetrics(RESULTS, cfg)
%BUILDOPERATIONALMETRICS Build Table I operational comparison.

metrics = [
    "Grid import energy"
    "Grid export energy"
    "Net grid energy"
    "Peak grid import"
    "Peak grid export"
    "EV charge energy"
    "EV discharge energy"
    "Battery throughput"
    "EV throughput"
    "Battery SOC minimum"
    "Battery SOC maximum"
    "Battery SOC final"
    "EV SOC minimum"
    "EV SOC maximum"
    "EV SOC final"
    "Export-to-PV ratio"
    "Household autonomy ratio"
    ];

units = [
    "kWh/day"
    "kWh/day"
    "kWh/day"
    "kW"
    "kW"
    "kWh/day"
    "kWh/day"
    "kWh/day"
    "kWh/day"
    "%"
    "%"
    "%"
    "%"
    "%"
    "%"
    "ratio"
    "ratio"
    ];

regimes = cfg.project.regimeOrder;
M = zeros(numel(metrics), numel(regimes));
for k = 1:numel(regimes)
    R = RESULTS.(regimes(k));
    Dt = mean(diff(R.time_h(:)));
    if ~isfinite(Dt) || Dt <= 0
        Dt = cfg.Dt;
    end

    gridImport = sum(max(R.P_grid_import(:), 0))*Dt;
    gridExport = sum(max(R.P_grid_export(:), 0))*Dt;
    netGrid = sum(R.P_grid_net(:))*Dt;
    % Some saved result sets store charging as negative power. Use the
    % magnitude so the reported charging energy remains physically positive.
    evCharge = sum(abs(R.P_ev_charge(:)))*Dt;
    evDischarge = sum(R.P_ev_discharge(:))*Dt;
    battThroughput = sum(R.P_batt_charge(:) + R.P_batt_discharge(:))*Dt;
    evThroughput = sum(abs(R.P_ev_charge(:)) + R.P_ev_discharge(:))*Dt;
    pvGeneration = sum(max(R.P_pv(:), 0))*Dt;
    loadEnergy = sum(max(R.P_load(:), 0))*Dt;
    exportToPV = gridExport / max(pvGeneration, eps);
    autonomy = min(max(1 - gridImport/max(loadEnergy, eps), 0), 1);

    M(:, k) = [
        gridImport
        gridExport
        netGrid
        max(R.P_grid_import(:))
        max(R.P_grid_export(:))
        evCharge
        evDischarge
        battThroughput
        evThroughput
        min(R.SOC_batt(:))
        max(R.SOC_batt(:))
        R.SOC_batt(end)
        min(R.SOC_ev(:))
        max(R.SOC_ev(:))
        R.SOC_ev(end)
        exportToPV
        autonomy
        ];
end

T = table(metrics, units, M(:,1), M(:,2), M(:,3), ...
    'VariableNames', {'Metric', 'Unit', char(regimes(1)), char(regimes(2)), char(regimes(3))});
T.Properties.Description = "Table I. Operational comparison across V2H-Old, V2H, and V2G.";
end
