
%% MAC Parameters
NR = 4;%number of PRB
NT = 4;%number of subframes
NUE = 10;%number of users
NP = 0;%number of previously discovered UE
Theta = 1;%ones(1,NUE)';%transmision probability

%% PHY Parameters
MACCol = 0;%flag for mac/phy collisions
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

params = parameterVariableMaker({NUE,NP,NR,NT,Theta});
a  = 0;
for i = 1:size(params,1)
    a = a + length(0:(params(i,1)-2));
end


data = cell(a,2);

a = 1;
for i = 1:size(params,1)%for each parameter combo
    i
    datestr(now)
    Nue = params(i,1);
    Np = params(i,2);
    Nr = params(i,3);
    Nt = params(i,4);
    theta = params(i,5);
    DataP = zeros(trials,1);
    
    for j = 1:trials%run a number of trials
        %place the UE
        angle = 2*pi*rand(Nue,1);
        r = R*sqrt(rand(Nue,1));
        userPos = [r.*cos(angle),r.*sin(angle)];
        
        %precalculate distances between them
        d = zeros(length(userPos));
        for q = 1:length(userPos)
            for w = 1:length(userPos)
                if q ~= w
                    d(q,w) = sqrt((userPos(q,1) - userPos(w,1))^2 + (userPos(q,2) - userPos(w,2))^2);
                end
            end
        end
        
        discoveryList = eye(Nue);%list of who has discovered who
        %assign PRB
        PRB = zeros(1,Nue);
        for k = 1:Nue
            if rand < theta
                PRB(k) =  randi(Nr);
            end
        end
        
        %detemine discoveries
        if MACCol == 1
            discoveryList = discoveryMAC(PRB,discoveryList,Nr,Nt);
        else
            discoveryList = discoveryPHY(PRB,discoveryList,Nr,Nt,d,Pt,thermalNoise,noiseFigure,lambda,alpha,systemLoss);
        end
        
        DataP(j) = (sum(discoveryList(1,1:end-Np),2)-1);
        
    end
    data{a,1} = [params(i,:),Np];
    data{a,2} = DataP;
    a = a+1;
end











