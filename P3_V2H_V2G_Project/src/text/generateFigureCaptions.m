function T = generateFigureCaptions()
%GENERATEFIGURECAPTIONS Captions for the required P3 figures.

Figure = (1:7).';
Caption = [
    "System and economic boundary used for P3, showing PV generation, household load, stationary battery, EV, grid import and export, tariff signals, and degradation-cost terms."
    "Daily grid import, export, and net grid energy for V2H-Old, corrected V2H, and export-enabled V2G."
    "Grid power profiles over the simulated day, where positive values denote import and negative values denote export."
    "EV net power profiles over the simulated day, with positive values denoting discharge and negative values denoting charging."
    "Stationary battery and EV state-of-charge profiles for the three optimisation regimes."
    "Daily net operating cost decomposition, including import cost, export revenue, stationary battery degradation, EV degradation, and total net cost."
    "Low, medium, and high tariff sensitivity of the economic benefit from corrected V2H and export-enabled V2G."
    ];

T = table(Figure, Caption);
end

