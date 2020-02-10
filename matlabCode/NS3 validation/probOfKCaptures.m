function[fk] = probOfKCaptures(Nue,Np,theta,Nr,Nt,PtdBm,R,macCol)
%calculates the probability of K captures given Nue, Np, theta, Nr, Nt, 
%PtdBm, and R. Parameters are:
%Nue: number of UE
%Np: number of previously discovered UE, 0 to Nue-2
%theta: transmit probability, 0 to 1
%Nr: number of PRB used in discovery
%Nt: number of subframes used in discovery
%PtdBm: transmit power in dBm
%R: radius of area where UE can be placed
%macCol: flag to indicate if collisions are mac based(1) or phy based(0)

%% initialization
fk = zeros(1,min(Nue-Np,Nr+1));

%% grabbing the colision probabilities and A data
colProbLookup = readtable('pColData.txt');
pCol = ones(Nue-1,Np+1);%the rows represent Nue, and the columns Nb
pCol(1,1) = 0;%this is the case that a PRB is occupied by one undiscovered UE
for i = 2:size(pCol,1)-1%for NUE
    for j = 0:Np%the reason Nb ranges from 0:Nu while Na ranges 1:Nu is that if Na = 0 Pdisk(k) = 0 for all k
        if i > j
            pCol(i,j+1) = colProbLookup.pCol(colProbLookup.Nue == i & colProbLookup.Np == j & colProbLookup.R == R & colProbLookup.PtdBm == PtdBm);
        end
    end
end

if macCol == 1
    pCol = ceil(pCol);%makes all multi-occupancy prb collisions, akin to mac collisions
end

%read in all possible A values
A = cell(Nue-1,Np+1,min(Nue-1,Nr));

for i = 1:(Nue)
    for j = 0:min(i-1,Np+1)
        for k = 1:min(i,min(Nue,Nr))
            string = strcat('AData/Nu',num2str(i),',Np',num2str(j),',r',num2str(k),'.csv');
            A{i,j+1,k} = csvread(string);
        end
    end
end


%% the actual calculation
for Nut = 0:Nue-Np-1%number of undiscovered UE which transmit
    PNut = binopdf(Nut,Nue-Np-1,theta);
    if PNut > 0
        for Npt = 0:Np%number of discovered UE which transmit
            PNpt = binopdf(Npt,Np,theta);
            if PNpt > 0
                fk2 = zeros(1,min(Nue-Np,Nr+1));
                for Nud = 0:Nut%number of transmitting UE which experience duplex
                    
                    PNud = binopdf(Nud,Nut,1/Nt);
                    
                    if Nud < Nut
                        for Npd = 0:Npt
                            
                            PNpd = binopdf(Npd,Npt,1/Nt);
                            fkTemp = PDiscovery(Nut-Nud,Npt-Npd,Nr-(Nr/Nt),pCol,A(Nut + Npt - Nud - Npd,Npt - Npd + 1,:));
                            fkTemp = [fkTemp,zeros(1,min(Nue-Np,Nr+1)-length(fkTemp))];
                            fk2 = fk2 + PNud*PNpd*fkTemp;
                        end
                    elseif Nud == Nut
                        for Npd = 0:Npt
                            
                            PNpd = binopdf(Npd,Npt,1/Nt);
                            fkTemp = 1;
                            fkTemp = [fkTemp,zeros(1,min(Nue-Np,Nr+1)-length(fkTemp))];
                            fk2 = fk2 + PNud*PNpd*fkTemp;
                        end
                    end
                end
                
                if Nut > 0
                    fk1 = PDiscovery(Nut,Npt,Nr,pCol,A(Nut+Npt,Npt+1,:));
                    fk1 = [fk1,zeros(1,min(Nue-Np,Nr+1)-length(fk1))];
                    fk = fk + PNut*PNpt*(theta*fk2 + (1-theta)*fk1);
                else
                    fk1 = 1;
                    fk1 = [fk1,zeros(1,min(Nue-Np,Nr+1)-length(fk1))];
                    fk = fk + PNut*PNpt*(theta*fk2 + (1-theta)*fk1);
                end
                
                
            end
        end
    end
end
end


