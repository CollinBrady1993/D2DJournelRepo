
%mosbah

%% MAC Parameters
Nr = 20;%number of PRB
Nt = 10;%number of subframes
NUE = 120;%number of users
Theta = .25;

%% PHY Parameters
R = 2500^2;

trials = 1000000;

params = parameterVariableMaker({NUE,Theta});

data = cell(size(params,1),4);

for i = 1:size(params,1)
    if mod(i,1) == 0
        i
        datestr(now)
    end
    Nue = params(i,1);
    theta = params(i,2:end)*ones(Nue,1);
    DataP = cell(ceil(trials/Nue),1);
    
    %DataDiscList = cell(ceil(trials/Nue),1);
    NDCTData = cell(ceil(trials/Nue),1);
    
    
    
    for j = 1:ceil(trials/Nue)
        periodData = zeros(Nue,10000);%this is oversized, excess 0's will be erased later.
        thetaData = zeros(Nue,10000);%this is oversized, excess 0's will be erased later.
        %DiscListData = cell(1,10000);
        
        
        
        if mod(j,100) == 0
            j
        end
        
        angle = 2*pi*rand(Nue,1);
        r = R*sqrt(rand(Nue,1));
        userPos = [r.*cos(angle),r.*sin(angle)];
        
        d = zeros(length(userPos));
        for q = 1:length(userPos)
            for w = 1:length(userPos)
                if q ~= w
                    d(q,w) = sqrt((userPos(q,1) - userPos(w,1))^2 + (userPos(q,2) - userPos(w,2))^2);
                end
            end
        end
        
        period = 1;%initialize period number
        discoveryList = eye(Nue);%list of who has discovered who
        
        while sum(sum(discoveryList)) < Nue^2%until all UE have discovered all other UE
            
            PRB = zeros(1,Nue);
            for k = 1:Nue
                if rand < theta(k)
                    PRB(k) =  randi(Nr);
                end
            end
            
            discoveryList = discoveryMAC(PRB,discoveryList,Nr,Nt);
            
            periodData(:,period) = sum(discoveryList,2)-1;%doesnt count itself
            thetaData(:,period) = theta;
            for k = 1:Nue
                
                theta(k) = mosbahTheta(periodData(k,period),Nr,Nt);
                
            end
            
            period = period + 1;
            
            
        end
        
        periodData(:,period:end) = [];
        thetaData(:,period:end) = [];
        %DiscListData(period:end) = [];
        DataP{j,:} = {periodData,thetaData};
        %DataDiscList{j,:} = DiscListData;
        
        temp = zeros(size(periodData,1),1);
        for k = 1:size(periodData,1)
            temp(k) = find(periodData(k,:) == Nue-1,1,'first');
        end
        NDCTData{j,:} = temp;
        
        
    end
    
    
    data{i,1} = params(i,:);
    %depending on how many trials/parameters you test
    %over I found that you sometimes run out of memory, causing the sim to
    %stop prematurely, a simple solution is to not record statistics of
    %certain quantities, in this case only recording NDCT.
    data{i,2} = DataP;
    %data{i,3} = DataDiscList;
    data{i,4} = NDCTData;
end











