%% 
%%
clc,clear;
%%
addpath(genpath("C:\Users\Public\Documents\FPM\Run_matlab\Sofiane_code\Reconstruction\BM3D"));

%% ---- System parameters ----
systemSetup = struct();
systemSetup.LEDspacing     = 4;       % mm
systemSetup.LEDheight      = 65;      % mm69/70
systemSetup.camPixSize     = 4.54;    % um
systemSetup.lambda         = 0.625;   % um
systemSetup.NA             = 0.1;     % objective NA
systemSetup.magnification  = 4;       % magnification

%% ---- Reconstruction options ---- 
options = struct();
options.maxIter       = 6;       % maximum number of iterations 
options.alpha         = 3;       % object update regularization %3
options.beta          = 5;       % pupil update regularization %5
options.useGPU        = 0;       % GPU acceleration flag (1 = on, 0 = off)
options.initialPupil  = 1;       % 1 = ones, 2 = Tukey, 3 = Gaussian
options.algorithm     = '1';     % '1'=Quasi-Newton, '2'=GS
options.IntCorr       = 1;       % enable intensity correction
%%
loadDirectory = "D:\Sofiane_data\Reflection\capture_20260804_162957\HDR_BF";
loadDirectory_reflective ="D:\Sofiane_data\Reflection\capture_20260804_162957\HDR_BF";


%% Reconstruction output folder
options.saveIterations = 1;
options.saveFolder = fullfile(loadDirectory_reflective, 'Reconstruction_Iterations');

if ~exist(options.saveFolder,'dir')
    mkdir(options.saveFolder);
end
%%

Led_Array={'77',...
    '67','68','78','88','87','86','76','66',...%ring1
    '56','57','58','59','69','79','89','99',...
    '98','97','96','95','85','75','65','55',...%ring2
    '45','46','47','48','49','4a','5a','6a',...
    '7a','8a','9a','aa','a9','a8','a7','a6',...
    'a5','a4','94','84','74','64','54','44',...%ring3
    '34','35','36','37','38','39','3a','3b',...
    '4b','5b','6b','7b','8b','9b','ab','bb',...
    'ba','b9','b8','b7','b6','b5','b4','b3',...
    'a3','93','83','73','63','53','43','33',...%ring4
    '23','24','25','26','27','28','29','2a',...
    '2b','2c','3c','4c','5c','6c','7c','8c',...
    '9c','ac','bc','cc','cb','ca','c9','c8',...
    'c7','c6','c5','c4','c3','c2','b2','a2',...
    '92','82','72','62','52','42','32','22',...%ring5
    '12','13','14','15','16','17','18','19',...
    '1a','1b','1c','2d','3d','4d','5d','6d',...
    '7d','8d','9d','ad','bd','cd','dc','db',...
    'da','d9','d8','d7','d6','d5','d4','d3',...
    'd2','c1','b1','a1','91','81','71','61',...
    '51','41','31','21',...%ring6
    '03','04','05','06',...
    '07','08','09','0a','0b','3e','4e','5e',...
    '6e','7e','8e','9e','ae','be','eb','ea',...
    'e9','e8','e7','e6','e5','e4','e3','b0',...
    'a0','90','80','70','60','50','40','30'};%ring7

Led_Array_bis={'77',...
    '67','68','78','88','87','86','76','66',...%ring1
    '56','57','58','59','69','79','89','99',...
    '98','97','96','95','85','75','65','55',...%ring2
    '45','46','47','48','49','4a','5a','6a',...
    '7a','8a','9a','aa','a9','a8','a7','a6',...
    'a5','a4','94','84','74','64','54','44'};%ring3
%%reflective mode
Led_xy_BF = [
    0       0;
    4.748   1.575;
    0.007   5.002;
   -4.743   1.589;
   -2.91   -4.069;
    2.924  -4.059;
    4.967  -6.842;
    8.04   -2.615;
    8.042   2.61;
    4.972   6.839;
    0.003   8.455;
   -4.967   6.842;
   -8.04    2.615;
   -8.042  -2.61;
   -4.972  -6.839;
   -0.003  -8.455
];
Led_xy_DF = [
    7.97	0.7;
    6.04	5.25;
    1.8	    7.79;
    -3.13	7.36;
    -6.86	4.12;
    -7.97	-0.7;
    -6.04	-5.25;
    -1.8	-7.79;
    3.13	-7.36;
    6.86	-4.12;
    11.33   2;
    9.53    6.43;
    6.09    9.75;
    1.6     11.39;
    -3.17   11.05;
    -7.39   8.81;
    -10.33  5.04;
    -11.49  0.4; 
    -10.66  -4.31;
    -7.99   -8.27;
    -3.93   -10.8;
    0.8     -11.47;
    5.4     -10.15;
    9.06    -7.08;
    11.16   -2.78;

    
];


Led_xy_DF2= [
    13.95	1.22;
    12.69   5.92;
    9.9     9.9;
    5.92    12.69;
    1.22    13.95;
    -3.62   13.52;
    -8.03   11.47;
    -11.47  8.03;
    -13.52  3.62;
    -13.95  -1.22;
    -12.69  -5.92;
    -9.9    -9.9;
    -5.92   -12.69;
    -1.22   -13.95;
    3.62    -13.52;
    8.03    -11.47;
    11.47   -8.03;
    13.52   -3.62;
    19.98   0.87;
    19.14   5.81;
    17.09   10.39;
    13.97   14.31;
    9.97    17.34;
    5.34    19.27;
    0.38    20;
    -4.6    19.46;
    -9.3    17.71;
    -13.41  14.84;
    -16.68  11.04;
    -18.9   6.54;
    -19.93  1.64;
    -19.71  -3.37;
    -18.26  -8.17;
    -15.65  -12.45;
    -12.06  -15.95;
    -7.72   -18.45;
    -2.89   -19.79;
    2.13    -19.89;
    7       -18.73;
    11.44   -16.4;
    15.16   -13.04;
    17.93   -8.86;
    19.57   -4.12;
    30      0;
    29.57   5.07;
    28.29   9.99;
    26.19   14.63;
    23.24   18.85;
    19.82   22.52;
    15.73   25.55;
    11.19   27.84;
    6.32    29.33;
    1.27    29.97;
    -3.81   29.76;
    -8.78   28.69;
    -13.51  26.79;
    -17.84  24.12;
    -21.66  20.76;
    -24.86  16.8;
    -27.34  12.36;
    -29.03  7.56;
    -29.89  2.54;
    -29.89  -2.54;
    -29.03  -7.56;
    -27.34  -12.36;
    -24.86  -16.8;
    -21.66  -20.76;
    -17.84  -24.12;
    -13.51  -26.79;
    -8.78   -28.69;
    -3.81   -29.76;
    1.27    -29.97;
    6.32    -29.33;
    11.19   -27.84;
    15.73   -25.55;
    19.82   -22.52;
    23.34   -18.85;
    26.19   -14.63;
    28.29   -9.99;
    29.57   -5.97;

];



LED_xy_DF_all=[Led_xy_DF ; Led_xy_DF2];
Led_xy_all = [Led_xy_BF ; Led_xy_DF];
LED_xy_all2= [Led_xy_BF ; Led_xy_DF ; Led_xy_DF2];
systemSetup.f1        = 200;   %125
systemSetup.f2        = 100;    %50
systemSetup.f_obj     = 45;
systemSetup.LEDheight_reflective = 18; %16.5       % distance from DF1 LED to sample (mm)
systemSetup.LEDheight_reflective2 = 9;             % distance from DF2 LED to sample (mm)
systemSetup.N_BF      = 16;         % first 16 LEDs are BF
%%
%[ImagesIn, imageList] = LoadImages(loadDirectory);
%% reflective
[ImagesIn, imageList] = LoadImages(loadDirectory_reflective);
class(Led_Array)
%%
[sy,sx,nImgs] = size(ImagesIn);
bck = zeros(nImgs,1);
if sy>100 && sx>100
    for nn = 1:nImgs; bck(nn) = mean2(ImagesIn(1:100,1:100,nn)); end
else
    for nn = 1:nImgs; bck(nn) = mean2(ImagesIn(:,:,nn)); end    
end
thr = (max(bck)+min(bck))/2;
%%
[ImagesIn, bck] = BackgroundRemoving(ImagesIn,thr);

%%
%[O_rec, phase_rec, P_rec, err_curve] = ...
%    Algorithm_QN(ImagesIn, Led_Array, systemSetup, options,'77');
%%
[O_rec, phase_rec, P_rec, err_curve] = ...
    Algorithm_QN(ImagesIn, Led_xy_BF, systemSetup, options,'16');
% [O_rec_df, phase_rec_df, P_rec_df, err_curve_df] = ...
%     Algorithm_QN(ImagesIn_df, Led_Array, systemSetup, options,'77');

%%
O_norm = O_rec ./ max(abs(O_rec(:)));
%%
[O_denoised, phase_denoised] = BM3D_denoise_auto(O_norm, 0.12, 'complex');
%% show results

% figure;
% imagesc(abs(O_denoised));
% axis image; colormap gray; title('Amplitude');
% 
% figure;
% imagesc(phase_denoised);
% axis image; colormap gray; title('Phase');

%%
figure;
%subplot(1,2,1); imagesc(abs(O_rec)); axis image; colormap gray; title('Amplitude');
%subplot(1,2,2); imagesc(phase_rec); axis image; colormap gray; title('Phase');
%%
figure;
A = abs(O_rec);

A(isnan(A)) = 0;
A(isinf(A)) = 0;

subplot(1,2,1); imshow(A, []); title('Amplitude');
subplot(1,2,2); imshow(phase_rec, []); title('Phase');
%%
figure;
imagesc(abs(O_denoised)); axis image; colormap gray; title('Amplitude denoised');
exportgraphics(gcf, 'Amplitude_highres.png', 'Resolution', 600);

figure;
imagesc(phase_denoised); axis image; colormap gray; title('Phase denoised');
exportgraphics(gcf, 'Phase_highres.png', 'Resolution', 600);

%% =========================================================
%% Save displayed images as TIFF
%% =========================================================

saveFolder = fullfile(loadDirectory_reflective,'Reconstruction');

if ~exist(saveFolder,'dir')
    mkdir(saveFolder);
end

%% Amplitude (same display as imagesc(abs(O_denoised)))

amp_disp = mat2gray(abs(O_denoised));

imwrite( ...
    uint16(amp_disp * 65535), ...
    fullfile(saveFolder,'Amplitude_denoised_display.tiff'), ...
    'Compression','none');

%% Phase (same display as imagesc(phase_denoised))

phase_disp = mat2gray(phase_denoised);

imwrite( ...
    uint16(phase_disp * 65535), ...
    fullfile(saveFolder,'Phase_denoised_display.tiff'), ...
    'Compression','none');

fprintf('\nTIFF files saved:\n');
fprintf('%s\n',fullfile(saveFolder,'Amplitude_denoised_display.tiff'));
fprintf('%s\n',fullfile(saveFolder,'Phase_denoised_display.tiff'));