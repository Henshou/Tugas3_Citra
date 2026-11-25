function lines = formatClassStats(info)
% FORMATCLASSSTATS  Daftar teks nama kelas dan persentase pikselnya, urut
% dari yang terbesar. Cocok untuk kotak info di GUI (cell array string).

pct = 100 * info.classFractions(:);
[pct, order] = sort(pct, 'descend');
names = info.classNames(order);

lines = cell(numel(pct) + 1, 1);
lines{1} = 'Proporsi piksel per kelas:';
for i = 1:numel(pct)
    lines{i + 1} = sprintf('%-11s %6.2f %%', names{i}, pct(i));
end
end