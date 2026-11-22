function [labelMap, overlay, info] = segmentEdge(img, params)
% SEGMENTEDGE  Segmentasi objek berdasarkan hasil deteksi tepi.
    tStart = tic;
    if nargin < 2, params = struct(); end
    params = setDefaults(params);

    if ~isa(img, 'uint8'), img = im2uint8(img); end

    if size(img, 3) == 3
        c = double(img);
        gray = 0.2989*c(:,:,1) + 0.5870*c(:,:,2) + 0.1140*c(:,:,3);
    else
        gray = double(img);
    end
    gray = gray / 255;
    [H, W] = size(gray);

    [edgeMap, mag] = detectEdges(gray, params.method, params);

    bw = edgeMap;
    if params.dilateRadius > 0
        bw = imdilate(bw, strel('disk', params.dilateRadius));
    end
    if params.closeRadius > 0
        bw = imclose(bw, strel('disk', params.closeRadius));
    end
    filled = imfill(bw, 'holes');         

    if params.dilateRadius > 0
        filled = imerode(filled, strel('disk', params.dilateRadius));
    end

    minArea = round(params.minAreaFrac * H * W);
    filled  = bwareaopen(filled, max(minArea, 1));
    labelMap = bwlabel(filled, 8);
    numObjects = max(labelMap(:));

    info.edgeMap    = edgeMap;
    info.mag        = mag;
    info.filled     = filled;
    info.method     = params.method;
    info.numObjects = numObjects;
    info.mainLabel  = 0;
    info.mainMask   = false(H, W);
    info.stats      = [];

    if numObjects == 0
        warning('segmentByEdge:noObject', ...
            'Tidak ada objek ditemukan. Coba ubah threshold/sigma/closeRadius.');
        overlay = repmat(img, [1 1 3 - size(img,3) + 1]);
        overlay = overlay(:,:,1:3);
        info.time = toc(tStart);
        return;
    end

    stats = regionprops(labelMap, 'Area', 'Centroid', 'BoundingBox');
    info.stats = stats;
    info.mainLabel = pickMainObject(stats, params.select, H, W);
    info.mainMask  = (labelMap == info.mainLabel);

    overlay = makeOverlay(img, info.mainMask);
    info.time = toc(tStart);
end


% HELPER
function idx = pickMainObject(stats, mode, H, W)
    areas = [stats.Area];

    if strcmpi(mode, 'largest')
        [~, idx] = max(areas);
        return;
    end

    center  = [W H] / 2;
    maxDist = norm(center);
    score   = zeros(size(areas));
    for i = 1:numel(stats)
        d = norm(stats(i).Centroid - center) / maxDist;   
        score(i) = areas(i) * (1 - 0.5 * d);
        if areas(i) > 0.9 * H * W         
            score(i) = 0;
        end
    end
    if all(score == 0), score = areas; end  
    [~, idx] = max(score);
end

function overlay = makeOverlay(img, mask)
    if size(img, 3) == 1, img = cat(3, img, img, img); end
    rgb = double(img) / 255;

    color = [1 0 0];                       
    alpha = 0.4;
    for k = 1:3
        ch = rgb(:,:,k);
        ch(mask) = (1 - alpha) * ch(mask) + alpha * color(k);
        rgb(:,:,k) = ch;
    end

    edgeLine = bwperim(mask);                
    edgeLine = imdilate(edgeLine, strel('disk', 1));
    lineColor = [0 1 0];
    for k = 1:3
        ch = rgb(:,:,k);
        ch(edgeLine) = lineColor(k);
        rgb(:,:,k) = ch;
    end
    overlay = im2uint8(rgb);
end

function p = setDefaults(p)
    d = struct('method', 'sobel', 'sigma', 1.5, 'thresh', [], ...
               'cannyThresh', [], 'dilateRadius', 2, 'closeRadius', 4, ...
               'minAreaFrac', 0.01, 'select', 'score');
    f = fieldnames(d);
    for i = 1:numel(f)
        if ~isfield(p, f{i}), p.(f{i}) = d.(f{i}); end
    end
end