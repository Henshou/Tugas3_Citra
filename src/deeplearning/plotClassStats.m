function plotClassStats(ax, info, theme)
% PLOTCLASSSTATS  Diagram batang proporsi piksel tiap kelas hasil semantic
% segmentation. Setiap batang memakai warna kelas yang sama dengan peta
% segmentasi, diberi nama kelas dan persentasenya.

if nargin < 3, theme = 'light'; end
if nargin < 1 || isempty(ax)
    fig = figure('Name', 'Proporsi Kelas', 'Color', 'w', ...
        'Position', [100 100 640 420]);
    ax = axes('Parent', fig);
end

if strcmpi(theme, 'dark')
    fg = [0.96 0.98 1.00];
    bg = [0.10 0.12 0.15];
else
    fg = [0.15 0.15 0.15];
    bg = [1 1 1];
end

pct = 100 * info.classFractions(:);         
[pct, order] = sort(pct, 'ascend');        
names  = info.classNames(order);
colors = info.palette(order, :);
n = numel(pct);

cla(ax);
ax.Color  = bg;
ax.XColor = fg;                              
ax.YColor = fg;
hold(ax, 'on');
b = barh(ax, 1:n, pct, 0.7, 'FaceColor', 'flat');
b.CData = colors;                          
xMax = max(pct) * 1.25 + 1;
for i = 1:n
    text(ax, pct(i) + 0.01 * xMax, i, sprintf('%.2f%%', pct(i)), ...
        'VerticalAlignment', 'middle', 'FontSize', 9, 'Color', fg);
end
hold(ax, 'off');

ax.YTick = 1:n;
ax.YTickLabel = names;
ax.YLim = [0.4, n + 0.6];
ax.XLim = [0, xMax];
xlabel(ax, 'Proporsi piksel (%)', 'Color', fg);
title(ax, 'Proporsi Kelas Hasil Segmentasi', 'Color', fg);
box(ax, 'on');
end