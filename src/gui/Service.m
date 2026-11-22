classdef Service < handle
    methods
        function [edgeImage, info] = detectEdges(~, img, methodName, threshold)
            grayImage = im2gray(im2double(img));
            switch methodName
                case 'Sobel'
                    edgeImage = edge(grayImage, 'Sobel', threshold);
                case 'Prewitt'
                    edgeImage = edge(grayImage, 'Prewitt', threshold);
                case 'Canny'
                    edgeImage = edge(grayImage, 'Canny', threshold);
                case 'Laplacian'
                    edgeImage = edge(grayImage, 'log', threshold);
                case 'Roberts'
                    edgeImage = edge(grayImage, 'Roberts', threshold);
                otherwise
                    error('Metode deteksi tepi tidak dikenali.');
            end
            edgeImage = uint8(edgeImage) * 255;
            pixelCount = nnz(edgeImage);
            info = {
                ['Metode: ' methodName]
                sprintf('Threshold: %.3f', threshold)
                sprintf('Edge pixels: %d', pixelCount)
                sprintf('Edge coverage: %.2f%%', 100 * pixelCount / numel(edgeImage))
            };
        end

        function overlay = makeEdgeOverlay(~, img, edgeImage)
            rgb = im2uint8(img);
            if size(rgb, 3) == 1
                rgb = repmat(rgb, [1 1 3]);
            end
            mask = edgeImage > 0;
            overlay = rgb;
            overlay(:, :, 1) = max(overlay(:, :, 1), uint8(mask) * 255);
            overlay(:, :, 2) = overlay(:, :, 2) .* uint8(~mask);
            overlay(:, :, 3) = overlay(:, :, 3) .* uint8(~mask);
        end

        function [result, overlay, info] = splitAndMerge(obj, img, minSize, mergeThreshold)
            grayImage = im2gray(im2double(img));
            [labels, meanImage] = obj.quadtreeSplit(grayImage, round(minSize), mergeThreshold);
            result = im2uint8(meanImage);
            cmap = turbo(max(labels(:)));
            rgbLabels = label2rgb(labels, cmap, 'k');
            if size(img, 3) == 1
                base = repmat(im2uint8(img), [1 1 3]);
            else
                base = im2uint8(img);
            end
            overlay = imfuse(base, rgbLabels, 'blend', 'Scaling', 'joint');
            info = {
                'Metode: Quadtree Split and Merge'
                sprintf('Ukuran minimum region: %d', round(minSize))
                sprintf('Threshold merge: %.3f', mergeThreshold)
                sprintf('Jumlah region: %d', max(labels(:)))
            };
        end

        function [output, overlay, info] = semanticSegment(~, img, modelPath)
            [~, ~, extension] = fileparts(modelPath);
            try
                if strcmpi(extension, '.onnx')
                    if exist('importONNXNetwork', 'file') ~= 2
                        error('importONNXNetwork tidak tersedia pada instalasi MATLAB ini.');
                    end
                    net = importONNXNetwork(modelPath);
                else
                    data = load(modelPath);
                    names = fieldnames(data);
                    netNames = {'net', 'network', 'lgraph', 'dlnetwork'};
                    net = [];
                    for i = 1:numel(netNames)
                        if isfield(data, netNames{i}), net = data.(netNames{i}); break; end
                    end
                    if isempty(net) && numel(names) == 1
                        net = data.(names{1});
                    end
                end
            catch ME
                error('Gagal memuat model: %s', ME.message);
            end
            if isempty(net)
                error('File model tidak memiliki variabel net/network/lgraph.');
            end
            if exist('semanticseg', 'file') ~= 2
                error('Deep Learning semanticseg belum tersedia pada instalasi MATLAB ini.');
            end

            [height, width, ~] = size(img);
            if isa(net, 'DAGNetwork') || isa(net, 'SeriesNetwork')
                inputSize = net.Layers(1).InputSize(1:2);
            elseif isa(net, 'dlnetwork')
                inputSize = [height width];
            else
                error('Format jaringan tidak dikenali. Gunakan MATLAB DAGNetwork/SeriesNetwork atau dlnetwork.');
            end
            resized = imresize(img, [inputSize(1) inputSize(2)]);
            C = semanticseg(resized, net);
            mask = imresize(uint8(C ~= C(1,1)), [height width], 'nearest');
            output = mask * 255;
            rgb = im2uint8(img);
            if size(rgb, 3) == 1, rgb = repmat(rgb, [1 1 3]); end
            overlay = rgb;
            overlay(:, :, 1) = max(overlay(:, :, 1), mask * 255);
            overlay(:, :, 2) = overlay(:, :, 2) .* uint8(~mask);
            overlay(:, :, 3) = overlay(:, :, 3) .* uint8(~mask);
            info = {
                'Metode: Semantic Segmentation'
                ['Model: ' modelPath]
                sprintf('Ukuran output: %d x %d', height, width)
                sprintf('Jumlah foreground pixels: %d', nnz(mask))
            };
        end
    end

    methods (Access = private)
        function [labels, meanImage] = quadtreeSplit(~, grayImage, minSize, mergeThreshold)
            [height, width] = size(grayImage);
            meanImage = zeros(height, width);
            labels = zeros(height, width);
            regionId = 0;

            function splitBlock(r1, r2, c1, c2)
                block = grayImage(r1:r2, c1:c2);
                bh = r2 - r1 + 1;
                bw = c2 - c1 + 1;
                homogeneous = std(block(:)) <= mergeThreshold;
                canSplit = bh > minSize && bw > minSize;
                if homogeneous || ~canSplit
                    regionId = regionId + 1;
                    labels(r1:r2, c1:c2) = regionId;
                    meanImage(r1:r2, c1:c2) = mean(block(:));
                else
                    rm = floor((r1 + r2) / 2);
                    cm = floor((c1 + c2) / 2);
                    splitBlock(r1, rm, c1, cm);
                    splitBlock(r1, rm, cm + 1, c2);
                    splitBlock(rm + 1, r2, c1, cm);
                    splitBlock(rm + 1, r2, cm + 1, c2);
                end
            end

            splitBlock(1, height, 1, width);

            means = zeros(regionId, 1);
            for id = 1:regionId
                means(id) = mean(grayImage(labels == id));
            end
            for id1 = 1:regionId
                if ~any(labels(:) == id1), continue; end
                for id2 = id1 + 1:regionId
                    if ~any(labels(:) == id2), continue; end
                    if abs(means(id1) - means(id2)) <= mergeThreshold
                        m1 = labels == id1;
                        m2 = labels == id2;
                        if exist('imdilate', 'file') == 2
                            adjacent = any(m2 & imdilate(m1, ones(3)));
                        else
                            expanded = padarray(m1, [1 1], 0);
                            expanded = expanded(1:end-2, 1:end-2) | ...
                                expanded(2:end-1, 1:end-2) | expanded(3:end, 1:end-2) | ...
                                expanded(1:end-2, 2:end-1) | expanded(3:end, 2:end-1) | ...
                                expanded(1:end-2, 3:end) | expanded(2:end-1, 3:end) | expanded(3:end, 3:end);
                            adjacent = any(m2(:) & expanded(:));
                        end
                        if adjacent
                            labels(m2) = id1;
                            means(id1) = mean(grayImage(labels == id1));
                        end
                    end
                end
            end

            uniqueLabels = unique(labels(:));
            remap = zeros(size(labels));
            meanImage = zeros(size(grayImage));
            for newId = 1:numel(uniqueLabels)
                oldId = uniqueLabels(newId);
                mask = labels == oldId;
                remap(mask) = newId;
                meanImage(mask) = mean(grayImage(mask));
            end
            labels = remap;
        end
    end
end
