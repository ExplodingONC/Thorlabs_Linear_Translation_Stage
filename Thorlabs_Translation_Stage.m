classdef Thorlabs_Translation_Stage < handle
    %THORLABS_TRANSLATION_STAGE Used for Controlling Motorized Translation Stage(s) with Thorlabs KDC101 Controller
    %   You could probably modify this to work with other stages...
    
    properties
        numOfAxis = 3
        numOfAxisUsed = 0
        serialNo
        initialized
        axisObj
        softwareHomePos
    end
    
    methods
        
        function obj = Thorlabs_Translation_Stage(axisCount, varargin)
            %THORLABS_TRANSLATION_STAGE Construct the instance with serial numbers of the controllers, can be skipped with empty input []
            obj.numOfAxis = axisCount;
            narginchk(obj.numOfAxis+1, obj.numOfAxis+1);
            % create vars
            obj.axisObj = cell(1, obj.numOfAxis);
            obj.serialNo = cell(1, obj.numOfAxis);
            obj.initialized = cell(1, obj.numOfAxis);
            obj.softwareHomePos = zeros(1, obj.numOfAxis);
            % save serial numbers
            for i = 1:obj.numOfAxis
                obj.serialNo{i} = varargin{i};
                if ~isempty(obj.serialNo{i})
                    obj.initialized{i} = true;
                    obj.numOfAxisUsed = obj.numOfAxisUsed + 1;
                else
                    obj.initialized{i} = false;
                end
            end
            % get device objects
            for i = 1:obj.numOfAxis
                if obj.initialized{i}
                    fprintf(['Stage Axis No.' num2str(i) ' S.' obj.serialNo{i} ' confirmed.\n']);
                    obj.axisObj{i} = Thorlabs_Translation_Stage_Axis(obj.serialNo{i});
                else
                    fprintf(['Stage Axis No.' num2str(i) ' ignored!\n']);
                end
            end
            fprintf('\n');
        end
        
        function outputArg = Connect(obj, polling_rate)
            %CONNECT Connect the instance to actual hardware(s) and enable them
            
            for i = 1:obj.numOfAxis
                if obj.initialized{i}
                    fprintf(['Stage Axis No.' num2str(i) ' S.' obj.serialNo{i} ' connecting...\n']);
                    Axis_Connect(obj.axisObj{i}, polling_rate);
                end
            end
            fprintf('\n');
            pause(0.5);
        end
        
        function outputArg = ShutDown(obj)
            %SHUTDOWN Stop and disconnect to the hardware(s)
            
            for i = 1:obj.numOfAxis
                if obj.initialized{i}
                    Axis_ShutDown(obj.axisObj{i});
                end
            end
        end
        
        function outputArg = IsHomed(obj)
            %ISHOMED Request homing state
            
            homed_count = 0;
            homing_count = 0;
            for i = 1:obj.numOfAxis
                if obj.initialized{i}
                    if Axis_IsHomed(obj.axisObj{i}) == 1
                        homed_count = homed_count + 1;
                    elseif Axis_IsHomed(obj.axisObj{i}) == 2
                        homing_count = homing_count + 1;
                    end
                end
            end
            if homed_count + homing_count < obj.numOfAxisUsed
                outputArg = 0;
            elseif homed_count == obj.numOfAxisUsed
                outputArg = 1;
            else
                outputArg = 2;
            end
        end
        
        function outputArg = Home(obj)
            %HOME Home all axises
            
            % issue homing commands
            for i = 1:obj.numOfAxis
                if obj.initialized{i}
                    fprintf(['Stage Axis No.' num2str(i) ' start homing...\n']);
                    Axis_Home(obj.axisObj{i});
                end
            end
            % wait for finish
            time_stamp = tic;
            while true
                pause(0.01);
                stage_busy = false;
                for i = 1:obj.numOfAxis
                    if obj.initialized{i}
                        stage_busy = stage_busy || obj.axisObj{i}.busy;
                    end
                end
                time_elapsed = toc(time_stamp);
                if ~stage_busy
                    fprintf('Stage Moving Completed.\n\n');
                    break;
                end
                if time_elapsed > 120
                    fprintf('Stage Moving Time Out.\n\n');
                    break;
                end
            end
            fprintf('Stage Axises Homing Completed.\n\n');
        end
        
        function outputArg = SetSoftwareHome(obj, softwareHomePos)
            %SETSOFTWAREHOME Set the position for Return function
            
            obj.softwareHomePos = softwareHomePos;
        end
        
        function outputArg = Move(obj, position, varargin)
            %MOVE Move to position given by the 1x3 array measured in mm
            
            % check for acceleration input
            narginchk(2, 4);
            if nargin == 2
                speed = 2.4;
                accel = 1.5;
            elseif nargin == 3
                speed = varargin{1};
                accel = 1.5;
            else
                speed = varargin{1};
                accel = varargin{2};
            end
            % calculate position difference
            currentPos = zeros(1,obj.numOfAxis);
            direction = zeros(1,obj.numOfAxis);
            for i = 1:obj.numOfAxis
                if obj.initialized{i}
                    currentPos(i) = System.Decimal.ToDouble(obj.axisObj{i}.handle.Position);
                end
            end
            posDifference = position - currentPos;
            if normest(posDifference) < 0.0005
                posDifference = ones(1,obj.numOfAxis);
            end
            fprintf('Stage Moving from [ ');
            for i = 1:obj.numOfAxis
                fprintf('%7.4f ', currentPos(i));
            end
            fprintf('] to [ ');
            for i = 1:obj.numOfAxis
                fprintf('%7.4f ', position(i));
            end
            fprintf('].\n');
            % calculate movement direction vector
            for i = 1:obj.numOfAxis
                if obj.initialized{i}
                    if abs(posDifference(i)) < 0.0005
                        direction(i) = 1;
                    else
                        direction(i) = abs(posDifference(i))/normest(posDifference);
                        direction(i) = min(direction(i),1);
                    end
                end
            end
            % issue movement commands
            for i = 1:obj.numOfAxis
                if obj.initialized{i}
                    Axis_Move(obj.axisObj{i}, position(i), speed*direction(i), accel*direction(i));
                end
            end
            % wait for finish
            time_stamp = tic;
            while true
                pause(0.01);
                stage_busy = false;
                for i = 1:obj.numOfAxis
                    if obj.initialized{i}
                        stage_busy = stage_busy || obj.axisObj{i}.busy;
                    end
                end
                time_elapsed = toc(time_stamp);
                if ~stage_busy
                    fprintf('Stage Moving Completed.\n\n');
                    break;
                end
                if time_elapsed > (normest(posDifference)/speed+5)
                    fprintf('Stage Moving Time Out.\n\n');
                    break;
                end
            end
        end
        
        function outputArg = Return(obj, varargin)
            %RETURN Return to the home position
            
            narginchk(1, 2);
            if nargin == 1
                speed = 2.4;
            else
                speed = varargin{1};
            end
            
            Move(obj, obj.softwareHomePos, speed);
        end
    end
end

