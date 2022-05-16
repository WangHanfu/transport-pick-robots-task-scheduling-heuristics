classdef ClassPickRobot<handle
    
    properties
        ID
        Type %[0=transport robot, 1=pick robot]
        State %[x,y]
        
        TaskID
        SubtaskID
        BlockID
        Workzone %[xmin,xmax,ymin,ymax]. only for pick robots
        
        TaskSequence
        TaskCount
        
        Path
        DummyPath
        DummyLength
        
        Status %0: idle; 1: on the road; 2: on the pick station 3:picking
        Statistics
    end
    
    methods
        function obj = ClassPickRobot()
            obj.TaskID = 0;
            obj.SubtaskID = zeros(1,2); %改为两个id，并且用任务的列向量更新状态
            obj.Workzone = zeros(1,4);
            obj.DummyLength = 100;
            obj.TaskCount = 0;
            obj.Status = 0;
            obj.Statistics=zeros(1,4);
        end
        
        %Initialize the robot.
        function setAttribute(obj,id,type,initialState,workZone)
            obj.ID = id;
            obj.Type = type;
            obj.State = initialState;
            global WarehouseMap
            if obj.Type == 1 %pick robot
                %obj.Workzone = [initialState(1,1)-5  initialState(1,1)+5 initialState(1,2)-1  initialState(1,2)+1 ];
                obj.Workzone = workZone;
                while true
                    x = randi([workZone(1,1) workZone(1,2)]);
                    y = randi([workZone(1,3) workZone(1,4)]);
                    height = WarehouseMap.Height;
                    xy2rc=@(x,y)[height+1-y;x];
                    rc = xy2rc(x,y);
                    if WarehouseMap.GridMapMat(rc(1,1),rc(2,1))==0
                        break;
                    end
                end
                initialState = [x,y];
                obj.State = initialState;
            end
        end               
    end
end
