classdef App < handle
    properties (Access = private)
        RootFolder char
        UI Layout
        Service Service
        ImgInput
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
        end

        function loadImage(obj)
            startDir = fullfile(obj.RootFolder, 'dataset');
            if ~isfolder(startDir), startDir = obj.RootFolder; end
            [fileName, folderName] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif', 'Image files'}, ...
                'Pilih Citra Input', startDir);
            if isequal(fileName, 0), return; end
            obj.ImgInput = imread(fullfile(folderName, fileName));
            if size(obj.ImgInput, 3) == 4
                obj.ImgInput = obj.ImgInput(:, :, 1:3);
            end
            imshow(obj.ImgInput, 'Parent', obj.UI.AxInput);
            title(obj.UI.AxInput, 'Citra Masukan');
            obj.UI.LblStatus.Text = ['Citra dimuat: ' fileName];
            obj.updateInfo({
                ['Input: ' fileName]
                sprintf('Ukuran: %d x %d', size(obj.ImgInput,1), size(obj.ImgInput,2))
                sprintf('Tipe: %s', class(obj.ImgInput))
            });
        end

        function loadModel(obj)
            [fileName, folderName] = uigetfile({'*.mat;*.onnx', 'MATLAB/ONNX model'}, ...
                'Pilih Model Deep Learning');
            if isequal(fileName, 0), return; end
            obj.ModelPath = fullfile(folderName, fileName);
            obj.UI.LblModel.Text = ['Model: ' fileName];
            obj.UI.LblStatus.Text = 'Model dipilih.';
        end

        function onCategoryChanged(obj)
            switch obj.UI.MenuCategory.Value
                case 'Deteksi Tepi'
                    obj.UI.setMethodItems({'Sobel', 'Prewitt', 'Canny', 'Laplacian', 'Roberts'});
                    obj.UI.TxtThreshold.Enable = 'on';
                    obj.UI.TxtMinSize.Enable = 'off';
                    obj.UI.TxtMerge.Enable = 'off';
                    obj.UI.BtnModel.Enable = 'off';
                case 'Split and Merge'
                    obj.UI.setMethodItems({'Quadtree Split and Merge'});
                    obj.UI.TxtThreshold.Enable = 'off';
                    obj.UI.TxtMinSize.Enable = 'on';
                    obj.UI.TxtMerge.Enable = 'on';
                    obj.UI.BtnModel.Enable = 'off';
                otherwise
                    obj.UI.setMethodItems({'Semantic Segmentation'});
                    obj.UI.TxtThreshold.Enable = 'off';
                    obj.UI.TxtMinSize.Enable = 'off';
                    obj.UI.TxtMerge.Enable = 'off';
                    obj.UI.BtnModel.Enable = 'on';
            end
        end

        function run(obj)
            if isempty(obj.ImgInput)
                uialert(obj.UI.Fig, 'Silakan pilih citra input terlebih dahulu.', 'Citra Belum Dipilih');
                return;
            end

            obj.UI.LblStatus.Text = 'Memproses citra...';
            drawnow;
            try
                switch obj.UI.MenuCategory.Value
                    case 'Deteksi Tepi'
                        threshold = str2double(obj.UI.TxtThreshold.Value);
                        [obj.ImgOutput, edgeInfo] = obj.Service.detectEdges(obj.ImgInput, ...
                            obj.UI.MenuMethod.Value, threshold);
                        obj.ImgOverlay = obj.Service.makeEdgeOverlay(obj.ImgInput, obj.ImgOutput);
                        obj.updateInfo(edgeInfo);
                    case 'Split and Merge'
                        [obj.ImgOutput, obj.ImgOverlay, regionInfo] = obj.Service.splitAndMerge(...
                            obj.ImgInput, obj.UI.TxtMinSize.Value, str2double(obj.UI.TxtMerge.Value));
                        obj.updateInfo(regionInfo);
                    otherwise
                        if isempty(obj.ModelPath)
                            error('Pilih model .mat atau .onnx terlebih dahulu.');
                        end
                        [obj.ImgOutput, obj.ImgOverlay, modelInfo] = obj.Service.semanticSegment(...
                            obj.ImgInput, obj.ModelPath);
                        obj.updateInfo(modelInfo);
                end
                imshow(obj.ImgOutput, 'Parent', obj.UI.AxOutput);
                imshow(obj.ImgOverlay, 'Parent', obj.UI.AxOverlay);
                obj.UI.LblStatus.Text = 'Pemrosesan selesai.';
            catch ME
                uialert(obj.UI.Fig, ME.message, 'Kesalahan Pemrosesan');
                obj.UI.LblStatus.Text = ['Error: ' ME.message];
            end
        end

        function updateInfo(obj, lines)
            obj.UI.TxtInfo.Value = lines;
        end

        function resetGui(obj)
            obj.ImgInput = [];
            obj.ImgOutput = [];
            obj.ImgOverlay = [];
            obj.ModelPath = '';
            cla(obj.UI.AxInput); cla(obj.UI.AxOutput); cla(obj.UI.AxOverlay);
            obj.UI.LblModel.Text = 'Model: Belum dipilih';
            obj.updateInfo({'Belum ada citra.', 'Pilih metode lalu jalankan pemrosesan.'});
            obj.UI.LblStatus.Text = 'Ready. Pilih citra input untuk memulai.';
        end
    end
end
