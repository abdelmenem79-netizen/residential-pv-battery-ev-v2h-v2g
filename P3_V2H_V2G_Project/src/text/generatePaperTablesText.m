function T = generatePaperTablesText()
%GENERATEPAPERTABLESTEXT Captions for the required P3 tables.

TableID = ["Table I"; "Table II"; "Table III"; "Table IV"];
Caption = [
    "Operational comparison across V2H-Old, corrected V2H, and export-enabled V2G."
    "Economic comparison across V2H-Old, corrected V2H, and export-enabled V2G using daily GBP costs."
    "Validation comparison across the three regimes, including power balance, bounds, grid exclusivity, and EV availability checks."
    "Tariff sensitivity for low, medium, and high import/export tariff cases with daily cost units."
    ];

T = table(TableID, Caption);
end

