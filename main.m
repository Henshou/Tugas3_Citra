    function main
%MAIN Menjalankan GUI Tugas 3.

    rootFolder = fileparts(mfilename('fullpath'));
    addpath(fullfile(rootFolder, 'src', 'gui'));
    addpath(fullfile(rootFolder, 'src', 'edge'));
    addpath(fullfile(rootFolder, 'src', 'splitmerge'));
    addpath(fullfile(rootFolder, 'src', 'deeplearning'));
    addpath(fullfile(rootFolder, 'src', 'utils'));

    App(rootFolder);
end