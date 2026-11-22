clear; clc; close all;

% Uji pada delapan citra BSDS500 yang disediakan bersama tugas.
rootFolder = fileparts(fileparts(mfilename('fullpath')));
dataFolder = fullfile(rootFolder, 'data', 'bsds500_test_8');
files = dir(fullfile(dataFolder, '*.jpg'));
if numel(files) ~= 8
    error('Diharapkan ada 8 citra BSDS500 di %s, ditemukan %d.', ...
        dataFolder, numel(files));
end

params = struct('minSize', 8, 'splitThreshold', 0.05, 'mergeThreshold', 0.05);
summary = cell(numel(files), 4);

for i = 1:numel(files)
    imagePath = fullfile(files(i).folder, files(i).name);
    img = imread(imagePath);
    [~, ~, overlay, info] = splitMerge(img, params);

    figure('Name', ['Split and Merge - ' files(i).name], ...
        'Color', 'w', 'Position', [80 80 1350 460]);
    tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

    nexttile;
    imshow(img);
    title('Citra Masukan');

    nexttile;
    imshow(info.splitVisualization);
    title(sprintf('Setelah Split (%d region)', info.splitRegionCount));

    nexttile;
    imshow(overlay);
    title(sprintf('Setelah Merge (%d region)', info.regionCount));

    summary(i, :) = {files(i).name, info.splitRegionCount, ...
        info.regionCount, info.time};
    fprintf('%s | split=%d | merge=%d | time=%.2fs\n', ...
        files(i).name, info.splitRegionCount, info.regionCount, info.time);
end

summaryTable = cell2table(summary, 'VariableNames', ...
    {'Image', 'RegionsAfterSplit', 'RegionsAfterMerge', 'TimeSeconds'});
disp(summaryTable);
