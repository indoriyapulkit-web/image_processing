% filter_view.m
% Read pixels_out.txt from the RTL simulation and reconstruct the image.
% For the supplied design, expected output geometry is 510 rows x 512 columns:
% no vertical padding; the line buffer zero-pads the right horizontal edge.

clear; clc;
WIDTH = 512;
INPUT_HEIGHT = 512;
OUTPUT_HEIGHT = INPUT_HEIGHT - 2;
EXPECTED = WIDTH * OUTPUT_HEIGHT;

[fileName, folder] = uigetfile({'*.txt', 'Text files (*.txt)'; '*.*', 'All files (*.*)'}, ...
    'Select pixels_out.txt from simulation');
if isequal(fileName, 0)
    disp('Output selection cancelled.');
    return;
end

fid = fopen(fullfile(folder, fileName), 'r');
if fid < 0
    error('Cannot open the selected output file.');
end
outPixels = fscanf(fid, '%d');
fclose(fid);

if numel(outPixels) ~= EXPECTED
    error(['Expected %d output pixels (510x512), but read %d. ' ...
        'Check the simulator log for output count warnings.'], EXPECTED, numel(outPixels));
end
if any(outPixels < 0 | outPixels > 255)
    error('Output file contains values outside the 8-bit pixel range.');
end

% Output file is raster-ordered. Undo MATLAB's column-major storage.
filteredImage = reshape(uint8(outPixels), WIDTH, OUTPUT_HEIGHT).';

figure('Name', 'RTL filtered image');
imagesc(filteredImage);
colormap(gray(256));
axis image off;
title('RTL output: 3x3 average filter');

resultFile = fullfile(folder, 'filtered_result.png');
imwrite(filteredImage, resultFile);
fprintf('Reconstructed filtered image: %s\n', resultFile);
fprintf('Image dimensions: %d rows x %d columns.\n', size(filteredImage, 1), size(filteredImage, 2));

% Optional pixel-for-pixel comparison against the expected integer average.
% This mirrors the RTL's behavior: 3x3 windows, floor(sum/9), no vertical
% padding, and zero padding only beyond the right edge.
inputPreview = fullfile(pwd, 'input_resized.png');
if exist(inputPreview, 'file') == 2
    src = imread(inputPreview);
    expectedImage = zeros(OUTPUT_HEIGHT, WIDTH, 'uint8');
    for y = 1:OUTPUT_HEIGHT
        for x = 1:WIDTH
            xEnd = min(WIDTH, x + 2);
            block = double(src(y:y+2, x:xEnd));
            expectedImage(y, x) = uint8(floor(sum(block(:)) / 9));
        end
    end
    if isequal(filteredImage, expectedImage)
        disp('Pixel-for-pixel check against the expected 3x3 average passed.');
    else
        mismatchCount = nnz(filteredImage ~= expectedImage);
        fprintf('WARNING: %d output pixels differ from the software reference.\n', mismatchCount);
        fprintf('Check RTL timing, byte order, and the simulation input file.\n');
    end
else
    fprintf('No input_resized.png found in MATLAB current folder; skipped reference comparison.\n');
end
