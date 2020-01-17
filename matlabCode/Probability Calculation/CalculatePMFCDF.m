%Calculates both the PMF and CDF of the parameters listed below
Nue = 10;%number of UE
theta = 1;%transmission probability
Nr = 12;%number of PRB
Nt = 4;%number of timeslots
PtdBm = -10;%transmit power in dbm
R = 5000;%play field radius

PMFCalc = zeros(Nue,min(Nue,Nr+1));

for i = 0:Nue-1
    disp(strcat('Calculating PMF: ',num2str(i+1),'/',num2str(Nue)))
    datestr(now)
    temp = probOfKCaptures(Nue,i,theta,Nr,Nt,PtdBm,R,macCol);
    PMFCalc(i+1,:) = [temp,zeros(1,size(PMFCalc,2) - length(temp))];
end
clear('temp','i')


T = zeros(Nue,Nue);%this is the state transition matrix
T(1,:) = [PMFCalc(1,:),zeros(1,Nue-length(PMFCalc(1,:)))];
T(end,end) = 1;
for i = 2:(size(PMFCalc,1)-1)
    T(i,i:(i+length(PMFCalc(i,:))-1)) = PMFCalc(i,:);
end
T = T(:,1:Nue);

CDFCalc = 0;%this will store the CMF
i = 1;
tempT = T;
while tempT(1,end) < .9999%some threshold close to 1
    tempT = T^i;
    CDFCalc = [CDFCalc,tempT(1,end)];
    i = i+1;
end

