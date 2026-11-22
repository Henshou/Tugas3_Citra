classdef App < handle
    properties (Access = private)
        RootFolder char
        UI Layout
        Service Service
        ImgInput
        ImgEdgeMap
        ImgOutput
        ImgOverlay
        ModelPath char = ''
    end

    methods
        function obj = App(rootFolder)
            obj.RootFolder = rootFolder;
            obj.Service = Service();
            obj.UI = Layout(@(~,~) obj.delete());
            obj.bindEvents();
            obj.onCategoryChanged();
        end

        function delete(obj)
            if ~isempty(obj.UI) && isvalid(obj.UI), delete(obj.UI); end
        end
    end

    methods (Access = private)
        function bindEvents(obj)
            obj.UI.BtnLoad.ButtonPushedFcn = @(~,~) obj.loadImage();
            obj.UI.BtnRun.ButtonPushedFcn = @(~,~) obj.run();
            obj.UI.BtnReset.ButtonPushedFcn = @(~,~) obj.resetGui();
            obj.UI.BtnHistogram.ButtonPushedFcn = @(~,~) obj.UI.showHistogram(obj.ImgInput);
            obj.UI.BtnModel.ButtonPushedFcn = @(~,~) obj.loadModel();
            obj.UI.MenuCategory.ValueChangedFcn = @(~,~) obj.onCategoryChanged();
            obj.UI.MenuMethod.ValueChangedFcn = @(~,~) obj.onMethodChanged();
        end

        function loadImage(obj)
            % Mulai dari folder delapan citra uji BSDS500 yang disertakan.
            startDir = fullfile(obj.RootFolder, 'data', 'bsds500_test_8');
            if ~isfolder(startDir), startDir = obj.RootFolder; end
            [fileName, folderName] = uigetfile( ...
                {'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', 'Image files'}, ...
                'Pilih Citra Input', startDir);
            if isequal(fileName, 0), return; end

            [img, colorMap] = imread(fullfile(folderName, fileName));
            if ~isempty(colorMap), img = im2uint8(ind2rgb(img, colorMap)); end
            if size(img, 3) == 4, img = img(:, :, 1:3); end
            obj.ImgInput = img;
            obj.ImgEdgeMap = [];
            obj.ImgOutput = [];
            obj.ImgOverlay = [];
            imshow(obj.ImgInput, 'Parent', obj.UI.AxInput);
            cla(obj.UI.AxEdge);
            cla(obj.UI.AxOutput);
            cla(obj.UI.AxOverlay);
            obj.UI.setVisualizationTitles('Citra Masukan', 'Hasil Pemrosesan', 'Hasil / Overlay');
            obj.UI.LblStatus.Text = ['Citra dimuat: ' fileName];
            obj.updateInfo({
                ['Input: ' fileName]
                sprintf('Ukuran: %d x %d', size(img, 1), size(img, 2))
                sprintf('Tipe data: %s', class(img))
            });
        end

        function loadModel(obj)
            [fileName, folderName] = uigetfile({'*.pth', 'Model PyTorch (*.pth)'}, ...
                'Pilih bobot model semantic segmentation');
            if isequal(fileName, 0), return; end
            obj.ModelPath = fullfile(folderName, fileName);
            obj.UI.LblModel.Text = ['Bobot: ' fileName];
            obj.UI.LblStatus.Text = 'Bobot model dipilih.';
        end

        function onCategoryChanged(obj)
            category = obj.UI.MenuCategory.Value;
            obj.UI.configureCategory(category);
            obj.UI.configureVisualization(category);
            cla(obj.UI.AxEdge);
            cla(obj.UI.AxOutput);
            cla(obj.UI.AxOverlay);
            if strcmp(category, 'Segmentasi Berbasis Tepi')
                obj.UI.setEdgeVisualizationTitles('Citra Masukan', 'Peta Deteksi Tepi', ...
                    'Label Objek', 'Overlay Objek Utama');
            else
                obj.UI.setVisualizationTitles('Citra Masukan', 'Hasil Pemrosesan', ...
                    'Hasil / Overlay');
            end
            switch category
                case 'Segmentasi Berbasis Tepi'
                    obj.UI.setMethodItems({'Sobel', 'Prewitt', 'Roberts', 'Laplace', 'LoG', 'Canny'});
                case 'Split and Merge'
                    obj.UI.setMethodItems({'Quadtree Split and Merge'});
                otherwise
                    obj.UI.setMethodItems({'Semantic Segmentation (CamVid)'});
            end
            obj.onMethodChanged();
        end

        function onMethodChanged(obj)
            isCanny = strcmpi(obj.UI.MenuMethod.Value, 'Canny');
            obj.UI.configureEdgeMethod(isCanny);
        end

        function run(obj)
            if isempty(obj.ImgInput)
                uialert(obj.UI.Fig, 'Silakan pilih citra input terlebih dahulu.', 'Citra Belum Dipilih');
                return;
            end

            obj.UI.LblStatus.Text = 'Memproses citra...';
            obj.UI.BtnRun.Enable = 'off';
            drawnow;
            try
                obj.UI.setVisualizationTitles('Citra Masukan', 'Mask / Label Segmen', ...
                    'Overlay / Hasil Segmentasi');
                switch obj.UI.MenuCategory.Value
                    case 'Segmentasi Berbasis Tepi'
                        params = obj.edgeParams();
                        params.method = lower(obj.UI.MenuMethod.Value);
                        params.dilateRadius = obj.UI.TxtDilateRadius.Value;
                        params.closeRadius = obj.UI.TxtCloseRadius.Value;
                        params.minAreaFrac = obj.parseValue(obj.UI.TxtMinArea.Value, ...
                            'Luas minimum', 0, 1);
                        params.select = obj.UI.MenuSelect.Value;
                        [labelMap, overlay, segmentInfo] = ...
                            obj.Service.segmentByEdges(obj.ImgInput, params);
                        obj.ImgEdgeMap = segmentInfo.edgeMap;
                        obj.ImgOutput = obj.Service.colorizeLabels(labelMap);
                        obj.ImgOverlay = overlay;
                        obj.updateInfo(obj.Service.formatSegmentInfo(segmentInfo));
                    case 'Split and Merge'
                        params = struct( ...
                            'minSize', obj.UI.TxtMinSize.Value, ...
                            'splitThreshold', obj.parseValue(obj.UI.TxtSplitThreshold.Value, ...
                                'Threshold split', 0, 1), ...
                            'mergeThreshold', obj.parseValue(obj.UI.TxtMerge.Value, ...
                                'Threshold merge', 0, 1));
                        [~, ~, overlay, splitInfo] = ...
                            obj.Service.splitAndMerge(obj.ImgInput, params);
                        % Panel output memperlihatkan hasil split sebelum merge;
                        % panel overlay memperlihatkan hasil akhir setelah merge.
                        obj.ImgOutput = splitInfo.splitVisualization;
                        obj.ImgOverlay = overlay;
                        obj.UI.setVisualizationTitles('Citra Masukan', ...
                            'Setelah Split (Quadtree)', 'Setelah Merge (Overlay)');
                        obj.updateInfo(obj.Service.formatSplitMergeInfo(splitInfo));
                    otherwise
                        params = struct( ...
                            'pythonExe', 'python', ...
                            'device', strtrim(obj.UI.TxtDevice.Value), ...
                            'alpha', obj.parseValue(obj.UI.TxtAlpha.Value, 'Alpha overlay', 0, 1));
                        if ~isempty(obj.ModelPath), params.weights = obj.ModelPath; end
                        [~, overlay, semanticInfo] = ...
                            obj.Service.semanticSegment(obj.ImgInput, params);
                        obj.ImgOutput = semanticInfo.colorMask;
                        obj.ImgOverlay = overlay;
                        obj.updateInfo(obj.Service.formatSemanticInfo(semanticInfo));
                end

                imshow(obj.ImgOutput, 'Parent', obj.UI.AxOutput);
                imshow(obj.ImgOverlay, 'Parent', obj.UI.AxOverlay);
                if strcmp(obj.UI.MenuCategory.Value, 'Segmentasi Berbasis Tepi')
                    imshow(obj.ImgEdgeMap, 'Parent', obj.UI.AxEdge);
                    obj.UI.setEdgeVisualizationTitles('Citra Masukan', ...
                        ['Peta Tepi (' upper(segmentInfo.method) ')'], ...
                        'Hasil Segmentasi', 'Overlay Objek Utama');
                elseif strcmp(obj.UI.MenuCategory.Value, 'Split and Merge')
                    obj.UI.setVisualizationTitles('Citra Masukan', ...
                        'Setelah Split (Quadtree)', 'Setelah Merge (Overlay)');
                else
                    obj.UI.setVisualizationTitles('Citra Masukan', ...
                        'Peta Kelas Semantik', 'Overlay Semantic Segmentation');
                end
                obj.UI.LblStatus.Text = 'Pemrosesan selesai.';
            catch ME
                uialert(obj.UI.Fig, ME.message, 'Kesalahan Pemrosesan');
                obj.UI.LblStatus.Text = ['Error: ' ME.message];
            end
            obj.UI.BtnRun.Enable = 'on';
        end

        function params = edgeParams(obj)
            method = lower(obj.UI.MenuMethod.Value);
            threshold = [];
            cannyThreshold = [];
            if strcmp(method, 'canny')
                cannyThreshold = obj.parseCannyThreshold(obj.UI.TxtCannyThreshold.Value);
            else
                threshold = obj.parseOptionalThreshold(obj.UI.TxtThreshold.Value, 'Threshold');
            end
            params = struct('sigma', obj.UI.TxtSigma.Value, ...
                'thresh', threshold, 'cannyThresh', cannyThreshold);
        end

        function value = parseOptionalThreshold(obj, text, label)
            if isempty(strtrim(text))
                value = [];
            else
                value = obj.parseValue(text, label, 0, 1);
            end
        end

        function value = parseCannyThreshold(obj, text)
            text = strtrim(text);
            if isempty(text)
                value = [];
                return;
            end
            text = strrep(strrep(text, '[', ' '), ']', ' ');
            tokens = strsplit(strtrim(text));
            value = cellfun(@str2double, tokens);
            if numel(value) ~= 2 || any(~isfinite(value)) || ...
                    value(1) < 0 || value(2) > 1 || value(1) >= value(2)
                error('Canny threshold harus kosong atau berupa [low high] dengan 0 <= low < high <= 1.');
            end
        end

        function value = parseValue(~, text, label, minValue, maxValue)
            value = str2double(text);
            if ~isscalar(value) || ~isfinite(value) || value < minValue || value > maxValue
                error('%s harus berupa angka antara %g dan %g.', label, minValue, maxValue);
            end
        end

        function updateInfo(obj, lines)
            obj.UI.TxtInfo.Value = lines;
        end

        function resetGui(obj)
            obj.ImgInput = [];
            obj.ImgEdgeMap = [];
            obj.ImgOutput = [];
            obj.ImgOverlay = [];
            obj.ModelPath = '';
            cla(obj.UI.AxInput);
            cla(obj.UI.AxEdge);
            cla(obj.UI.AxOutput);
            cla(obj.UI.AxOverlay);
            obj.UI.LblModel.Text = 'Bobot model: default';
            obj.UI.setVisualizationTitles('Citra Masukan', 'Mask / Label Segmen', ...
                'Overlay / Hasil Segmentasi');
            obj.updateInfo({'Belum ada citra.', 'Pilih metode lalu jalankan pemrosesan.'});
            obj.UI.LblStatus.Text = 'Ready. Pilih citra input untuk memulai.';
        end
    end

end
