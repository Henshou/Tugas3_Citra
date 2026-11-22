function [labelMap, overlay, info] = semanticSegmentation(img, params)
% SEMANTICSEGMENTATION  Segmentasi semantik CamVid (11 kelas) via Python.
    tStart = tic;
    if nargin < 2, params = struct(); end
    
    here  = fileparts(mfilename('fullpath'));
    pyDir = fullfile(here, 'python');
    d = struct('pythonExe', 'python', ...
        'script',    fullfile(pyDir, 'predict.py'), ...
        'weights',   fullfile(pyDir, 'camvid_deeplabv3.pth'), ...
        'device',    'auto', ...
        'alpha',     0.5);
    f = fieldnames(d);
    for i = 1:numel(f)
        if ~isfield(params, f{i}), params.(f{i}) = d.(f{i}); end
    end
    
    if ~isfile(params.script)
        error('semanticSegmentation:noScript', 'predict.py tidak ditemukan: %s', params.script);
    end
    if ~isfile(params.weights)
        error('semanticSegmentation:noWeights', ...
            ['File bobot tidak ditemukan: %s\n' ...
            'Jalankan train.py dulu lalu salin .pth ke folder python/.'], params.weights);
    end
    
    if size(img, 3) == 1, img = repmat(img, [1 1 3]); end
    base       = tempname;
    tmpIn      = [base '_in.png'];
    tmpLabel   = [base '_label.png'];
    tmpColor   = [base '_color.png'];
    tmpOverlay = [base '_overlay.png'];
    cleaner = onCleanup(@() removeFiles({tmpIn, tmpLabel, tmpColor, tmpOverlay})); 
    imwrite(img, tmpIn);
    
    cmd = sprintf(['"%s" "%s" --weights "%s" --image "%s" --out_label "%s" ' ...
        '--out_color "%s" --out_overlay "%s" --device %s --alpha %g'], ...
        params.pythonExe, params.script, params.weights, tmpIn, ...
        tmpLabel, tmpColor, tmpOverlay, params.device, params.alpha);
    if isunix
        cmd = ['LD_LIBRARY_PATH= ' cmd];
    end
    [status, output] = system(cmd);
    if status ~= 0 || ~isfile(tmpLabel)
        error('semanticSegmentation:pythonFailed', ...
            'Python gagal dijalankan (status %d):\n%s', status, output);
    end


    labelMap = imread(tmpLabel) + 1;      
    overlay  = imread(tmpOverlay);
    
    info.classNames = {'Sky','Building','Pole','Road','Pavement','Tree', ...
        'SignSymbol','Fence','Car','Pedestrian','Bicyclist'};
    info.palette = [128 128 128; 128 0 0; 192 192 128; 128 64 128; 60 40 222; ...
        128 128 0; 192 128 128; 64 64 128; 64 0 128; 64 64 0; ...
        0 128 192] / 255;
    info.colorMask      = imread(tmpColor);
    info.classFractions = histcounts(labelMap(:), 0.5:1:11.5) / numel(labelMap);
    info.pythonOutput   = strtrim(output);
    info.time           = toc(tStart);
    end
    
    function removeFiles(list)
    for i = 1:numel(list)
        if isfile(list{i}), delete(list{i}); end
    end
end