%this script simulates the probability of collision given a Nue
%undiscovered UE and Np previously discovered UE occupy a PRB. it then
%writes these probabilties to a file for use in the probability
%calculations folder.

NUE = 3:31;%number of other undiscovered UE
NP = [0,1,2,5,10];%number of previously discovered UE
PtdBm = -10;
Radius = 5000;

fc = 788000000;%hz, this is band 14
lambda = 299792458/fc;%wavelength
noiseFigure = 1;
thermalNoise = 3.98107e-21;%W/Hz, power spectral density
alpha = 2;%coeficient of attenuation
systemLoss = 1;

trials = 1000000;

params = parameterVariableMaker({NUE,NP,Radius,PtdBm});
toRemove = [];
for i = 1:size(params,1)
    if params(i,2) >= (params(i,1) - 1) || (params(i,1) - params(i,2)) > 21
        toRemove = [toRemove;i];
    end
end
params(toRemove,:) = [];

%{
Nue = params(:,1)-1;
Np = params(:,2);
PtdBm = params(:,4);
R = params(:,3);
%}

pCol = zeros(size(params,1),1);

for i = 1:size(params,1)%for each parameter combo
    i
    datestr(now)
    Nue = params(i,1);
    Np = params(i,2);
    Nr = 1;
    Nt = 1;
    theta = 1;
    R = params(i,3);
    ptdBm = params(i,4);
    Pt = (10^(ptdBm/10))/(2*180000*1000);%W/Hz, power spectral density
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
        PRB = [0,ones(1,Nue-1)];
        
        %detemine discoveries(always phy)
        discoveryList = discoveryPHY(PRB,discoveryList,Nr,Nt,d,Pt,thermalNoise,noiseFigure,lambda,alpha,systemLoss);
        
        DataP(j) = (sum(discoveryList(1,1:end-Np),2)-1);%minus 1 because it cannot discover itself
        
    end
    
    pCol(i) = mean(DataP);
    
end

%these versions of the parameters are for the saved file
Nue = params(:,1)-1;
Np = params(:,2);
PtdBm = params(:,4);
R = params(:,3);

T = table(Nue,Np,PtdBm,R,pCol);
writetable(T,'pColData.txt');



















