classdef Thorlabs_Translation_Stage_Axis < handle
    %THORLABS_TRANSLATION_STAGE Used for Controlling Motorized Translation Stage(s) with Thorlabs KDC101 Controller
    %   You could probably modify this to work with other stages...
    
    properties
        serialNo
        handle
        busy = false
    end
    
    methods
        
        function obj = Thorlabs_Translation_Stage_Axis(serialNo)
            %THORLABS_TRANSLATION_STAGE_AXIS Construct the instance with serial number of the controller
            
            % load DLL libraries
            [~] = NET.addAssembly('Replace\with\Your\Project\Directory\DLL\Thorlabs.MotionControl.DeviceManagerCLI.dll');
            [~] = NET.addAssembly('Replace\with\Your\Project\Directory\DLL\Thorlabs.MotionControl.GenericMotorCLI.dll');
            [~] = NET.addAssembly('Replace\with\Your\Project\Directory\DLL\Thorlabs.MotionControl.Tools.Common.dll');
            [~] = NET.addAssembly('Replace\with\Your\Project\Directory\DLL\Thorlabs.MotionControl.Tools.Logging.dll');
            [~] = NET.addAssembly('Replace\with\Your\Project\Directory\DLL\Thorlabs.MotionControl.KCube.DCServoCLI.dll');
            import Thorlabs.MotionControl.DeviceManagerCLI.*;
            import Thorlabs.MotionControl.KCube.DCServoCLI.*;
            import Thorlabs.MotionControl.GenericMotorCLI.Settings.*;
            % save serial numbers
            obj.serialNo = serialNo;
            % get device handles
            DeviceManagerCLI.BuildDeviceList();
            obj.handle = KCubeDCServo.CreateKCubeDCServo(obj.serialNo);
            fprintf(['-- Axis S.' obj.serialNo ' created!\n']);
        end
        
        function outputArg = Axis_Connect(obj, polling_rate)
            %AXIS_CONNECT Connect the instance to actual hardware and enable it
            
            obj.handle.Connect(obj.serialNo);
            obj.handle.WaitForSettingsInitialized(5000);
            [~] = obj.handle.LoadMotorConfiguration(obj.serialNo);
            obj.handle.StartPolling(1000/polling_rate);
            obj.handle.EnableDevice();
            fprintf(['-- Axis S.' obj.serialNo ' connected!\n']);
        end
        
        function outputArg = Axis_ShutDown(obj)
            %AXIS_SHUTDOWN Stop and disconnect to the hardware
            
            obj.handle.StopPolling();
            obj.handle.ShutDown();
            fprintf(['-- Axis S.' obj.serialNo ' disconnected.\n']);
        end
        
        function outputArg = Axis_IsHomed(obj)
            %AXIS_ISHOMED Request homing state
            
            if obj.handle.Status.IsHomed
                outputArg = 1;
            elseif obj.handle.Status.IsHoming
                outputArg = 2;
            else
                outputArg = 0;
            end
        end
        
        function outputArg = Axis_Home(obj)
            %AXIS_HOME Home this axis
            
            obj.busy = true;
            obj.handle.Home( @obj.Axis_Report );
            fprintf(['-- Axis S.' obj.serialNo ' homing.\n']);
        end
        
        function outputArg = Axis_Move(obj, position, speed, accel)
            %AXIS_MOVE Move to position given in mm
            
            obj.handle.SetVelocityParams(speed, accel);
            obj.busy = true;
            obj.handle.MoveTo(position, @obj.Axis_Report );
        end
        
        function outputArg = Axis_Return(obj, speed, accel)
            %AXIS_RETURN Return to the home position
            
            Axis_Move(obj, 0, speed, accel);
        end
        
        function outputArg = Axis_Report(obj, ~, ~)
            %AXIS_REPORT Callback
            
            fprintf(['-- Axis S.' obj.serialNo ' movement done.\n']);
            obj.busy = false;
        end
        
    end
    
    methods(Static)
        
        
        
    end
   
end

