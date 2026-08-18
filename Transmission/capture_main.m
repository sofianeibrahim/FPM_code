% 你已有：
% ring0 = {'77'};
% ring1 = {'66','67','68','78','88','87','86','76'};
% ring2 = {...};
% ring3 = {...};  % The large ring in your image (already ordered clockwise starting from the top-left）
% ring4 = {...};
%%
clc,clear;
%%
gain = 0;
exposure_ms = 100000;   %micro seconds
%%
s = init_serialport('COM5',115200);
%%
[vid,src] = init_camera_soft(exposure_ms,gain);
%%
% ring0 = {'77'};
% 
% ring1 = {'66','67','68','78','88','87','86','76'};
% 
% ring2 = {'56','57','58','69','79','89', ...
%          '98','97','96','85','75','65'};
% ring2_2 = {'55','56','57','58','59','69','79','89', ...
%          '99','98','97','96','95','85','75','65'};
% 
% ring3 = {'44','45','49','4a', ...
%          '5a','9a','aa', ...
%          'a9','a5','a4', ...
%          '94','54'};
% ring3_3 = {'44','45','46','47','48','49','4a', ...
%          '5a','6a','7a','8a','9a','aa', ...
%          'a9','a8','a7','a6','a5','a4', ...
%          '94','84','74','64','54'};
% 
% ring4 = {'33','34','35','36','37','38','39','3a','3b', ...
%          '4b','5b','6b','7b','8b','9b','ab','bb', ...
%          'ba','b9','b8','b7','b6','b5','b4','b3', ...
%          'a3','93','83','73','63','53','43'};



ring0 = {'77'};
ring1 = {'67','68','78','88','87','86','76','66'};
ring2 = {'56','57','58','59','69','79','89','99','98','97','96','95',...
    '85','75','65','55'};
ring3 = {'45','46','47', ...
         '48','49','4a', ...
         '5a','6a','7a', ...
         '8a','9a','aa', ...
         'a9','a8','a7', ...
         'a6','a5','a4','94','84','74','64','54','44'};
ring4 = {'34','35','36','37','38','39','3a','3b','4b', ...
         '5b','6b','7b','8b','9b','ab','bb','ba', ...
         'b9','b8','b7','b6','b5','b4','b3','a3', ...
         '93','83','73','63','53','43','33'};
ring5 = {'23','24','25','26','27','28','29','2a',...
        '2b','2c','3c','4c','5c','6c','7c','8c',...
        '9c','ac','bc','cc','cb','ca','c9','c8',...
        'c7','c6','c5','c4','c3','c2','b2','a2',...
        '92','82','72','62','52','42','32','22'};
ring6 = {'12','13','14','15','16','17','18','19',...
        '1a','1b','1c','2d','3d','4d','5d','6d',...
        '7d','8d','9d','ad','bd','cd','dc','db',...
        'da','d9','d8','d7','d6','d5','d4','d3',...
        'd2','c1','b1','a1','91','81','71','61',...
        '51','41','31','21'};
ring7 = {'03','04','05','06',...
        '07','08','09','0a','0b','3e','4e','5e',...
        '6e','7e','8e','9e','ae','be','eb','ea',...
        'e9','e8','e7','e6','e5','e4','e3','b0',...
        'a0','90','80','70','60','50','40','30'};









% 可选：打包
%rings = {ring0, ring1, ring2, ring3, ring4};
%rings = {ring0, ring1, ring2, ring3, ring4, ring5, ring6, ring7};
rings = {ring0, ring1, ring2};
%%
%BF_rings = {ring0, ring1, ring2};
%DF_rings = {ring3, ring4};


% pwm_by_ring_min ={'c00','c00','c00','c00','c00','c00','c00','c00'};
% exp_by_ring_min =[60000, 60000, 60000, 60000, 100000, 100000, 150000, 200000];
% 
% pwm_by_ring_low ={'c00','c00','c00','c00','c00','c00','c00','c00'};
% exp_by_ring_low = [100000, 100000, 100000, 100000, 150000, 150000, 200000, 250000];
% 
% pwm_by_ring_mid ={'c00','c00','c00','c00','c00','c00','c00','c00'};
% exp_by_ring_mid  =[120000, 120000, 120000, 120000, 180000 ,180000, 220000, 280000];
% 
% pwm_by_ring_high ={'c00','c00','c00','c00','c00','c00','c00','c00'};
% exp_by_ring_high =[150000, 150000, 150000, 150000, 200000, 200000, 250000, 300000];
% 
% pwm_by_ring_max ={'c00','c00','c00','c00','c00','c00','c00','c00'};
% exp_by_ring_max = [180000, 180000, 180000, 180000, 220000, 220000, 280000, 320000];

% PWM/exposure corresponding to the rings (length must match the number of rings）
%pwm_by_ring_bf = {'c00','c00','c00'};
%exp_by_ring_bf = [100000, 100000, 100000];

%pwm_by_ring_df = {'300','300'};
%exp_by_ring_df = [100000, 100000];

pwm_by_ring_min ={'c00','c00','c00'};
exp_by_ring_min =[60000, 60000, 60000];

pwm_by_ring_low ={'c00','c00','c00'};
exp_by_ring_low = [100000, 100000, 100000];

pwm_by_ring_mid ={'c00','c00','c00'};
exp_by_ring_mid  =[120000, 120000, 120000];

pwm_by_ring_high ={'c00','c00','c00'};
exp_by_ring_high =[150000, 150000, 150000];

pwm_by_ring_max ={'c00','c00','c00'};
exp_by_ring_max = [180000, 180000, 180000];

%%
%% Top-level directory = capture\capture under the current script's directory
%cd('F:\new study\Internship\Matlab project\Transmission');  % 你的工程根
cd("C:\Users\I_MSI\Documents\SUPOP\3A\IMEC_internship\FPM\Run_matlab\capture code\capture code");
thisDir  = pwd;  

rootDir = fullfile(thisDir, 'capture', 'Capture');
if ~exist(rootDir,'dir'), mkdir(rootDir); end

ts  = datestr(now,'yyyymmdd_HHMMSS');
saveRoot = fullfile(rootDir, ['capture_' ts]);   %  -> capture\capture\capture_时间戳
mkdir(saveRoot);

fprintf('所有数据保存到: %s\n', saveRoot);


%% 拍 BF flat
% opts_bf = struct('save_tag','flat_BF');
% flat_bf = capture_flat_bank(BF_rings, pwm_by_ring_bf, exp_by_ring_bf, opts_bf);
%%
% cap_bf = capture_scan(BF_rings, pwm_by_ring_bf, exp_by_ring_bf, ...
%     struct('save_root', saveRoot, 'save_tag','BF','avgPerLED',1));
% 
% %%
% % 拍 DF（RAW）
% cap_df = capture_scan(DF_rings, pwm_by_ring_df, exp_by_ring_df, ...
%     struct('save_root', saveRoot, 'save_tag','DF','avgPerLED',1));


cap_min = capture_scan(rings, pwm_by_ring_min, exp_by_ring_min, ...
    struct('save_root', saveRoot, 'save_tag','ring_min','avgPerLED',1));
cap_low = capture_scan(rings, pwm_by_ring_low, exp_by_ring_low, ...
    struct('save_root', saveRoot, 'save_tag','ring_low','avgPerLED',1));
cap_mid = capture_scan(rings, pwm_by_ring_mid, exp_by_ring_mid, ...
    struct('save_root', saveRoot, 'save_tag','ring_mid','avgPerLED',1));
cap_high = capture_scan(rings, pwm_by_ring_high, exp_by_ring_high, ...
    struct('save_root', saveRoot, 'save_tag','ring_high','avgPerLED',1));
cap_max = capture_scan(rings, pwm_by_ring_max, exp_by_ring_max, ...
    struct('save_root', saveRoot, 'save_tag','ring_max','avgPerLED',1));