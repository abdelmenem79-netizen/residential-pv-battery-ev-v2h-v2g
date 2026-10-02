function run_round2_principal()
out=fileparts(mfilename('fullpath'));
for d=["runs_certified","logs_certified","tables","figures"],if ~isfolder(fullfile(out,d)),mkdir(fullfile(out,d));end,end
diary(fullfile(out,'logs_certified','principal_execution.txt'));cleanup=onCleanup(@()diary('off'));
[cfg,days,inputs,old]=prepareRound2();
base=find(days.DayID==43598);rows=table();
% Genuine unmodified baseline reproduction before changed-constraint runs.
for reg=["V2H","V2G"]
    [row,~]=runRound2Case(cfg,inputs{base},reg,"none",false,"control_43598_"+reg,out);
    assert(row.Valid);expected=old.baseline.RESULTS.(reg).cost.total;
    fprintf('Saved-default to certified baseline change: %.9f GBP\n',row.Cost_GBP-expected);
    rows=[rows;row]; %#ok<AGROW>
end
% Fresh uncapped controls separate reserve-policy change from solver accuracy.
for n=1:height(days)
    for reg=["V2H","V2G"]
        [row,~]=runRound2Case(cfg,inputs{n},reg,"none",false,"uncapped_"+days.DayID(n)+"_"+reg,out);
        rows=[rows;row]; %#ok<AGROW>
        writetable(rows,fullfile(out,'tables','certified_principal_runs.csv'));
    end
end
% All 90 days, both regimes, both boundary conditions; no failed-day exclusion.
for mode=["none","ge"]
    for n=1:height(days)
        for reg=["V2H","V2G"]
            [row,~]=runRound2Case(cfg,inputs{n},reg,mode,true,"principal_"+mode+"_"+days.DayID(n)+"_"+reg,out);
            rows=[rows;row]; %#ok<AGROW>
            writetable(rows,fullfile(out,'tables','certified_principal_runs.csv'));
        end
    end
end
% Equality sensitivity on 20 deterministic chronological coverage days plus baseline.
eqIdx=unique([round(linspace(1,90,20)),base]);
for n=eqIdx
    for reg=["V2H","V2G"]
        [row,~]=runRound2Case(cfg,inputs{n},reg,"eq",true,"equality_"+days.DayID(n)+"_"+reg,out);
        rows=[rows;row]; %#ok<AGROW>
        writetable(rows,fullfile(out,'tables','certified_principal_runs.csv'));
    end
end
save(fullfile(out,'Round2_principal_results.mat'),'rows','days','cfg','eqIdx','-v7.3');
fprintf('PRINCIPAL COMPLETE: attempted %d; validation passed %d\n',height(rows),sum(rows.Valid));
end
