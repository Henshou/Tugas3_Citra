clear; clc; close all;

imgPath = 'data/bsds500_test_8/2018.jpg';             
params.pythonExe = 'C:\Users\Gerrard\AppData\Local\Programs\Python\Python311\python.exe';              

img = imread(imgPath);
[labelMap, overlay, info] = semanticSegmentation(img, params);
disp(info.pythonOutput);

figure('Name', 'Segmentasi Semantik CamVid', 'Position', [50 50 1300 450]);

subplot(1, 3, 1); imshow(img); title('Citra asli');
subplot(1, 3, 2); imshow(overlay); title(sprintf('Overlay (%.1f s)', info.time));

subplot(1, 3, 3);
imagesc(labelMap, [0.5 11.5]);           
axis image off;
colormap(gca, info.palette);
cb = colorbar;
cb.Ticks = 1:11;
cb.TickLabels = info.classNames;
title('Peta kelas');


T = table(info.classNames', 100 * info.classFractions', ...
    'VariableNames', {'Kelas', 'PersenPiksel'});
disp(T);