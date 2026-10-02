function out = validateGridLogic(Result, cfg)
%VALIDATEGRIDLOGIC Check simultaneous import/export and binary indicators.

simultaneousPower = max(min(Result.P_grid_import(:), Result.P_grid_export(:)));
binarySumMax = NaN;
if isfield(Result, 'raw') && isfield(Result.raw, 'isOn')
    D = cfg.DPoints;
    binaryImport = Result.raw.isOn(4*D+1:5*D);
    binaryExport = Result.raw.isOn(5*D+1:6*D);
    binarySumMax = max(binaryImport + binaryExport);
end

out = struct();
out.simultaneousImportExport_kW = simultaneousPower;
out.gridBinarySumMax = binarySumMax;
out.pass = simultaneousPower <= cfg.optimization.boundTolerance && ...
    (isnan(binarySumMax) || binarySumMax <= 1 + cfg.optimization.boundTolerance);
end

