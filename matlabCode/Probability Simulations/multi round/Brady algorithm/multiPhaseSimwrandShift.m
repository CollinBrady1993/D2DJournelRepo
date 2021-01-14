
%brady

rng('shuffle')

%% MAC Parameters
NR = [20];%number of PRB
NT = [10];%number of subframes
NUE = [10:5:200];%number of users

%% PHY Parameters
MACCol = 1;%flag for mac/phy collisions
PtdBm = -10;%dBm
Pt = (10^(PtdBm/10))/(2*180000*1000);%W/Hz, power spectral density
fc = 788000000;%hz, this is band 14
lambda = 299792458/fc;%wavelength
noiseFigure = 1;
thermalNoise = 3.98107e-21;%W/Hz, power spectral density
alpha = 2;%coeficient of attenuation
systemLoss = 1;
R = 2500^2;


trials = 1000000;
%.51,137;.5025,522;
initialw1 = .1;
initialw2 = 2.5;
trainingSequence = [1,.5,.75,.25];
Epsilon = [1e-3];
eta1 = .1;%learning rate
eta2s = 99*eta1;
AETA = [30];
%b = a/2;
%eta2 = (eta2s*erfc(([1:5000]-a)/b)/2 + eta1);

AverageLength = [4]*length(trainingSequence);
StopTimer = [1]*length(trainingSequence);

params = parameterVariableMaker({NUE,initialw1,initialw2,NR,NT,AETA,Epsilon,AverageLength,StopTimer});
for i = size(params,1):-1:1
    if params(i,9)>params(i,8) || params(i,5) > params(i,4) || mod(params(i,4),params(i,5))>0
        params(i,:) = [];
    end
end


data = cell(size(params,1),5);

for i = 1:size(params,1)
    if mod(i,1) == 0
        i 
        datestr(now)
    end
    Nue = params(i,1);
    Nr = params(i,4);
    Nt = params(i,5);
    aEta = params(i,6);
    bEta = aEta/2;
    epsilon = params(i,7);
    averageLength = params(i,8);
    stopTimer = params(i,9);
    eta2 = (eta2s*erfc(([1:10000]-aEta)/bEta)/2 + eta1);
    randShift = poissrnd(0.1,1,Nue);%randi(4,1,Nue)-1;%poissrnd(0.1,1,Nue);%
    
    DataP = cell(ceil(trials/Nue),1);
    thetaData = cell(ceil(trials/Nue),1);
    descentData = cell(ceil(trials/Nue),1);
    NDCTData = cell(ceil(trials/Nue),1);
    
        for j = 1:ceil(trials/Nue)
            periods = 10000;
            periodData = zeros(Nue,periods);
            periodThetaData = zeros(Nue,periods);
            periodDescentData = zeros(Nue,3*periods);
            if mod(j,100) == 0
                i
                j
            end
            
            %% generate user positions
            
            angle = 2*pi*rand(Nue,1);
            r = sqrt(R*rand(Nue,1));
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
            
            theta = 1*ones(Nue,1);%(1/params(i,3))*ones(Nue,1);
            
            w1 = params(i,2)*ones(size(r,1),1);
            w2 = params(i,3)*ones(size(r,1),1);
            
            training = ones(size(r,1),1);
            stableCount = zeros(size(r,1),1);
            w2BarOld = zeros(size(r,1),1);
            w2BarNew = zeros(size(r,1),1);
            
            
            startTheta = ones(size(r,1),2);%this is used to calculate the dtheta for the kick
            
            while sum(sum(discoveryList)) < Nue^2%period <= periods %until a max period has been reached
                
                PRB = zeros(1,Nue);
                for k = 1:Nue
                    if rand < theta(k)
                        PRB(k) =  randi(Nr);
                    end
                end
                
                if MACCol == 1
                    [discoveryList,Nm] = discoveryMAC(PRB,discoveryList,Nr,Nt);
                else
                    [discoveryList,Nm] = discoveryPHY(PRB,discoveryList,Nr,d,Pt,thermalNoise,noiseFigure,lambda,alpha,systemLoss);
                end
                
                periodData(:,period) = sum(discoveryList,2)-1;%doesnt count itself
                periodThetaData(:,period) = theta(:);
                
                for k = 1:length(PRB)
                    Nm(k) = Nm(k)/Nr;
                    %%{
                    if training(k)
                        [w1(k),w2(k)] = thetaUpdate(Nm(k),theta(k),w1(k),w2(k),period,eta1,eta2(period),aEta,bEta);
                        if period >= averageLength
                            %w1Bar = mean([w1(k),periodDescentData(1,(5*(period-1)-1):-5:(5*(period-3)-1))]);
                            %w2BarNew(k) = mean([w2(k),periodDescentData(k,(6*(period-1)-1):-6:(6*(period-(averageLength-1))-1))]);
                            w2BarNew(k) = mean([w2(k),periodDescentData(k,(7*(period-1)-2):-7:(7*(period-(averageLength-1))-2))]);
                            if abs(w2BarNew(k) - w2BarOld(k)) < epsilon
                                stableCount(k) = stableCount(k) + 1;
                                if stableCount(k) >= stopTimer
                                    theta(k) = min(max(1/(w2BarNew(k)),.25),1);
                                    training(k) = 0;
                                else
                                    theta(k) = trainingSequence(mod(period+randShift(k),4)+1);
                                end
                            else
                                stableCount(k) = 0;
                                theta(k) = trainingSequence(mod(period+randShift(k),4)+1);
                            end
                            
                            w2BarOld(k) = w2BarNew(k);
                            
                        else %first 4 periods are always training
                            theta(k) = trainingSequence(mod(period+randShift(k),4)+1);
                        end
                    end
                    %}
                    
                end
                
                periodDescentData(:,(7*(period-1) + 1):(7*period)) = [theta,PRB',Nm',w1,w2,w2BarOld,training];
                
                
                period = period + 1;
            end
            periodData(:,period:end) = [];
            periodThetaData(:,period:end) = [];
            %periodDescentData(:,(7*(period-1)+1):end) = [];
            %DataP{j,:} = periodData;
            thetaData{j,:} = periodThetaData;
            %descentData{j,:} = periodDescentData;
            
            temp = zeros(size(periodData,1),1);
            for k = 1:size(periodData,1)
                temp(k) = find(periodData(k,:) == Nue-1,1,'first');
            end
            NDCTData{j,:} = temp;
            
            
        end
        data{i,1} = params(i,:);
        %data{i,2} = cell2mat(thetaData);
        %temp = cell2mat(thetaData);
        %data{i,3} = temp(:,end);%theta^A
        %data{i,3} = cell2mat(descentData);
        
        %NDCT
        data{i,4} = NDCTData;
        
        %training completion time
        %{
        temp = cell2mat(descentData);
        temp2 = zeros(size(temp,1),1);
        for j = 1:size(temp,1)
            temp2(j) = find(temp(j,7:7:end) == 0,1,'first');
        end
        
        data{i,5} = temp2;
        %}
end

