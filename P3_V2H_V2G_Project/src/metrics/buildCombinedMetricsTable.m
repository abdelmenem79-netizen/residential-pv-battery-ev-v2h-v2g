function T = buildCombinedMetricsTable(Toperational, Tcost)
%BUILDCOMBINEDMETRICSTABLE Combine operational and economic rows.

T1 = Toperational;
T1.Category = repmat("Operational", height(T1), 1);
T2 = Tcost;
T2.Category = repmat("Economic", height(T2), 1);
T = [T1(:, ["Category", "Metric", "Unit", "V2HOld", "V2H", "V2G"]); ...
     T2(:, ["Category", "Metric", "Unit", "V2HOld", "V2H", "V2G"])];
T.Properties.Description = "Combined operational and economic metrics.";
end

