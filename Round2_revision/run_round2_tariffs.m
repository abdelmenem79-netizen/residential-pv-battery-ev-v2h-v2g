function run_round2_tariffs()
% Re-optimised export-value onset. V2G is a superset, so a zero plateau is possible.
out=fileparts(mfilename('fullpath'));root=fileparts(out);
addpath(fullfile(root,'P3_V2H_V2G_Project','config'));addpath(genpath(fullfile(root,'P3_V2H_V2G_Project','src')));
Q=load(fullfile(out,'audit','prepared_inputs_private.mat'));cfg=Q.cfg;
cfg.round2.tight=true;
cfg.round2.boundFocus=true;
I0=Q.inputs{Q.days.DayID==43598};rows=table();pairs=table();thresholds=table();
diary(fullfile(out,'logs','tariff_execution.txt'));cleanup=onCleanup(@()diary('off'));
priceGrid=unique([0:.01:.12,.15,.20,.25,.30]);tol=1e-5;priceTol=1e-4;
for mode=["none","ge"]
    for scale=[.75,1,1.25]
        local=table();
        for price=priceGrid
            coarseCfg=cfg;coarseCfg.round2.absoluteTolerance=.005;
            [pr,rr]=pair(coarseCfg,I0,mode,scale,price,out,tol);
            pairs=[pairs;pr];rows=[rows;rr];local=[local;pr]; %#ok<AGROW>
            writetable(rows,fullfile(out,'tables','tariff_runs.csv'));
            writetable(pairs,fullfile(out,'tables','tariff_pairs.csv'));
            % Threshold experiment: stop expansion after a certified positive
            % endpoint, then spend accuracy on its local bracket, not far tails.
            if pr.CertifiedPositive,break;end
        end
        assert(all(local.Valid),'Tariff pair invalid; no threshold can be certified');
        first=find(local.CertifiedPositive,1);
        lo=NaN;hi=NaN;note="No certified positive saving within tested range";
        if ~isempty(first) && first>1
            lo=local.ExportTariff(first-1);hi=local.ExportTariff(first);
            note="Local onset bracket after a zero/tolerance plateau; not a unique sign-changing root";
            while hi-lo>priceTol
                mid=(hi+lo)/2;
                [pr,rr]=pair(coarseCfg,I0,mode,scale,mid,out,tol);
                if ~pr.CertifiedPositive && pr.SavingUpperBound_GBP>tol
                    % Only ambiguous signs need tighter optimisation. Bounds
                    % that already separate the sign are sufficient proof.
                    writetable(rr,fullfile(out,'tables',"probe_"+mode+"_"+scale+"_"+compose('%.8f',mid)+".csv"));
                    [pr,rr]=pair(cfg,I0,mode,scale,mid,out,tol);
                end
                pairs=[pairs;pr];rows=[rows;rr]; %#ok<AGROW>
                assert(pr.Valid);
                if pr.CertifiedPositive
                    hi=mid;
                elseif pr.SavingUpperBound_GBP<=tol
                    lo=mid;
                else
                    note=note+"; refinement limited by certified MILP bound uncertainty";break
                end
            end
        elseif first==1
            lo=0;hi=0;note="Already positive at zero export tariff; no break-even crossing on nonnegative range";
        end
        allNow=pairs(pairs.TerminalMode==mode & pairs.ImportScale==scale,:);
        ordered=sortrows(allNow,'ExportTariff');
        observedNonmonotone=any(diff(ordered.Saving_GBP)<-1e-4);
        thresholds=[thresholds;table(mode,scale,lo,hi,hi-lo,min(I0.tariff.import)*scale, ...
            mean(I0.tariff.import)*scale,max(I0.tariff.import)*scale, ...
            min(I0.tariff.import)*scale-hi,mean(I0.tariff.import)*scale-hi, ...
            tol,observedNonmonotone,note,'VariableNames',{'TerminalMode','ImportScale', ...
            'OnsetLower_GBPperkWh','OnsetUpper_GBPperkWh','BracketWidth_GBPperkWh', ...
            'ImportOffPeak_GBPperkWh','ImportMean_GBPperkWh','ImportPeak_GBPperkWh', ...
            'OffPeakMinusOnsetUpper','MeanImportMinusOnsetUpper','SavingTolerance_GBP', ...
            'ObservedNonmonotonicity','Interpretation'})]; %#ok<AGROW>
        writetable(thresholds,fullfile(out,'tables','break_even_thresholds.csv'));
        writetable(rows,fullfile(out,'tables','tariff_runs.csv'));
        writetable(pairs,fullfile(out,'tables','tariff_pairs.csv'));
    end
end
save(fullfile(out,'Round2_tariff_results.mat'),'rows','pairs','thresholds','priceGrid','tol','priceTol','-v7.3');
fprintf('TARIFF COMPLETE: %d genuine schedule solves\n',height(rows));
end

function [p,rows]=pair(cfg,I0,mode,scale,price,out,tol)
I=I0;I.tariff.import=I0.tariff.import*scale;I.tariff.export(:)=price;rows=table();
for reg=["V2H","V2G"]
    key="tariff_"+mode+"_s"+compose('%.4f',scale)+"_p"+compose('%.8f',price)+"_"+reg;
    target=1e-8;if isfield(cfg.round2,'absoluteTolerance'),target=cfg.round2.absoluteTolerance;end
    cache=fullfile(out,'runs_certified',key+".mat");
    if isfile(cache)
        C=load(cache);
        if C.row.Valid && C.row.AbsoluteMIPGap_GBP>target+1e-8
            % Preserve lower-accuracy source files rather than overwriting
            % paths already cited by another experiment row.
            key=key+"_strict";
        end
    end
    [row,~]=runRound2Case(cfg,I,reg,mode,true,key,out);rows=[rows;row]; %#ok<AGROW>
end
h=rows(1,:);g=rows(2,:);saving=h.Cost_GBP-g.Cost_GBP;
lb=h.ObjectiveLowerBound_GBP-g.Cost_GBP;ub=h.Cost_GBP-g.ObjectiveLowerBound_GBP;
p=table(mode,scale,price,h.Cost_GBP,g.Cost_GBP,saving,lb,ub, ...
    h.Valid && g.Valid,lb>tol,'VariableNames',{'TerminalMode','ImportScale','ExportTariff', ...
    'V2HCost_GBP','V2GCost_GBP','Saving_GBP','SavingLowerBound_GBP','SavingUpperBound_GBP', ...
    'Valid','CertifiedPositive'});
end
