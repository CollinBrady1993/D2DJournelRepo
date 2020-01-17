
%% MAC Parameters
Nr = 12;%number of PRB
Nt = 4;%number of subframes
NUE = 10;%number of users
Theta = ones(1,40)';

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
R = 2500;

trials = 10000;

params = parameterVariableMaker({NUE,Theta});

data = cell(size(params,1),2);

for i = 1:size(params,1)
    if mod(i,10) == 0
        i
        datestr(now)
        
    end
    Nue = params(i,1);
    theta = params(i,2:end);
    DataP = cell(ceil(trials/Nue),1);
    
    for j = 1:ceil(trials/Nue)
        periodData = zeros(Nue,10000);%this is oversized, excess 0's will be erased later.
        
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
            
            if MACCol == 1
                discoveryList = discoveryMAC(PRB,discoveryList,Nr,Nt);
            else
                discoveryList = discoveryPHY(PRB,discoveryList,Nr,Nt,d,Pt,thermalNoise,noiseFigure,lambda,alpha,systemLoss);
            end
            
            periodData(:,period) = sum(discoveryList,2)-1;%doesnt count itself
            period = period + 1;
            
            
        end
        
        periodData(:,period:end) = [];
        DataP{j,:} = periodData;
        
    end
    data{i,1} = params(i,:);
    data{i,2} = DataP;
end











