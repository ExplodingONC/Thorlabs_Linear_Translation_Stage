
%% start
clc; close all;
clearvars -except stage; 
tic;

%% initialize
numOfAxis = 3;
serialNo_X = 'SN of your device';
serialNo_Y = 'SN of your device';
serialNo_Z = []; % Leave empty if this axis is not used
offset_X = 14.00;
offset_Y = 42.50;
offset_Z = 0;
stage = Thorlabs_Translation_Stage( numOfAxis, serialNo_X,serialNo_Y,serialNo_Z );

%% measuring parameters
step_cnt_X = 7; step_cnt_Y = 3;
step_size_X = 1.5; step_size_Y = 1.5;

%% connecting
Connect(stage,10);

%% preperation
if IsHomed(stage) ~= 1
    Home(stage);
else
    fprintf('Stage already homed.\n\n');
end
SetSoftwareHome(stage, [ offset_X, offset_Y, offset_Z ]);
Return(stage, 2.4);

%% workflow
fprintf('Movement Started!\n\n');
for step_index_Y = 1:step_cnt_Y
    pos_Y = -(step_cnt_Y-1)/2*step_size_Y + (step_index_Y-1)*step_size_Y;
    for step_index_X = 1:step_cnt_X
        pos_X = -(step_cnt_X-1)/2*step_size_X + (step_index_X-1)*step_size_X;
        pos = [ pos_X, pos_Y, 0 ];
        % stage movement
        Move(stage, [ offset_X-pos_X, offset_Y+pos_Y, offset_Z ], 2);   % X axis is invert-mounted
        fprintf( ' -- @[%4.2f %4.2f %4.2f] -- \n\n', pos );
        pause(1);
    end
end
clearvars step_index_* pos_* pos;
Return(stage, 2.4);
fprintf('Movement Finished!\n\n');

%% disconnect
ShutDown(stage); % Always shutdown the connection before exit, or you will need to restart MATLAB to release devices
toc;
