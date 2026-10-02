function dayData = loadHouseData(cfg, dayNumber)
%LOADHOUSEDATA Load one House 1 day using the legacy day slicing convention.

if exist(cfg.paths.data.processedHouseData, 'file')
    S = load(cfg.paths.data.processedHouseData, 'House1_data_Struct');
    house = S.House1_data_Struct;
else
    error('Processed house data not found: %s', cfg.paths.data.processedHouseData);
end

idx = house.DayNum >= dayNumber - 1 & floor(house.DayNum) <= dayNumber;

data.Hour = house.Hour(idx);
data.Load = house.PL1(idx);
data.PV = house.PV1(idx);
data.EVStatus = house.EV1S(idx);
data.EVDistance = house.EV1D(idx);
data.DayNum = house.DayNum(idx);

if numel(data.Load) < 2*cfg.DPoints
    error('House data for day %.0f has %d samples; expected at least %d.', ...
        dayNumber, numel(data.Load), 2*cfg.DPoints);
end

dayData = struct();
dayData.dayNumber = dayNumber;
dayData.time_h = (0:cfg.DPoints-1).' * cfg.Dt;
dayData.load_kW = data.Load(cfg.DPoints+1:2*cfg.DPoints);
dayData.pv_kW = data.PV(cfg.DPoints+1:2*cfg.DPoints);
dayData.evAvailableRaw = data.EVStatus(cfg.DPoints+1:2*cfg.DPoints);
dayData.evDistanceRaw = data.EVDistance(cfg.DPoints+1:2*cfg.DPoints);
dayData.source = "House1_data_Struct";
end

