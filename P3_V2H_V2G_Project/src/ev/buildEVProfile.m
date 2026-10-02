function ev = buildEVProfile(cfg, rawAvailability, rawDistance)
%BUILDEVPROFILE Build EV availability and trip-energy profiles for one day.
%
% Legacy EV1_MODEL overwrote the requested date internally. This refactor
% takes the already loaded day-specific EV status and distance arrays, which
% keeps load, PV, EV availability, and trip energy on the same case-study day.

rawAvailability = double(rawAvailability(:));
rawDistance = double(rawDistance(:));

ev = struct();
ev.available = alignEVAvailability(rawAvailability, cfg.DPoints);
ev.rawAvailable = rawAvailability;
ev.rawDistance_miles = rawDistance;
ev.trip = computeTripEnergy(cfg, rawAvailability, rawDistance);
ev.capacity_kWh = cfg.ev.capacity;
ev.Pmax_kW = cfg.ev.Pmax;
ev.consumption_kWh_per_mile = cfg.ev.consumption;
ev.eta = cfg.ev.eta;
ev.socMin_pct = cfg.ev.soc.min;
ev.socMax_pct = cfg.ev.soc.max;
end

