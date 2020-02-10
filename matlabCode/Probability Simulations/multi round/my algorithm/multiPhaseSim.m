
%% MAC Parameters
NR = 10;%number of PRB
NT = 10;%number of subframes
NUE = 4:50;%number of users

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

trials = 10000;

initialw1 = .6;%1.5;
initialw2 = 1.8;%.95;
initialw3 = 1.8;%.4;

params = parameterVariableMaker({NUE,initialw1,initialw2,initialw3,NR,NT});
data = cell(size(params,1),5);

for i = 1:size(params,1)
    if mod(i,10) == 0
        i 
        datestr(now)
    end
    Nue = params(i,1);
    Nr = params(i,5);
    Nt = params(i,6);
    DataP = cell(ceil(trials/Nue),1);
    thetaData = cell(ceil(trials/Nue),1);
    descentData = cell(ceil(trials/Nue),1);
       
        for j = 1:ceil(trials/Nue)
            periods = 1000;
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
            
            theta = 1*ones(Nue,1);
            
            w1 = params(i,2)*ones(size(r,1),1);
            w2 = params(i,3)*ones(size(r,1),1);
            w3 = params(i,4)*ones(size(r,1),1);
            
            
            while period <= periods %until a max period has been reached
                
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
                    [w1(k),w2(k),w3(k)] = thetaUpdate(Nm(k)/(Nr*(double(PRB(k)>0)*(1-1/Nt) + double(PRB(k)==0)*1)),theta(k),w1(k),w2(k),w3(k),0);
                    
                    x = .25:.01:1;
                    y = (-w1(k)*x.^2 + w2(k)*x).*exp(-w3(k)*x);
                    [~,I] = max(y);
                    theta(k) = x(I);%round(4*x(I))/4;
                end
                
                periodDescentData(:,(6*(period-1) + 1):(6*period)) = [theta,PRB',Nm',w1,w2,w3];
                
                
                period = period + 1;
            end
            periodData(:,period:end) = [];
            periodThetaData(:,period:end) = [];
            periodDescentData(:,(6*(period-1)+1):end) = [];
            DataP{j,:} = periodData;
            thetaData{j,:} = periodThetaData;
            descentData{j,:} = periodDescentData;
        end
        data{i,1} = params(i,:);
        data{i,2} = mean(cell2mat(thetaData));
        data{i,3} = var(cell2mat(thetaData));
        
        
        temp = cell2mat(thetaData);
        temp2 = cell2mat(descentData);
        data{i,4} = [temp(:,end),temp2(:,(end-2):end)];
        
        temp = cell2mat(DataP);
        temp2 = zeros(size(temp,1),1);
        for j = 1:size(temp,1)
            temp2(j) = find(temp(j,:) == Nue-1,1,'first');
        end
        
        data{i,5} = temp2;
        
end

