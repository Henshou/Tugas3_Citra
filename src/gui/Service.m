classdef Service < handle
    methods
        function [edgeMap, magnitude, info] = runEdgeDetection(~, img, method, params)
            grayImage = im2gray(im2double(img));
            [edgeMap, magnitude, info] = detectEdges(grayImage, lower(method), params);
        end

        function overlay = makeEdgeOverlay(~, img, edgeMap)
            rgb = im2uint8(img);
            if size(rgb, 3) == 1, rgb = repmat(rgb, [1 1 3]); end
            mask = logical(edgeMap);
            overlay = rgb(:, :, 1:3);
            red = overlay(:, :, 1);
            green = overlay(:, :, 2);
            blue = overlay(:, :, 3);
            red(mask) = 255;
            green(mask) = 0;
            blue(mask) = 0;
            overlay(:, :, 1) = red;
            overlay(:, :, 2) = green;
            overlay(:, :, 3) = blue;
        end

        function colorMap = colorizeLabels(~, labelMap)
            regionCount = max(labelMap(:));
            if regionCount == 0
                colorMap = zeros([size(labelMap), 3], 'uint8');
            else
                colorMap = label2rgb(labelMap, turbo(regionCount), 'k', 'shuffle');
            end
        end

        function [labelMap, overlay, info] = segmentByEdges(~, img, params)
            [labelMap, overlay, info] = segmentEdge(img, params);
        end

        function [labelMap, segmentedImage, overlay, info] = splitAndMerge(~, img, params)
            [labelMap, segmentedImage, overlay, info] = splitMerge(img, params);
        end

        function [labelMap, overlay, info] = semanticSegment(~, img, params)
            [labelMap, overlay, info] = semanticSegmentation(img, params);
        end

        function infoLines = formatEdgeInfo(~, info, edgeMap)
            infoLines = {
                ['Metode: ' upper(info.method)]
                sprintf('Sigma: %.2f', info.sigma)
                sprintf('Piksel tepi: %d', nnz(edgeMap))
                sprintf('Cakupan tepi: %.2f%%', 100 * nnz(edgeMap) / numel(edgeMap))
            };
        end

        function infoLines = formatSegmentInfo(~, info)
            infoLines = {
                ['Metode: ' info.method]
                sprintf('Sigma: %.2f', info.sigma)
                sprintf('Threshold: %.2f', info.thresh)
                sprintf('Jumlah objek: %d', info.numObjects)
                sprintf('Objek utama: %d', info.mainLabel)
                sprintf('Waktu: %.2f detik', info.time)
            };
        end

        function infoLines = formatSplitMergeInfo(~, info)
            infoLines = {
                ['Metode: ' info.method]
                sprintf('Region setelah split: %d', info.splitRegionCount)
                sprintf('Region setelah merge: %d', info.regionCount)
                sprintf('Jumlah penggabungan: %d', info.mergeCount)
                sprintf('Ukuran minimum: %d px', info.minSize)
                sprintf('Threshold split (std gray): %.3f', info.splitThreshold)
                sprintf('Threshold merge (RMS mean RGB): %.3f', info.mergeThreshold)
                sprintf('Waktu: %.2f detik', info.time)
            };
        end

        function infoLines = formatSemanticInfo(~, info)
            infoLines = {
                'Metode: Semantic Segmentation (CamVid)'
                sprintf('Jumlah kelas: %d', numel(info.classNames))
                sprintf('Waktu: %.2f detik', info.time)
            };
        end
    end
end
