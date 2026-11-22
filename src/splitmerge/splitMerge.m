function [labelMap, segmentedImage, overlay, info] = splitMerge(img, params)
%SPLITMERGE Segmentasi citra dengan quadtree split dan region merging.
%   Predikat split: simpangan baku intensitas grayscale sebuah blok harus
%   <= splitThreshold. Blok yang tidak homogen dibagi secara rekursif.
%   Predikat merge: dua region bertetangga digabung jika RMS distance dari
%   rerata warna RGB ternormalisasi keduanya <= mergeThreshold.
%
%   Semua threshold berada pada rentang [0, 1]. Untuk citra grayscale,
%   fitur warna RGB direplikasi dari intensitas grayscale.

    tStart = tic;
    if nargin < 2 || isempty(params)
        params = struct();
    end
    params = setDefaults(params);

    validateattributes(params.minSize, {'numeric'}, ...
        {'scalar', 'finite', 'integer', 'positive'}, mfilename, 'params.minSize');
    validateattributes(params.splitThreshold, {'numeric'}, ...
        {'scalar', 'finite', 'nonnegative', '<=', 1}, mfilename, 'params.splitThreshold');
    validateattributes(params.mergeThreshold, {'numeric'}, ...
        {'scalar', 'finite', 'nonnegative', '<=', 1}, mfilename, 'params.mergeThreshold');

    if isempty(img) || ndims(img) > 3
        error('splitMerge:invalidImage', 'Citra masukan kosong atau memiliki dimensi yang tidak didukung.');
    end

    % Normalisasi data ke [0,1] agar threshold tidak bergantung pada tipe citra.
    baseImage = im2double(img);
    if size(baseImage, 3) == 4
        baseImage = baseImage(:, :, 1:3);
    end
    if size(baseImage, 3) ~= 1 && size(baseImage, 3) ~= 3
        error('splitMerge:invalidChannels', 'Citra harus grayscale atau RGB.');
    end
    if any(~isfinite(baseImage(:)))
        error('splitMerge:invalidPixels', 'Citra mengandung nilai NaN atau Inf.');
    end
    baseImage = min(max(baseImage, 0), 1);

    [height, width, channels] = size(baseImage);
    if height < 1 || width < 1
        error('splitMerge:invalidSize', 'Ukuran citra tidak valid.');
    end

    if channels == 1
        grayImage = baseImage;
        featureImage = repmat(baseImage, [1 1 3]);
        displayImage = featureImage;
    else
        displayImage = baseImage;
        featureImage = baseImage;
        grayImage = 0.2989 * baseImage(:, :, 1) + ...
                    0.5870 * baseImage(:, :, 2) + ...
                    0.1140 * baseImage(:, :, 3);
    end

    % Tahap 1: quadtree split. Pemotongan dilakukan pada kedua sumbu jika
    % memungkinkan, atau hanya pada sumbu yang masih cukup besar.
    splitLabelMap = zeros(height, width);
    splitRegionCount = 0;
    splitBlock(1, height, 1, width);

    % Simpan fitur rerata dan ukuran setiap leaf region untuk tahap merge.
    splitLabels = splitLabelMap(:);
    regionSizes = accumarray(splitLabels, 1, [splitRegionCount 1]);
    regionMeans = zeros(splitRegionCount, 3);
    for channel = 1:3
        plane = featureImage(:, :, channel);
        regionMeans(:, channel) = accumarray(splitLabels, plane(:), ...
            [splitRegionCount 1], @mean);
    end

    % Tahap 2: bentuk graf adjacency 4-arah dari region hasil split.
    % Union-find memastikan region yang telah digabung tetap direferensikan
    % sebagai satu komponen saat pasangan tetangga berikutnya diperiksa.
    adjacentPairs = findAdjacentPairs(splitLabelMap);
    parent = 1:splitRegionCount;
    changed = true;
    while changed
        changed = false;
        for pairId = 1:size(adjacentPairs, 1)
            regionA = findRoot(parent, adjacentPairs(pairId, 1));
            regionB = findRoot(parent, adjacentPairs(pairId, 2));
            if regionA == regionB
                continue;
            end

            colorDistance = sqrt(mean((regionMeans(regionA, :) - ...
                                       regionMeans(regionB, :)).^2));
            if colorDistance > params.mergeThreshold
                continue;
            end

            % Pertahankan root dengan ukuran lebih besar, lalu perbarui
            % rerata warna berbobot agar keputusan merge berikutnya konsisten.
            if regionSizes(regionA) < regionSizes(regionB)
                temp = regionA;
                regionA = regionB;
                regionB = temp;
            end
            totalSize = regionSizes(regionA) + regionSizes(regionB);
            regionMeans(regionA, :) = ...
                (regionMeans(regionA, :) * regionSizes(regionA) + ...
                 regionMeans(regionB, :) * regionSizes(regionB)) / totalSize;
            regionSizes(regionA) = totalSize;
            parent(regionB) = regionA;
            changed = true;
        end
    end

    % Kompresi label akhir menjadi 1..N tanpa celah.
    roots = zeros(splitRegionCount, 1);
    for regionId = 1:splitRegionCount
        roots(regionId) = findRoot(parent, regionId);
    end
    [~, ~, compactLabels] = unique(roots);
    labelMap = reshape(compactLabels(splitLabelMap(:)), height, width);
    regionCount = max(labelMap(:));

    % Citra segmentasi akhir: setiap piksel diganti dengan rerata regionnya.
    segmentedRGB = zeros(height, width, 3);
    finalLabels = labelMap(:);
    for channel = 1:3
        plane = featureImage(:, :, channel);
        means = accumarray(finalLabels, plane(:), [regionCount 1], @mean);
        segmentedRGB(:, :, channel) = reshape(means(finalLabels), height, width);
    end
    if channels == 1
        segmentedImage = mean(segmentedRGB, 3);
    else
        segmentedImage = segmentedRGB;
    end

    % Visualisasi split memakai warna region berbeda; overlay akhir memadukan
    % label hasil merge dengan citra asli dan menandai batas antar-region.
    splitVisualization = labelsToRGB(splitLabelMap);
    mergedColorMap = labelsToRGB(labelMap);
    overlay = makeOverlay(displayImage, mergedColorMap, labelMap);

    info.method = 'Quadtree split and region merge';
    info.minSize = params.minSize;
    info.splitThreshold = params.splitThreshold;
    info.mergeThreshold = params.mergeThreshold;
    info.splitRegionCount = splitRegionCount;
    info.regionCount = regionCount;
    info.mergeCount = splitRegionCount - regionCount;
    info.splitLabelMap = splitLabelMap;
    info.splitVisualization = splitVisualization;
    info.segmentedImage = segmentedImage;
    info.mergeVisualization = mergedColorMap;
    info.splitPredicate = 'Simpangan baku intensitas grayscale blok <= threshold split';
    info.mergePredicate = 'RMS distance rerata RGB region bertetangga <= threshold merge';
    info.time = toc(tStart);

    function splitBlock(rowStart, rowEnd, colStart, colEnd)
        block = grayImage(rowStart:rowEnd, colStart:colEnd);
        blockHeight = rowEnd - rowStart + 1;
        blockWidth = colEnd - colStart + 1;
        isHomogeneous = std(block(:), 1) <= params.splitThreshold;

        % Sebuah sumbu hanya dibelah jika kedua hasil potongannya dapat
        % memenuhi batas ukuran minimum. Blok persegi panjang tetap didukung.
        canSplitRows = blockHeight >= 2 * params.minSize;
        canSplitCols = blockWidth >= 2 * params.minSize;
        if isHomogeneous || (~canSplitRows && ~canSplitCols)
            splitRegionCount = splitRegionCount + 1;
            splitLabelMap(rowStart:rowEnd, colStart:colEnd) = splitRegionCount;
            return;
        end

        if canSplitRows
            rowMid = floor((rowStart + rowEnd) / 2);
        end
        if canSplitCols
            colMid = floor((colStart + colEnd) / 2);
        end

        if canSplitRows && canSplitCols
            splitBlock(rowStart, rowMid, colStart, colMid);
            splitBlock(rowStart, rowMid, colMid + 1, colEnd);
            splitBlock(rowMid + 1, rowEnd, colStart, colMid);
            splitBlock(rowMid + 1, rowEnd, colMid + 1, colEnd);
        elseif canSplitRows
            splitBlock(rowStart, rowMid, colStart, colEnd);
            splitBlock(rowMid + 1, rowEnd, colStart, colEnd);
        else
            splitBlock(rowStart, rowEnd, colStart, colMid);
            splitBlock(rowStart, rowEnd, colMid + 1, colEnd);
        end
    end
end

function pairs = findAdjacentPairs(labelMap)
% Temukan semua pasangan region bertetangga secara horizontal/vertikal.
    horizontalA = labelMap(:, 1:end-1);
    horizontalB = labelMap(:, 2:end);
    verticalA = labelMap(1:end-1, :);
    verticalB = labelMap(2:end, :);
    pairs = [horizontalA(:), horizontalB(:); verticalA(:), verticalB(:)];
    if isempty(pairs)
        pairs = zeros(0, 2);
        return;
    end
    pairs = pairs(pairs(:, 1) ~= pairs(:, 2), :);
    pairs = unique(sort(pairs, 2), 'rows');
end

function root = findRoot(parent, node)
% Temukan root komponen union-find.
    root = node;
    while parent(root) ~= root
        root = parent(root);
    end
end

function rgb = labelsToRGB(labelMap)
% Buat peta warna deterministik tanpa mengacak warna antar-pemanggilan.
    numberOfLabels = max(labelMap(:));
    palette = hsv(max(numberOfLabels, 1));
    [height, width] = size(labelMap);
    rgb = zeros(height, width, 3);
    for channel = 1:3
        plane = reshape(palette(labelMap(:), channel), height, width);
        rgb(:, :, channel) = plane;
    end
end

function overlay = makeOverlay(baseImage, colorMap, labelMap)
% Paduan warna hasil merge dengan citra asli, disertai garis batas region.
    baseRGB = baseImage;
    if size(baseRGB, 3) == 1
        baseRGB = repmat(baseRGB, [1 1 3]);
    end
    blended = 0.55 * baseRGB + 0.45 * colorMap;

    boundary = false(size(labelMap));
    if size(labelMap, 2) > 1
        different = labelMap(:, 1:end-1) ~= labelMap(:, 2:end);
        boundary(:, 1:end-1) = boundary(:, 1:end-1) | different;
        boundary(:, 2:end) = boundary(:, 2:end) | different;
    end
    if size(labelMap, 1) > 1
        different = labelMap(1:end-1, :) ~= labelMap(2:end, :);
        boundary(1:end-1, :) = boundary(1:end-1, :) | different;
        boundary(2:end, :) = boundary(2:end, :) | different;
    end

    overlay = im2uint8(blended);
    for channel = 1:3
        plane = overlay(:, :, channel);
        plane(boundary) = 255;
        overlay(:, :, channel) = plane;
    end
end

function params = setDefaults(params)
    defaults = struct('minSize', 8, 'splitThreshold', 0.05, 'mergeThreshold', 0.05);
    names = fieldnames(defaults);
    for i = 1:numel(names)
        if ~isfield(params, names{i}) || isempty(params.(names{i}))
            params.(names{i}) = defaults.(names{i});
        end
    end
end
