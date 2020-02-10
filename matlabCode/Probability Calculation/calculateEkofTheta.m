Nue = 20;%number of UE
theta = 0.25:.01:1;%transmission probability
Nr = 10;%number of PRB
Nt = 10;%number of timeslots
Np = 0;
PtdBm = -10;%transmit power in dbm
R = 2500;%play field radius
macCol = 1;

PDF = cell(1,length(theta));
Ek = zeros(1,length(theta));

for i = 1:length(theta)
    i
    PDF{i} = probOfKCaptures(Nue,Np,theta(i),Nr,Nt,PtdBm,R,macCol);
    
    Ek(i) = sum([0:(length(PDF{Np+1,i})-1)].*PDF{Np+1,i});
    [~,I] = max(Ek);
    
end






