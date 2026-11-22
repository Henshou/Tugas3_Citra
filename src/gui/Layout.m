classdef Layout < handle
    properties (SetAccess = private)
        Fig matlab.ui.Figure
        MainGrid matlab.ui.container.GridLayout
        BtnLoad matlab.ui.control.Button
        BtnRun matlab.ui.control.Button
        BtnReset matlab.ui.control.Button
        BtnModel matlab.ui.control.Button
        BtnHistogram matlab.ui.control.Button
        MenuCategory matlab.ui.control.DropDown
        MenuMethod matlab.ui.control.DropDown
        TxtThreshold matlab.ui.control.EditField
        TxtMinSize matlab.ui.control.NumericEditField
        TxtMerge matlab.ui.control.EditField
        LblModel matlab.ui.control.Label
        LblStatus matlab.ui.control.Label
        AxInput matlab.ui.control.UIAxes
        AxOutput matlab.ui.control.UIAxes
        AxOverlay matlab.ui.control.UIAxes
        TxtInfo matlab.ui.control.TextArea
        Colors struct
    end

    methods
        function obj = Layout(closeRequestCallback)
            obj.Colors = struct();
            obj.Colors.background = [0.95 0.96 0.98];
            obj.Colors.panel = [0.13 0.15 0.18];
            obj.Colors.card = [0.90 0.92 0.95];
            obj.Colors.text = [0.96 0.98 1.00];
            obj.Colors.dark = [0.10 0.12 0.15];
            obj.Colors.primary = [0.00 0.45 0.85];
            obj.Colors.success = [0.10 0.60 0.30];
            obj.Colors.secondary = [0.22 0.26 0.32];
            obj.buildUI(closeRequestCallback);
        end

        function setMethodItems(obj, items)
            obj.MenuMethod.Items = items;
            obj.MenuMethod.Value = items{1};
        end

        function showHistogram(obj, img)
            if isempty(img), return; end
            fig = uifigure('Name', 'Histogram Citra', 'Position', [180 120 700 500], ...
                'Color', obj.Colors.background);
            ax = uiaxes(fig);
            histogram(ax, im2uint8(im2gray(im2double(img))), 256);
            title(ax, 'Histogram');
        end

        function delete(obj)
            if isvalid(obj.Fig), delete(obj.Fig); end
        end
    end

    methods (Access = private)
        function buildUI(obj, closeRequestCallback)
            obj.Fig = uifigure('Name', 'Tugas 3 - Deteksi Tepi & Segmentasi Citra', ...
                'Position', [30 30 1450 820], 'Color', obj.Colors.background, ...
                'CloseRequestFcn', closeRequestCallback);
            obj.MainGrid = uigridlayout(obj.Fig, [3 1]);
            obj.MainGrid.RowHeight = {45 '1x' 30};
            obj.MainGrid.Padding = [10 10 10 10];
            obj.MainGrid.RowSpacing = 8;

            header = uipanel(obj.MainGrid, 'BackgroundColor', obj.Colors.card, 'BorderType', 'none');
            header.Layout.Row = 1;
            uilabel(header, 'Text', 'Tugas 3 - Deteksi Tepi dan Segmentasi Citra', ...
                'FontSize', 17, 'FontWeight', 'bold', 'FontColor', obj.Colors.dark, ...
                'Position', [15 8 700 30]);

            mid = uigridlayout(obj.MainGrid, [1 3]);
            mid.Layout.Row = 2;
            mid.ColumnWidth = {300 250 '1x'};
            mid.ColumnSpacing = 10;
            mid.Padding = [0 0 0 0];
            obj.buildControls(mid);
            obj.buildInfo(mid);
            obj.buildVisualization(mid);

            statusPanel = uipanel(obj.MainGrid, 'BackgroundColor', obj.Colors.card, 'BorderType', 'none');
            statusPanel.Layout.Row = 3;
            obj.LblStatus = uilabel(statusPanel, 'Text', 'Ready. Pilih citra input untuk memulai.', ...
                'FontColor', obj.Colors.dark, 'FontWeight', 'bold', 'Position', [10 4 1200 22]);
        end

        function buildControls(obj, parent)
            panel = uipanel(parent, 'Title', ' Operation & Parameters ', 'FontWeight', 'bold', ...
                'ForegroundColor', obj.Colors.text, 'BackgroundColor', obj.Colors.panel);
            grid = uigridlayout(panel, [12 1]);
            grid.RowHeight = {32 22 32 22 32 32 32 32 32 32 38 38};
            grid.RowSpacing = 4;
            grid.Padding = [8 8 8 8];

            obj.BtnLoad = uibutton(grid, 'push', 'Text', '1. Pilih Citra Input', ...
                'BackgroundColor', obj.Colors.primary, 'FontColor', 'white', 'FontWeight', 'bold');
            uilabel(grid, 'Text', 'Bagian:', 'FontWeight', 'bold', 'FontColor', obj.Colors.text);
            obj.MenuCategory = uidropdown(grid, 'Items', ...
                {'Deteksi Tepi', 'Split and Merge', 'Deep Learning / Semantic Segmentation'}, ...
                'BackgroundColor', obj.Colors.secondary, 'FontColor', 'white');
            uilabel(grid, 'Text', 'Metode:', 'FontWeight', 'bold', 'FontColor', obj.Colors.text);
            obj.MenuMethod = uidropdown(grid, 'Items', {'Sobel', 'Prewitt', 'Canny', 'Laplacian', 'Roberts'}, ...
                'BackgroundColor', obj.Colors.secondary, 'FontColor', 'white');
            uilabel(grid, 'Text', 'Threshold:', 'FontWeight', 'bold', 'FontColor', obj.Colors.text);
            obj.TxtThreshold = uieditfield(grid, 'text', 'Value', '0.10', ...
                'BackgroundColor', 'white', 'FontColor', obj.Colors.dark);
            uilabel(grid, 'Text', 'Ukuran Minimum Region:', 'FontWeight', 'bold', 'FontColor', obj.Colors.text);
            obj.TxtMinSize = uieditfield(grid, 'numeric', 'Value', 8, ...
                'BackgroundColor', 'white', 'FontColor', obj.Colors.dark);
            uilabel(grid, 'Text', 'Threshold Merge:', 'FontWeight', 'bold', 'FontColor', obj.Colors.text);
            obj.TxtMerge = uieditfield(grid, 'text', 'Value', '0.05', ...
                'BackgroundColor', 'white', 'FontColor', obj.Colors.dark);
            obj.BtnModel = uibutton(grid, 'push', 'Text', 'Pilih Model (.mat / .onnx)', ...
                'BackgroundColor', obj.Colors.secondary, 'FontColor', 'white', 'Enable', 'off');
            obj.LblModel = uilabel(grid, 'Text', 'Model: Belum dipilih', ...
                'FontColor', [0.78 0.82 0.88], 'FontSize', 9, 'WordWrap', 'on');
            obj.BtnRun = uibutton(grid, 'push', 'Text', 'Jalankan Segmentasi', ...
                'BackgroundColor', obj.Colors.success, 'FontColor', 'white', 'FontWeight', 'bold');
            obj.BtnReset = uibutton(grid, 'push', 'Text', 'Reset', ...
                'BackgroundColor', obj.Colors.card, 'FontColor', obj.Colors.dark, 'FontWeight', 'bold');
        end

        function buildInfo(obj, parent)
            panel = uipanel(parent, 'Title', ' Informasi Hasil ', 'FontWeight', 'bold', ...
                'ForegroundColor', obj.Colors.text, 'BackgroundColor', obj.Colors.panel);
            grid = uigridlayout(panel, [3 1]);
            grid.RowHeight = {'1x' 32 38};
            grid.RowSpacing = 6;
            grid.Padding = [8 8 8 8];
            obj.TxtInfo = uitextarea(grid, 'Editable', 'off', 'Value', ...
                {'Belum ada citra.', 'Pilih metode lalu jalankan pemrosesan.'}, ...
                'BackgroundColor', obj.Colors.card, 'FontColor', obj.Colors.dark);
            obj.BtnHistogram = uibutton(grid, 'push', 'Text', 'Tampilkan Histogram', ...
                'BackgroundColor', obj.Colors.secondary, 'FontColor', 'white');
        end

        function buildVisualization(obj, parent)
            grid = uigridlayout(parent, [2 2]);
            grid.ColumnWidth = {'1x' '1x'};
            grid.RowHeight = {'1x' '1x'};
            grid.ColumnSpacing = 8;
            grid.RowSpacing = 8;
            grid.Padding = [0 0 0 0];
            obj.AxInput = obj.makeAxes(grid, 'Citra Masukan', 1, 1);
            obj.AxOutput = obj.makeAxes(grid, 'Hasil Deteksi / Segmentasi', 1, 2);
            obj.AxOverlay = obj.makeAxes(grid, 'Overlay Segmen', 2, [1 2]);
        end

        function ax = makeAxes(~, parent, titleText, row, column)
            panel = uipanel(parent, 'Title', titleText, 'FontWeight', 'bold', ...
                'ForegroundColor', [0.96 0.98 1.00], 'BackgroundColor', [0.13 0.15 0.18]);
            panel.Layout.Row = row;
            panel.Layout.Column = column;
            ax = uiaxes(panel, 'BackgroundColor', [0.10 0.12 0.15], 'XColor', 'none', 'YColor', 'none');
        end
    end
end
