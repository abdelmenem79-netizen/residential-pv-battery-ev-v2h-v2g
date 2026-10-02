function status = exportFigures(FIGURES, cfg)
%EXPORTFIGURES Export figures as FIG, PNG, EPS, and PDF.

status = table('Size', [numel(FIGURES), 6], ...
    'VariableTypes', {'string','logical','logical','logical','logical','string'}, ...
    'VariableNames', {'Figure', 'SavedFIG', 'SavedPNG', 'SavedEPS', 'SavedPDF', 'Message'});

for k = 1:numel(FIGURES)
    fig = FIGURES(k).handle;
    base = char(FIGURES(k).baseName);
    status.Figure(k) = string(base);
    status.Message(k) = "";

    try
        if cfg.export.saveFig
            savefig(fig, fullfile(cfg.paths.outputs.figures.fig, [base '.fig']));
            status.SavedFIG(k) = true;
        end
        if cfg.export.savePng
            exportgraphics(fig, fullfile(cfg.paths.outputs.figures.png, [base '.png']), ...
                'Resolution', cfg.figure.dpi);
            status.SavedPNG(k) = true;
        end
        if cfg.export.savePdf
            exportgraphics(fig, fullfile(cfg.paths.outputs.figures.pdf, [base '.pdf']), ...
                'ContentType', 'vector');
            status.SavedPDF(k) = true;
        end
        if cfg.export.saveEps
            print(fig, fullfile(cfg.paths.outputs.figures.eps, [base '.eps']), ...
                '-depsc', sprintf('-r%d', cfg.figure.dpi));
            status.SavedEPS(k) = true;
        end
    catch ME
        status.Message(k) = string(ME.message);
    end
end
end

