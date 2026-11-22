classdef Layout < handle
    properties (SetAccess = private)
        Fig matlab.ui.Figure
        MainGrid matlab.ui.container.GridLayout
        ControlsGrid matlab.ui.container.GridLayout
        BtnLoad matlab.ui.control.Button
        BtnRun matlab.ui.control.Button
        BtnReset matlab.ui.control.Button
        BtnModel matlab.ui.control.Button
        BtnHistogram matlab.ui.control.Button
        MenuCategory matlab.ui.control.DropDown
        MenuMethod matlab.ui.control.DropDown
        TxtThreshold matlab.ui.control.EditField
        TxtSigma matlab.ui.control.NumericEditField
        TxtCannyThreshold matlab.ui.control.EditField
        TxtDilateRadius matlab.ui.control.NumericEditField
        TxtCloseRadius matlab.ui.control.NumericEditField
        TxtMinArea matlab.ui.control.EditField
        MenuSelect matlab.ui.control.DropDown
        TxtMinSize matlab.ui.control.NumericEditField
        TxtSplitThreshold matlab.ui.control.EditField
        TxtMerge matlab.ui.control.EditField
        TxtAlpha matlab.ui.control.EditField
        TxtDevice matlab.ui.control.EditField
        LblThreshold matlab.ui.control.Label
        LblSigma matlab.ui.control.Label
        LblCannyThreshold matlab.ui.control.Label
        LblDilateRadius matlab.ui.control.Label
        LblCloseRadius matlab.ui.control.Label
        LblMinArea matlab.ui.control.Label
        LblSelect matlab.ui.control.Label
        LblMinSize matlab.ui.control.Label
        LblSplitThreshold matlab.ui.control.Label
        LblMerge matlab.ui.control.Label
        LblSplitHelp matlab.ui.control.Label
        LblAlpha matlab.ui.control.Label
        LblDevice matlab.ui.control.Label
        LblModel matlab.ui.control.Label
        LblStatus matlab.ui.control.Label
        AxInput matlab.ui.control.UIAxes
        AxEdge matlab.ui.control.UIAxes
        AxOutput matlab.ui.control.UIAxes
        AxOverlay matlab.ui.control.UIAxes
        PnlInput matlab.ui.container.Panel
        PnlEdge matlab.ui.container.Panel
        PnlOutput matlab.ui.container.Panel
        PnlOverlay matlab.ui.container.Panel
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

        function setMethodItems(obj, items, selected)
            obj.MenuMethod.Items = items;
            if nargin < 3 || isempty(selected) || ~any(strcmp(selected, items))
                selected = items{1};
            end
            obj.MenuMethod.Value = selected;
        end

        function configureCategory(obj, category)
            heights = {38, 32, 34, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 40};
            isEdgeSegmentation = strcmp(category, 'Segmentasi Berbasis Tepi');
            isSplitMerge = strcmp(category, 'Split and Merge');
            isDeepLearning = strcmp(category, 'Deep Learning / Semantic Segmentation');

            obj.setControlVisibility({obj.LblThreshold, obj.TxtThreshold}, isEdgeSegmentation);
            obj.setControlVisibility({obj.LblSigma, obj.TxtSigma}, isEdgeSegmentation);
            obj.setControlVisibility({obj.LblCannyThreshold, obj.TxtCannyThreshold}, isEdgeSegmentation);
            obj.setControlVisibility({obj.LblDilateRadius, obj.TxtDilateRadius}, isEdgeSegmentation);
            obj.setControlVisibility({obj.LblCloseRadius, obj.TxtCloseRadius}, isEdgeSegmentation);
            obj.setControlVisibility({obj.LblMinArea, obj.TxtMinArea}, isEdgeSegmentation);
            obj.setControlVisibility({obj.LblSelect, obj.MenuSelect}, isEdgeSegmentation);

            obj.setControlVisibility({obj.LblMinSize, obj.TxtMinSize}, isSplitMerge);
            obj.setControlVisibility({obj.LblSplitThreshold, obj.TxtSplitThreshold}, isSplitMerge);
            obj.setControlVisibility({obj.LblMerge, obj.TxtMerge}, isSplitMerge);
            obj.LblSplitHelp.Visible = obj.onOff(isSplitMerge);

            obj.setControlVisibility({obj.LblAlpha, obj.TxtAlpha}, isDeepLearning);
            obj.setControlVisibility({obj.LblDevice, obj.TxtDevice}, isDeepLearning);
            obj.BtnModel.Visible = obj.onOff(isDeepLearning);
            obj.LblModel.Visible = obj.BtnModel.Visible;

            if isEdgeSegmentation
                heights(4:10) = {30, 30, 30, 30, 30, 30, 30};
            elseif isSplitMerge
                heights(11:13) = {30, 30, 30};
                heights{14} = 50;
            elseif isDeepLearning
                heights(14:15) = {30, 30};
                heights(16:17) = {34, 38};
            end
            obj.ControlsGrid.RowHeight = heights;
        end

        function configureEdgeMethod(obj, isCanny)
            category = obj.MenuCategory.Value;
            if ~strcmp(category, 'Segmentasi Berbasis Tepi')
                return;
            end
            heights = obj.ControlsGrid.RowHeight;
            if isCanny
                heights{4} = 1;
                heights{6} = 30;
                obj.setControlVisibility({obj.LblThreshold, obj.TxtThreshold}, false);
                obj.setControlVisibility({obj.LblCannyThreshold, obj.TxtCannyThreshold}, true);
            else
                heights{4} = 30;
                heights{6} = 1;
                obj.setControlVisibility({obj.LblThreshold, obj.TxtThreshold}, true);
                obj.setControlVisibility({obj.LblCannyThreshold, obj.TxtCannyThreshold}, false);
            end
            obj.ControlsGrid.RowHeight = heights;
        end

        function setVisualizationTitles(obj, inputTitle, outputTitle, overlayTitle)
            title(obj.AxInput, inputTitle);
            title(obj.AxOutput, outputTitle);
            title(obj.AxOverlay, overlayTitle);
        end

        function setEdgeVisualizationTitles(obj, inputTitle, edgeTitle, outputTitle, overlayTitle)
            title(obj.AxInput, inputTitle);
            title(obj.AxEdge, edgeTitle);
            title(obj.AxOutput, outputTitle);
            title(obj.AxOverlay, overlayTitle);
        end

        function configureVisualization(obj, category)
            if strcmp(category, 'Segmentasi Berbasis Tepi')
                obj.PnlInput.Layout.Row = 1;
                obj.PnlInput.Layout.Column = 1;
                obj.PnlEdge.Layout.Row = 1;
                obj.PnlEdge.Layout.Column = 2;
                obj.PnlOutput.Layout.Row = 2;
                obj.PnlOutput.Layout.Column = 1;
                obj.PnlOverlay.Layout.Row = 2;
                obj.PnlOverlay.Layout.Column = 2;
                obj.PnlEdge.Visible = 'on';
                obj.PnlOutput.Visible = 'on';
                obj.PnlOverlay.Visible = 'on';
                obj.PnlInput.Visible = 'on';
            else
                obj.PnlInput.Layout.Row = 1;
                obj.PnlInput.Layout.Column = 1;
                obj.PnlOutput.Layout.Row = 1;
                obj.PnlOutput.Layout.Column = 2;
                obj.PnlOverlay.Layout.Row = 2;
                obj.PnlOverlay.Layout.Column = [1 2];
                obj.PnlEdge.Visible = 'off';
                obj.PnlInput.Visible = 'on';
                obj.PnlOutput.Visible = 'on';
                obj.PnlOverlay.Visible = 'on';
            end
        end

        function showHistogram(obj, img)
            if isempty(img)
                return;
            end
            fig = uifigure('Name', 'Histogram Citra', 'Position', [180 120 700 500], ...
                'Color', obj.Colors.background);
            ax = uiaxes(fig);
            histogram(ax, im2uint8(im2gray(im2double(img))), 256);
            title(ax, 'Histogram Intensitas Grayscale');
            xlabel(ax, 'Intensitas');
            ylabel(ax, 'Jumlah piksel');
        end

        function delete(obj)
            if isvalid(obj.Fig)
                delete(obj.Fig);
            end
        end
    end

    methods (Access = private)
        function buildUI(obj, closeRequestCallback)
            obj.Fig = uifigure('Name', 'Tugas 3 - Segmentasi Citra', ...
                'Position', [25 35 1440 850], 'Color', obj.Colors.background, ...
                'CloseRequestFcn', closeRequestCallback);
            obj.MainGrid = uigridlayout(obj.Fig, [3 1]);
            obj.MainGrid.RowHeight = {48, '1x', 30};
            obj.MainGrid.Padding = [10 10 10 10];
            obj.MainGrid.RowSpacing = 8;

            header = uipanel(obj.MainGrid, 'BackgroundColor', obj.Colors.card, 'BorderType', 'none');
            header.Layout.Row = 1;
            uilabel(header, 'Text', 'Segmentasi Citra', ...
                'FontSize', 16, 'FontWeight', 'bold', 'FontColor', obj.Colors.dark, ...
                'Position', [15 8 1100 30]);

            mid = uigridlayout(obj.MainGrid, [1 3]);
            mid.Layout.Row = 2;
            mid.ColumnWidth = {350, 270, '1x'};
            mid.ColumnSpacing = 10;
            mid.Padding = [0 0 0 0];
            obj.buildControls(mid);
            obj.buildInfo(mid);
            obj.buildVisualization(mid);

            statusPanel = uipanel(obj.MainGrid, 'BackgroundColor', obj.Colors.card, 'BorderType', 'none');
            statusPanel.Layout.Row = 3;
            obj.LblStatus = uilabel(statusPanel, 'Text', 'Siap. Pilih salah satu citra BSDS500 atau citra lain.', ...
                'FontColor', obj.Colors.dark, 'FontWeight', 'bold', ...
                'Position', [10 4 1320 22]);
        end

        function buildControls(obj, parent)
            panel = uipanel(parent, 'Title', ' Metode & Parameter ', 'FontWeight', 'bold', ...
                'ForegroundColor', obj.Colors.text, 'BackgroundColor', obj.Colors.panel);
            obj.ControlsGrid = uigridlayout(panel, [18 2]);
            obj.ControlsGrid.RowHeight = {38, 32, 34, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 40};
            obj.ControlsGrid.ColumnWidth = {'1.15x', '1x'};
            obj.ControlsGrid.RowSpacing = 4;
            obj.ControlsGrid.ColumnSpacing = 6;
            obj.ControlsGrid.Padding = [9 9 9 9];

            obj.BtnLoad = uibutton(obj.ControlsGrid, 'push', ...
                'Text', 'Pilih Citra Input (BSDS500 tersedia)', ...
                'BackgroundColor', obj.Colors.primary, 'FontColor', 'white', 'FontWeight', 'bold');
            obj.BtnLoad.Layout.Row = 1;
            obj.BtnLoad.Layout.Column = [1 2];

            uilabel(obj.ControlsGrid, 'Text', 'Bagian:', 'FontWeight', 'bold', 'FontColor', obj.Colors.text);
            obj.MenuCategory = uidropdown(obj.ControlsGrid, 'Items', ...
                {'Segmentasi Berbasis Tepi', 'Split and Merge', ...
                 'Deep Learning / Semantic Segmentation'}, ...
                'BackgroundColor', obj.Colors.secondary, 'FontColor', 'white');
            obj.MenuCategory.Layout.Row = 2;
            obj.MenuCategory.Layout.Column = 2;

            uilabel(obj.ControlsGrid, 'Text', 'Metode:', 'FontWeight', 'bold', 'FontColor', obj.Colors.text);
            obj.MenuMethod = uidropdown(obj.ControlsGrid, 'Items', ...
                {'Sobel', 'Prewitt', 'Roberts', 'Laplace', 'LoG', 'Canny'}, ...
                'BackgroundColor', obj.Colors.secondary, 'FontColor', 'white');
            obj.MenuMethod.Layout.Row = 3;
            obj.MenuMethod.Layout.Column = 2;

            obj.LblThreshold = obj.addParameterLabel('Threshold (kosong = auto):', 4);
            obj.TxtThreshold = obj.addTextField(4, '');
            obj.LblSigma = obj.addParameterLabel('Sigma:', 5);
            obj.TxtSigma = obj.addNumericField(5, 1.5, 0.1, 10);
            obj.LblCannyThreshold = obj.addParameterLabel('Canny [low high] (auto):', 6);
            obj.TxtCannyThreshold = obj.addTextField(6, '');

            obj.LblDilateRadius = obj.addParameterLabel('Radius dilasi:', 7);
            obj.TxtDilateRadius = obj.addNumericField(7, 2, 0, 50);
            obj.LblCloseRadius = obj.addParameterLabel('Radius closing:', 8);
            obj.TxtCloseRadius = obj.addNumericField(8, 4, 0, 50);
            obj.LblMinArea = obj.addParameterLabel('Luas minimum (fraksi):', 9);
            obj.TxtMinArea = obj.addTextField(9, '0.01');
            obj.LblSelect = obj.addParameterLabel('Pemilihan objek:', 10);
            obj.MenuSelect = uidropdown(obj.ControlsGrid, 'Items', {'score', 'largest'}, ...
                'BackgroundColor', 'white', 'FontColor', obj.Colors.dark);
            obj.MenuSelect.Layout.Row = 10;
            obj.MenuSelect.Layout.Column = 2;

            obj.LblMinSize = obj.addParameterLabel('Ukuran minimum region (px):', 11);
            obj.TxtMinSize = obj.addNumericField(11, 8, 1, 2048);
            obj.LblSplitThreshold = obj.addParameterLabel('Std. dev. split (0-1):', 12);
            obj.TxtSplitThreshold = obj.addTextField(12, '0.05');
            obj.LblMerge = obj.addParameterLabel('Jarak mean RGB merge (0-1):', 13);
            obj.TxtMerge = obj.addTextField(13, '0.05');

            obj.LblSplitHelp = uilabel(obj.ControlsGrid, ...
                'Text', ['std intensitas grayscale blok harus <= threshold. ' ...
                         'Merge terjadi saat region bertetangga jarak RMS mean RGB <= threshold. '], ...
                'FontColor', [0.78 0.82 0.88], 'FontSize', 9, 'WordWrap', 'on', ...
                'VerticalAlignment', 'center');
            obj.LblSplitHelp.Layout.Row = 14;
            obj.LblSplitHelp.Layout.Column = [1 2];

            obj.LblAlpha = obj.addParameterLabel('Alpha overlay:', 14);
            obj.TxtAlpha = obj.addTextField(14, '0.5');
            obj.LblDevice = obj.addParameterLabel('Device (auto/cpu/cuda):', 15);
            obj.TxtDevice = obj.addTextField(15, 'auto');

            obj.BtnModel = uibutton(obj.ControlsGrid, 'push', 'Text', 'Pilih Bobot Model (.pth)', ...
                'BackgroundColor', obj.Colors.secondary, 'FontColor', 'white');
            obj.BtnModel.Layout.Row = 16;
            obj.BtnModel.Layout.Column = [1 2];
            obj.LblModel = uilabel(obj.ControlsGrid, 'Text', 'Bobot model: default', ...
                'FontColor', [0.78 0.82 0.88], 'FontSize', 9, 'WordWrap', 'on');
            obj.LblModel.Layout.Row = 17;
            obj.LblModel.Layout.Column = [1 2];

            buttons = uigridlayout(obj.ControlsGrid, [1 2]);
            buttons.Layout.Row = 18;
            buttons.Layout.Column = [1 2];
            buttons.ColumnWidth = {'1x', '0.6x'};
            buttons.Padding = [0 0 0 0];
            obj.BtnRun = uibutton(buttons, 'push', 'Text', 'Jalankan', ...
                'BackgroundColor', obj.Colors.success, 'FontColor', 'white', 'FontWeight', 'bold');
            obj.BtnReset = uibutton(buttons, 'push', 'Text', 'Reset', ...
                'BackgroundColor', obj.Colors.card, 'FontColor', obj.Colors.dark, 'FontWeight', 'bold');
        end

        function label = addParameterLabel(obj, labelText, row)
            label = uilabel(obj.ControlsGrid, 'Text', labelText, 'FontWeight', 'bold', ...
                'FontColor', obj.Colors.text, 'FontSize', 9, 'WordWrap', 'on');
            label.Layout.Row = row;
            label.Layout.Column = 1;
        end

        function field = addTextField(obj, row, value)
            field = uieditfield(obj.ControlsGrid, 'text', 'Value', value, ...
                'BackgroundColor', 'white', 'FontColor', obj.Colors.dark);
            field.Layout.Row = row;
            field.Layout.Column = 2;
        end

        function field = addNumericField(obj, row, value, minValue, maxValue)
            field = uieditfield(obj.ControlsGrid, 'numeric', 'Value', value, ...
                'Limits', [minValue maxValue], 'BackgroundColor', 'white', 'FontColor', obj.Colors.dark);
            field.Layout.Row = row;
            field.Layout.Column = 2;
        end

        function setControlVisibility(~, controls, visible)
            state = 'off';
            if visible
                state = 'on';
            end
            for i = 1:numel(controls)
                controls{i}.Visible = state;
            end
        end

        function state = onOff(~, value)
            state = 'off';
            if value
                state = 'on';
            end
        end

        function buildInfo(obj, parent)
            panel = uipanel(parent, 'Title', ' Informasi Hasil ', 'FontWeight', 'bold', ...
                'ForegroundColor', obj.Colors.text, 'BackgroundColor', obj.Colors.panel);
            grid = uigridlayout(panel, [3 1]);
            grid.RowHeight = {'1x', 34, 38};
            grid.RowSpacing = 6;
            grid.Padding = [8 8 8 8];
            obj.TxtInfo = uitextarea(grid, 'Editable', 'off', ...
                'Value', {'Belum ada citra.', 'Pilih metode lalu jalankan pemrosesan.'}, ...
                'BackgroundColor', obj.Colors.card, 'FontColor', obj.Colors.dark);
            obj.BtnHistogram = uibutton(grid, 'push', 'Text', 'Tampilkan Histogram', ...
                'BackgroundColor', obj.Colors.secondary, 'FontColor', 'white');
        end

        function buildVisualization(obj, parent)
            grid = uigridlayout(parent, [2 2]);
            grid.ColumnWidth = {'1x', '1x'};
            grid.RowHeight = {'1x', '1x'};
            grid.ColumnSpacing = 8;
            grid.RowSpacing = 8;
            grid.Padding = [0 0 0 0];
            [obj.PnlInput, obj.AxInput] = obj.makeAxes(grid, 'Citra Masukan', 1, 1);
            [obj.PnlEdge, obj.AxEdge] = obj.makeAxes(grid, 'Peta Deteksi Tepi', 1, 2);
            [obj.PnlOutput, obj.AxOutput] = obj.makeAxes(grid, 'Mask / Label Segmen', 2, 1);
            [obj.PnlOverlay, obj.AxOverlay] = obj.makeAxes(grid, 'Overlay / Hasil Segmentasi', 2, 2);
            obj.PnlEdge.Visible = 'off';
            obj.PnlOutput.Layout.Row = 1;
            obj.PnlOutput.Layout.Column = 2;
            obj.PnlOverlay.Layout.Row = 2;
            obj.PnlOverlay.Layout.Column = [1 2];
        end

        function [panel, ax] = makeAxes(~, parent, titleText, row, column)
            panel = uipanel(parent, 'Title', titleText, 'FontWeight', 'bold', ...
                'ForegroundColor', [0.96 0.98 1.00], 'BackgroundColor', [0.13 0.15 0.18]);
            panel.Layout.Row = row;
            panel.Layout.Column = column;
            grid = uigridlayout(panel, [1 1]);
            grid.Padding = [4 4 4 4];
            ax = uiaxes(grid, 'BackgroundColor', [0.10 0.12 0.15], ...
                'XColor', 'none', 'YColor', 'none');
            ax.Toolbar.Visible = 'off';
            ax.Interactions = [];
        end
    end
end
