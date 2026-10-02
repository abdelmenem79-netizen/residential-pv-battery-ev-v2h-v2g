function [cfg,days,inputs,old] = prepareRound2()
% Distributed as prepareRound2.m in the local public-release candidate.
% No raw profiles are bundled. User must supply authorised prepared inputs.
out=fileparts(mfilename('fullpath'));root=fileparts(out);p3=fullfile(root,'P3_V2H_V2G_Project');
addpath(fullfile(p3,'config'));addpath(genpath(fullfile(p3,'src')));
S=load(fullfile(out,'configuration.mat'));cfg=S.cfg;
cfg.paths.data.processedHouseData=fullfile(root,'private_inputs','House1_data_Struct.mat');
cfg.paths.data.socBattery=fullfile(root,'private_inputs','SOCFinal.xlsx');
cfg.paths.data.socEV=fullfile(root,'private_inputs','SOCFinalEV.xlsx');
required=[string(cfg.paths.data.processedHouseData),string(cfg.paths.data.socBattery), ...
    string(cfg.paths.data.socEV),string(fullfile(root,'private_inputs','Total_Data_house1.xlsx'))];
assert(all(isfile(required)),'Supply all four authorised prepared input files in private_inputs. No synthetic fallback is used.');
H=load(required(1));H=H.House1_data_Struct;A=readmatrix(required(4));
assert(isequaln(A(:,1:4),[H.DayNum,H.Day,H.Month,H.Year]));
assert(isequaln(A(:,7:8),[H.PV1,H.PL1]));
days=readtable(fullfile(out,'selected_days.csv'),'TextType','string');inputs=cell(height(days),1);
for n=1:height(days)
    id=days.DayID(n);ix=find(floor(H.DayNum)==id);assert(numel(ix)==144);
    stamp=unique([H.Year(ix),H.Month(ix),H.Day(ix)],'rows');assert(size(stamp,1)==1);
    date=string(datetime(stamp(1),stamp(2),stamp(3),'Format','yyyy-MM-dd'));
    assert(date==days.CalendarDate(n));dc=cfg;dc.case.date=id;I=prepareInputs(dc);
    assert(max(abs(I.P_load-max(.01,abs(H.PL1(ix)))))<1e-12);
    assert(max(abs(I.P_pv-abs(H.PV1(ix))))<1e-12);
    I.metadata.calendarDate=date;I.metadata.calendarDateVerified=true;inputs{n}=I;
end
b=days(days.DayID==43598,:);old.baseline.RESULTS.V2H.cost.total=b.OldV2HCost_GBP;
old.baseline.RESULTS.V2G.cost.total=b.OldV2GCost_GBP;
if ~isfolder(fullfile(out,'audit')),mkdir(fullfile(out,'audit'));end
writetable(days,fullfile(out,'audit','verified_days.csv'));
save(fullfile(out,'audit','prepared_inputs_private.mat'),'cfg','days','inputs','-v7.3');
end
