classdef ClassMap<handle
    
    properties
        Width
        Height
        
        GridMapMat
        
        ObstacleLocations
        FreeLocations
        
        PickupStations
        RendezvousStations
        DeliveryStations
        AllStations
        
        DistanceMat
    end
    
    methods
        function obj = ClassMap(width,height,rackWidth,rackLength,rackRowNum,rackColNum,aisleWidth,crossAisleWidth,topLeftRC)
            obj.Width = width;
            obj.Height = height;
            
            rc2xy=@(r,c)[c;height+1-r];
            
            GridMapMat = zeros(height,width);
            RendezvousStationMat = zeros(height,width);
            
            %% generate grip map matrix
            %row indices
            rows = zeros(1,rackRowNum);
            for i=1:rackRowNum
                rows(1,i) = topLeftRC(1,1)+(i-1)*(rackWidth+aisleWidth);
            end
            
            %col indices
            cols=zeros(1,rackColNum*rackLength);
            rendezvousCols=zeros(1,rackColNum*rackLength/2);
            index = 1;
            index2 = 1;
            for i=1:rackColNum
                cols(1,index:index+rackLength-1) = topLeftRC(1,2)+(i-1)*(rackLength+crossAisleWidth):topLeftRC(1,2)+(i-1)*(rackLength+crossAisleWidth)+rackLength-1;
                rendezvousCols(1,index2:index2+rackLength/2-1) = topLeftRC(1,2)+(i-1)*(rackLength+crossAisleWidth):2:topLeftRC(1,2)+(i-1)*(rackLength+crossAisleWidth)+rackLength-1;
                index = index+rackLength;
                index2 = index2+rackLength/2;
            end
            
            % generate racks, stations
            for i=rows
                GridMapMat(i,cols)=1;
                if i~=min(rows)
                    RendezvousStationMat(i-1,rendezvousCols)=1;
                end
                if i~=max(rows)
                    RendezvousStationMat(i+1,rendezvousCols)=1;
                end
            end
            
            %rack locations (x,y)
            [R,C]=find(GridMapMat==1);
            podNum=size(R,1);
            ObstacleLocations = zeros(podNum,2);
            for i=1:podNum
                ObstacleLocations(i,:)=rc2xy(R(i,1),C(i,1));
            end
            
            % all free locations (x,y)
            [R,C]=find(GridMapMat==0);
            freeNum=size(R,1);
            FreeLocations = zeros(freeNum,2);
            for i=1:freeNum
                FreeLocations(i,:)=rc2xy(R(i,1),C(i,1));
            end
            
            %rendezvous stations
            [R,C]=find(RendezvousStationMat==1);
            rendezvousNum = size(R,1);
            RendezvousStations=zeros(rendezvousNum,2);
            for i=1:rendezvousNum
                RendezvousStations(i,:)=rc2xy(R(i,1),C(i,1));
            end
            
            PickupStations = RendezvousStations;
            PickupStations(:,1) = PickupStations(:,1)+1;
            
            %delivery stations
            DeliveryStationMat = zeros(height,width);
            DeliveryStationMat(1,:) = 1;
            DeliveryStationMat(end,:) = 1;
            DeliveryStationMat(:,1) = 1;
            DeliveryStationMat(:,end) = 1;
            
            [R,C]=find(DeliveryStationMat==1);
            deliveryStationNum=size(R,1);
            DeliveryStations=zeros(deliveryStationNum,2);
            for i=1:deliveryStationNum
                DeliveryStations(i,:)=rc2xy(R(i,1),C(i,1));
            end
            
            obj.GridMapMat = GridMapMat;
            obj.ObstacleLocations = ObstacleLocations;
            obj.FreeLocations = FreeLocations;
            obj.RendezvousStations = RendezvousStations;
            obj.PickupStations = PickupStations;
            obj.DeliveryStations = DeliveryStations;
            obj.AllStations = [RendezvousStations;PickupStations;DeliveryStations];
            size(obj.AllStations,1)
            size(obj.FreeLocations,1)
            % this function is very time-consuming, so the map can be generated
            % once and stored.
            %obj.generateDistanceMat();
        end
        function generateDistanceMat(obj)
            stationNum = size(obj.AllStations,1);
            distanceMat = zeros(stationNum);
            for i=1:stationNum
                for j=1:stationNum
                    if i==j
                        continue;
                    elseif i<j
                        path = AlgSinglePlanner(obj.GridMapMat,obj.AllStations(i,:),obj.AllStations(j,:),0,[]);
                        distanceMat(i,j)=size(path,1)-1;
                        disp(obj.AllStations(i,:));
                        disp(obj.AllStations(j,:));
                        fprintf("***********%d,%d,%d\n",i,j,distanceMat(i,j));
                    else
                        distanceMat(i,j)=distanceMat(j,i);
                    end
                end
            end
            obj.DistanceMat = distanceMat;
        end
        
        function plotMap(obj)
            sz=get(0,'screensize');
            sz(1,2) = 10;
            sz(1,4) = 680;
            h=figure('outerposition',sz);
            assignin('base','h',h); %in case of any callback errors.
            %title('Heterogeneous Robotic Order Fulfillment System');
            hold on;
            grid on;
            set(gca,'xtick',0:1:obj.Width);
            set(gca,'ytick',0:1:obj.Height);
            axis equal;
            axis([0 obj.Width+1 0 obj.Height+1]);
            axis manual;
            obstacleMarkerSize = 11;
            stationMarkerSize = obstacleMarkerSize;
            stationColor = [0.8 0.8 0.8];
            
            rectangle('Position', [0,0,obj.Width+1,obj.Height+1],'lineWidth',5);
            
            plot(obj.ObstacleLocations(:,1),obj.ObstacleLocations(:,2),'square','MarkerEdgeColor','k','MarkerFaceColor',[0 0 0],'MarkerSize',obstacleMarkerSize);
            hold on;
            plot(obj.RendezvousStations(:,1),obj.RendezvousStations(:,2),'square','MarkerEdgeColor',stationColor,'MarkerFaceColor',stationColor,'MarkerSize',stationMarkerSize);
            hold on;
            plot(obj.PickupStations(:,1),obj.PickupStations(:,2),'square','MarkerEdgeColor',stationColor,'MarkerFaceColor',[1 1 1 ],'MarkerSize',stationMarkerSize);
            hold on;
            plot(obj.DeliveryStations(:,1),obj.DeliveryStations(:,2),'square','MarkerEdgeColor',stationColor,'MarkerFaceColor',stationColor,'MarkerSize',stationMarkerSize);
            
%             workZones = obj.WorkZones;
%             for i=1:size(workZones,1)
%                 %rectangle('Position', [workZones(i,1)-0.5,workZones(i,3)+0.5,workZones(i,2)-workZones(i,1)+1,workZones(i,4)-workZones(i,3)-1],'lineWidth',1,'lineStyle','-','FaceColor',[0.95 0.95 0.95],'edgeColor','none');
%                 %rectangle('Position', [workZones(i,1)-0.5,workZones(i,3)+0.5,workZones(i,2)-workZones(i,1)+2,workZones(i,4)-workZones(i,3)-1.2],'lineWidth',1,'lineStyle','-','edgeColor',[0 0 1]);
%                 rectangle('Position', [workZones(i,1)-0.5,workZones(i,3)-0.5,workZones(i,2)-workZones(i,1)+1,workZones(i,4)-workZones(i,3)+1],'lineWidth',1,'lineStyle','-','edgeColor',[0 0 1]);                
%             end
        end
        
    end %methods
end