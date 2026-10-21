% prepare_image.m
% Select an image, convert/resize it to 512x512 grayscale, and write
% pixels_in.txt in raster order for tb_image_processing.v.

clear; clc;
WIDTH = 512;
HEIGHT = 512;

[fileName, folder] = uigetfile( ...
    {'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', 'Image files'; '*.*', 'All files'}, ...
    'Select an input image');
if isequal(fileName, 0)
    disp('Image selection cancelled.');
    return;
end

[rawImage, colorMap] = imread(fullfile(folder, fileName));

% Convert indexed images to RGB/grayscale if a colormap is present.
if ~isempty(colorMap)
    idx = double(rawImage) + 1;
    r = colorMap(idx, 1);
    g = colorMap(idx, 2);
    b = colorMap(idx, 3);
    rawImage = cat(3, r, g, b);
end

% Convert to 8-bit grayscale without requiring rgb2gray/imresize.
if ndims(rawImage) == 3
    rgb = convertToUnitOrByteRange(rawImage);
    grayDouble = 0.2989 * rgb(:,:,1) + ...
                 0.5870 * rgb(:,:,2) + ...
                 0.1140 * rgb(:,:,3);
    gray = uint8(round(min(255, max(0, grayDouble))));
else
    gray = convertGrayToUint8(rawImage);
end

% Nearest-neighbor resize to exactly 512x512 using base MATLAB operations.
rowIndex = round(linspace(1, size(gray, 1), HEIGHT));
colIndex = round(linspace(1, size(gray, 2), WIDTH));
rowIndex(rowIndex < 1) = 1;
colIndex(colIndex < 1) = 1;
gray = gray(rowIndex, colIndex);

% MATLAB stores matrices column-wise. Transposing before linearizing makes
% the text stream raster-ordered: first row left-to-right, then next row.
pixels = reshape(gray.', [], 1);
inputFile = fopen('pixels_in.txt', 'w');
if inputFile < 0
    error('Cannot create pixels_in.txt in the current MATLAB folder.');
end
fprintf(inputFile, '%d\n', double(pixels));
fclose(inputFile);

imwrite(gray, 'input_resized.png');
figure('Name', 'Image supplied to RTL');
imagesc(gray);
% 'gray' is also the name of the image matrix, so avoid calling gray(256)
% here (MATLAB would index the matrix instead of calling the colormap function).
levels = linspace(0, 1, 256).';
colormap(gca, [levels levels levels]);
caxis([0 255]);
axis image off;
title('512 x 512 grayscale input');

fprintf('Created pixels_in.txt with %d decimal pixel values.\n', numel(pixels));
fprintf('Also saved input_resized.png in: %s\n', pwd);
fprintf('Copy pixels_in.txt into the Verilog simulator working directory before running the testbench.\n');

function out = convertGrayToUint8(img)
    if isa(img, 'uint8')
        out = img;
    elseif isa(img, 'uint16')
        out = uint8(round(double(img) / 257));
    elseif islogical(img)
        out = uint8(img) * 255;
    else
        d = double(img);
        if isempty(d)
            error('The selected image is empty.');
        end
        if min(d(:)) >= 0 && max(d(:)) <= 1
            d = d * 255;
        end
        out = uint8(round(min(255, max(0, d))));
    end
end

function out = convertToUnitOrByteRange(img)
    if isa(img, 'uint8')
        out = double(img);
    elseif isa(img, 'uint16')
        out = double(img) / 257;
    elseif islogical(img)
        out = double(img) * 255;
    else
        out = double(img);
        if min(out(:)) >= 0 && max(out(:)) <= 1
            out = out * 255;
        end
        out = min(255, max(0, out));
    end
end
