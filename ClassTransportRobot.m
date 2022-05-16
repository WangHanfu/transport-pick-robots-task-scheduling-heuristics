classdef ClassTransportRobot<handle
    
    properties
        ID
        Type %[0=transport robot, 1=pick robot]
        State %[x,y]
                        
        TaskID
        SubtaskID
        BlockID
        
        TaskSequence
        TaskCount
        
        Path
        DummyPath
        DummyLength
        
        Status %0: idle; 1: on the road; 2: on the pick station 3:picking
        Statistics
    end
    
    methods
        function obj = ClassTransportRobot()
            obj.TaskID = 0;
            obj.SubtaskID = zeros(1,2); %改为两个id，并且用任务的列向量更新状态
            obj.DummyLength = 100;
            obj.TaskCount = 0;
            obj.Status = 0;
            obj.Statistics=zeros(1,4);
        end
        
        %Initialize the robot.
        function setAttribute(obj,id,type,deliveryStation,workZone)
            obj.ID = id;
            obj.Type = type;
            obj.State = deliveryStation;
            if obj.Type == 1 %pick robot
                %obj.Workzone = [initialState(1,1)-5  initialState(1,1)+5 initialState(1,2)-1  initialState(1,2)+1 ];
                obj.Workzone = workZone;
                initialState = [workZone(1,1)+5,workZone(1,3)+2];
                obj.State = initialState;
            end
        end               
    end
end
