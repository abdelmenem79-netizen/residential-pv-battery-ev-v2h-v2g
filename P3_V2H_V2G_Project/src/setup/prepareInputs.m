function inputs = prepareInputs(cfg)
%PREPAREINPUTS Build all deterministic inputs for the P3 optimisation run.

day1 = loadHouseData(cfg, cfg.case.date);
day2 = loadHouseData(cfg, cfg.case.date + 1);

load_kW = abs(day1.load_kW(:));
pv_kW = abs(day1.pv_kW(:));
loadForecast_kW = abs(day2.load_kW(:));
pvForecast_kW = abs(day2.pv_kW(:));

load_kW(load_kW < 0.01) = 0.01;
pv_kW(pv_kW < 0) = 0;
loadForecast_kW(loadForecast_kW < 0.01) = 0.01;
pvForecast_kW(pvForecast_kW < 0) = 0;

socBatteryStart = cfg.battery.socStartPct;
if exist(cfg.paths.data.socBattery, 'file')
    socBattery = readmatrix(cfg.paths.data.socBattery);
    if ~isempty(socBattery) && size(socBattery, 2) >= 1 && isfinite(socBattery(1,1))
        socBatteryStart = socBattery(1,1);
    end
end

socEVStart = cfg.ev.socStartPct;
if exist(cfg.paths.data.socEV, 'file')
    socEV = readmatrix(cfg.paths.data.socEV);
    if ~isempty(socEV) && size(socEV, 2) >= 1 && isfinite(socEV(1,1))
        socEVStart = socEV(1,1);
    end
end

inputs = struct();
inputs.time_h = day1.time_h(:);
inputs.P_load = load_kW(:);
inputs.P_pv = pv_kW(:);
inputs.P_load_forecast = loadForecast_kW(:);
inputs.P_pv_forecast = pvForecast_kW(:);
inputs.tariff = buildTariffs(cfg);
inputs.ev = buildEVProfile(cfg, day1.evAvailableRaw, day1.evDistanceRaw);
inputs.initialSOC.battery_pct = socBatteryStart;
inputs.initialSOC.ev_pct = socEVStart;
inputs.appliances = cfg.appliances;
inputs.metadata.dayNumber = cfg.case.date;
inputs.metadata.source = day1.source;
end

