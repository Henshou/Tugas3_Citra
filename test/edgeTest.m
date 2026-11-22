clear; clc; close all;

imgPath = 'data/bsds500_test_8/2018.jpg';

if exist(imgPath, 'file')
    img = imread(imgPath);
else
    [X, Y] = meshgrid(1:300, 1:240);
    obj = ((X-150)/80).^2 + ((Y-120)/60).^2 <= 1;
    I = 0.25 * ones(240, 300);
    I(obj) = 0.8;
    I = min(max(I + 0.03*randn(size(I)), 0), 1);
    img = uint8(255 * I);
    disp('File citra tidak ditemukan -> memakai citra sintetis.');
end

methods = {'laplace', 'log', 'sobel', 'prewitt', 'roberts', 'canny'};

figure('Name', 'Segmentasi Edge-Based', 'Position', [50 50 1200 700]);
for i = 1:numel(methods)
    p = struct('method', methods{i});
    [labelMap, overlay, info] = segmentEdge(img, p);

    subplot(3, 4, 2*i-1);
    imshow(info.edgeMap);
    title(['Tepi: ' methods{i}]);

    subplot(3, 4, 2*i);
    imshow(overlay);
    title(sprintf('Segmentasi (%d objek, %.2f s)', info.numObjects, info.time));
end