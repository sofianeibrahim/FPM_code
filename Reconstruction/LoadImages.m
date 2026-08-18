function [I, imageList] = LoadImages(loadDirectory)
%LOADIMAGES Load FPM images from a directory
%   Inputs:
%       loadDirectory - directory where input FPM images are stored
%   Outputs:
%       I - loaded images (3D matrix, size: height x width x N)
%       imageList - list of loaded image filenames (natural order)
 %--- Step 1. Get all .tif / .tiff files ---
 imageList = [dir(fullfile(loadDirectory,'*tif'));...
     dir(fullfile(loadDirectory,'*tiff'))];
 if isempty(imageList)
     error('No .tif/.tiff files found in directory: %s', loadDirectory);
 end
 %--- Step 2. Sort files in natural order ---
 names = {imageList.name};
 imageList = sort_nat(names);% cell array of file names
 %--- Step 3. Read the first image to determine size and data type ---
 firstImage = imread(fullfile(loadDirectory, imageList{1})); % Read the first image
 [height, width] = size(firstImage); % Get the dimensions of the first image
 classType = class(firstImage);%  Keep the original camera bit depth
 %--- Step 4.Preallocate the 3D image array ---
 I = zeros(height, width, length(imageList), classType); % Initialize the 3D matrix for images
 I(:, :, 1) = firstImage; % Store the first image in the 3D matrix
 %--- Step 5. Batch loading of images ---
 for k = 2:length(imageList)
    I(:, :, k) = imread(fullfile(loadDirectory, imageList{k})); % Load subsequent images
 end
end