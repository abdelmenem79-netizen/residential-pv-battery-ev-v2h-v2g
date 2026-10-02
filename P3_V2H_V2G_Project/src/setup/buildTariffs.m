function tariff = buildTariffs(cfg)
%BUILDTARIFFS Build base import and export tariff vectors in GBP/kWh.

DPoints = cfg.DPoints;
samplesPerHour = round(DPoints/24);
if samplesPerHour*24 ~= DPoints
    error('DPoints must be a multiple of 24. DPoints=%d', DPoints);
end

import = cfg.tariff.import.offPeak * ones(DPoints, 1);
import(0*samplesPerHour+1 :  6*samplesPerHour) = cfg.tariff.import.offPeak;
import(6*samplesPerHour+1 : 16*samplesPerHour) = cfg.tariff.import.midPeak;
import(16*samplesPerHour+1: 19*samplesPerHour) = cfg.tariff.import.peak;
import(19*samplesPerHour+1: 23*samplesPerHour) = cfg.tariff.import.midPeak;
import(23*samplesPerHour+1: 24*samplesPerHour) = cfg.tariff.import.offPeak;

tariff = struct();
tariff.import = import(:);
tariff.export = cfg.tariff.export.base * ones(DPoints, 1);
tariff.unit = cfg.tariff.unit;
end

