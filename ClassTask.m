classdef ClassTask<handle
    
    properties
        TaskID    
        State %0=unallocated, 1=allocated, 2=finished. 初始：0，任务分配器置1，TR置2.  
        PickupSubtaskNum
        PickupSubtaskMat
        DeliverySubtaskVec                
        MinRouteTime           
    end
    
    methods
        function obj = ClassTask()
        end
        
        function setAttribute(obj,taskID,pickupSubtaskNum,pickupStations,pickupZones,deliveryStation,minRouteTime)
            obj.TaskID = taskID;   
            obj.State = 0;
            obj.PickupSubtaskNum = pickupSubtaskNum;
            global WarehouseMap
            if minRouteTime==0                
                [route,obj.MinRouteTime] = TSPOptimization(pickupStations,deliveryStation);
            else
                route = 1:pickupSubtaskNum;
                route = route';
                obj.MinRouteTime = minRouteTime;
            end
           %% pickup tasks
            %8 colomns. (taskID,subtaskID,TRID,PRID,k-th ID,x,y,ptime,stationID)
            pickupSubtasks = zeros(pickupSubtaskNum,9);
            multipleSubtasksInZones = zeros(max(pickupZones),1);
            multipleSubtasksInZones
            for i=1:pickupSubtaskNum
                pickupSubtasks(i,1) = taskID; %taskID
                pickupSubtasks(i,2) = i; %subtaskID
                
                pickupSubtasks(i,3) = 0; % yet to be allocated to a TR
                zoneID = pickupZones(route(i),1);
                pickupSubtasks(i,4) =  zoneID; %PRID or zone ID
                multipleSubtasksInZones(zoneID,1) = multipleSubtasksInZones(zoneID,1)+1;
                pickupSubtasks(i,5) = multipleSubtasksInZones(zoneID,1); %k-th subtask in the same zone
                
                pickupSubtasks(i,6:7) = pickupStations(route(i),:); %[x y]                  
                pickupSubtasks(i,8) = randi([10 20]);  % ptime,uniform distribution
                [indices,~]=ismember(WarehouseMap.AllStations,pickupSubtasks(i,6:7),'rows');
                pickupSubtasks(i,9) = find(indices == 1);
            end
            obj.PickupSubtaskMat = pickupSubtasks;
            
           %% delivery task
            deliverySubtask = zeros(1,9);
            deliverySubtask(1,1) = taskID; %taskID
            deliverySubtask(1,2) = 0; %subtaskID
            deliverySubtask(1,3:5) = [0 0 0]; %
            deliverySubtask(1,6:7) = deliveryStation; %[x y]
            deliverySubtask(1,8) = randi([10 20]);  % uniform distribution
            
            [indices,~]=ismember(WarehouseMap.AllStations,deliverySubtask(1,6:7),'rows');
            deliverySubtask(1,9) = find(indices == 1);
                
            obj.DeliverySubtaskVec = deliverySubtask;                      
        end        
        function setOperateTimes(obj, pickupTimeVec,deliveryTime)
            obj.PickupSubtaskMat(:,8) = pickupTimeVec;
            obj.DeliverySubtaskVec(1,8) = deliveryTime;
         end
    end %methods
end