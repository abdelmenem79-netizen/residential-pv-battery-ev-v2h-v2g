function plot_round2()
% Publication figures from certified R2.2 outputs, never historical plots.
out=fileparts(mfilename('fullpath'));F=load(fullfile(out,'Round2_Frozen_Results.mat'));
Q=load(fullfile(out,'audit','prepared_inputs_private.mat'));
T=load(fullfile(out,'Round2_tariff_results.mat'));
A=readtable(fullfile(out,'tables','restoration_day_level.csv'),'TextType','string', ...
    'Delimiter',',','ReadVariableNames',true,'VariableNamingRule','preserve');
green=[.10 .48 .30];orange=[.88 .38 .06];blue=[.05 .37 .68];red=[.75 .15 .18];
set(groot,'defaultAxesFontName','Times New Roman','defaultAxesFontSize',8, ...
    'defaultTextFontName','Times New Roman','defaultTextFontSize',8, ...
    'defaultLineLineWidth',1.15,'defaultFigureColor','w');
for mode=["none","ge"]
    H=load(fullfile(out,'runs_certified',"principal_"+mode+"_43598_V2H.mat"));
    G=load(fullfile(out,'runs_certified',"principal_"+mode+"_43598_V2G.mat"));
    f=fig(8.8,8.5);tl=tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
    nexttile;stairs([0;H.I.time_h+H.cfg.Dt],[H.R.P_ev_discharge-H.R.P_ev_charge;H.R.P_ev_discharge(end)-H.R.P_ev_charge(end)],'Color',green);hold on;
    stairs([0;G.I.time_h+G.cfg.Dt],[G.R.P_ev_discharge-G.R.P_ev_charge;G.R.P_ev_discharge(end)-G.R.P_ev_charge(end)],'--','Color',orange);
    yline(0,':','Color',[.4 .4 .4]);ylabel('EV net power (kW)');title('(a) EV power');ylim([-7 7]);yticks(-6:3:6);styleTime;
    legend('Corrected V2H','V2G','Location','northoutside','Orientation','horizontal','Box','off');
    nexttile;plot([0;H.I.time_h+H.cfg.Dt],[H.I.initialSOC.ev_pct;H.R.SOC_ev],'Color',green);hold on;
    plot([0;G.I.time_h+G.cfg.Dt],[G.I.initialSOC.ev_pct;G.R.SOC_ev],'--','Color',orange);
    ylabel('EV SOC (%)');xlabel('Time (h)');title('(b) Reconstructed EV state');ylim([0 100]);yticks(0:25:100);styleTime;
    export(f,"R2_01_Baseline_EV_"+mode,out);
end
p=F.pairs(F.pairs.TerminalMode=="none",:);p=sortrows(p,'DayID');
g=F.pairs(F.pairs.TerminalMode=="ge",:);g=sortrows(g,'DayID');
f=fig(8.8,8.5);tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
nexttile;plot(1:90,p.V2HCost_GBP,'Color',green);hold on;plot(1:90,p.V2GCost_GBP,'--','Color',orange);yline(0,':');ylabel('Daily cost (GBP)');title('(a) No EV terminal condition');styleDays;
legend('Corrected V2H','V2G','Location','northoutside','Orientation','horizontal','Box','off');
nexttile;plot(1:90,g.V2HCost_GBP,'Color',green);hold on;plot(1:90,g.V2GCost_GBP,'--','Color',orange);yline(0,':');ylabel('Daily cost (GBP)');xlabel('Chronological selected day');title('(b) EV terminal energy restored');styleDays;
export(f,'R2_02_Daily_Costs',out);
f=fig(8.8,6.5);plot(1:90,p.Saving_GBP,'Color',blue);hold on;plot(1:90,g.Saving_GBP,'--','Color',red);
scatter(find(~p.OldValidPair),p.Saving_GBP(~p.OldValidPair),14,orange,'filled');yline(0,':');styleDays;
ylabel('V2G saving (GBP/day)');xlabel('Chronological selected day');legend('No terminal condition','Terminal condition','Recovered 16 days','Location','northoutside','Box','off');
export(f,'R2_03_Daily_Saving',out);
f=fig(8.8,8.5);tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
for mode=["none","ge"]
    nexttile;hold on;co=[green;blue;red];ii=0;
    for scale=[.75 1 1.25]
        ii=ii+1;t=sortrows(T.pairs(T.pairs.TerminalMode==mode & T.pairs.ImportScale==scale,:),'ExportTariff');
        errorbar(t.ExportTariff,t.Saving_GBP,max(0,t.Saving_GBP-t.SavingLowerBound_GBP), ...
            max(0,t.SavingUpperBound_GBP-t.Saving_GBP),'Color',co(ii,:),'CapSize',2);
    end
    grid on;box on;xlim([0 .10]);xticks(0:.02:.10);ylabel('V2G saving (GBP)');
    if mode=="none",title('(a) No EV terminal condition');legend('0.75x import','1.00x import','1.25x import','Location','northwest','Box','off');else,title('(b) EV terminal energy restored');xlabel('Export tariff (GBP/kWh)');end
end
export(f,'R2_04_Reoptimised_Tariff',out);
f=fig(8.8,6);hold on;
for mode=["none","ge"]
    t=T.thresholds(T.thresholds.TerminalMode==mode,:);
    if mode=="none",c=blue;s='-o';else,c=red;s='--s';end
    errorbar(t.ImportScale,(t.OnsetLower_GBPperkWh+t.OnsetUpper_GBPperkWh)/2, ...
        (t.OnsetUpper_GBPperkWh-t.OnsetLower_GBPperkWh)/2,s,'Color',c,'MarkerSize',3);
end
grid on;box on;xticks([.75 1 1.25]);xlim([.70 1.30]);xlabel('Import-tariff multiplier');ylabel('Export onset (GBP/kWh)');legend('No terminal condition','Terminal condition','Location','northoutside','Box','off');
export(f,'R2_05_Tariff_Onset',out);
h=sortrows(A(A.Regime=="V2H",:),'DayID');a=sortrows(A(A.Regime=="V2G",:),'DayID');
f=fig(8.8,6.5);plot(1:90,h.FlatAdjustedCost_GBP-a.FlatAdjustedCost_GBP,'Color',blue);hold on;
plot(1:90,h.TOUAdjustedCost_GBP-a.TOUAdjustedCost_GBP,'--','Color',orange);
plot(1:90,h.TerminalOptimisedCost_GBP-a.TerminalOptimisedCost_GBP,':','Color',green);yline(0,'-','Color',[.4 .4 .4]);styleDays;
xlabel('Chronological selected day');ylabel('V2G saving (GBP/day)');legend('A: Flat-price accounting','B: Timed EV-only accounting','C: Terminal optimisation','Location','northoutside','Box','off');
export(f,'R2_06_Restoration_Comparison',out);
f=fig(8.8,6);C=F.allRuns;h=sortrows(C(startsWith(C.CaseID,"principal_none_") & C.Regime=="V2H",:),'DayID');a=sortrows(C(startsWith(C.CaseID,"principal_none_") & C.Regime=="V2G",:),'DayID');
bridge=[mean(h.ImportCost_GBP-a.ImportCost_GBP),mean(a.ExportRevenue_GBP-h.ExportRevenue_GBP),mean(h.BatteryDeg_GBP-a.BatteryDeg_GBP),mean(h.EVDeg_GBP-a.EVDeg_GBP),mean(h.Cost_GBP-a.Cost_GBP)];
b=barh(bridge,'FaceColor','flat');b.CData=[blue;green;orange;red;blue];yticks(1:5);yticklabels({'Import-cost change','Export-revenue change','Battery degradation','EV degradation','Net saving'});set(gca,'YDir','reverse');xline(0);grid on;box on;xlabel('Contribution to saving (GBP/day)');export(f,'R2_07_Cost_Decomposition',out);
end
function f=fig(w,h)
f=figure('Visible','off','Units','centimeters','Position',[2 2 w h]);
end
function styleTime
xlim([0 24]);xticks(0:4:24);grid on;box on;set(gca,'GridAlpha',.15,'TickDir','out');
end
function styleDays
xlim([1 90]);xticks([1 10:10:90]);grid on;box on;set(gca,'GridAlpha',.15,'TickDir','out');
end
function export(f,name,out)
drawnow;
% R2025a explicit output dimensions and padding keep labels off the crop edge.
exportgraphics(f,fullfile(out,'figures',name+".pdf"),'ContentType','vector', ...
    'Units','centimeters','Width',8.8,'Padding',.12);
exportgraphics(f,fullfile(out,'figures',name+".png"),'Resolution',600, ...
    'Units','centimeters','Width',8.8,'Padding',.12);
savefig(f,fullfile(out,'figures',name+".fig"));close(f);
end
