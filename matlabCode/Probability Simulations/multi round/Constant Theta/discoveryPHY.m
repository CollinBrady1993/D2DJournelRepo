function [newDiscoveryList] = discoveryPHY(PRB,oldDiscoveryList,Nr,Nt,d,Pt,thermalNoise,noiseFigure,lambda,alpha,systemLoss)
%resolves discoveries according to the PCM

newDiscoveryList = oldDiscoveryList;
for i = 1:Nr
    if sum(PRB == i) >= 1%if the PRB is occupied
        UEs = find(PRB == i);%determine which UEs is transmitting on the PRB
        for j = 1:length(PRB)%for each other UE
            if (PRB(j) == 0 || mod(PRB(j),Nt) ~= mod(i,Nt)) && ~ismember(j,UEs)%dont bother calculating SINR for the transmitter
                
                %determine the distance between the transmitters and UE j
                dist = d(j,UEs);
                %determine the coresponding path loss
                
                %we sort them because we want to start checking the close
                %UE
                [dist,I] = sort(dist,'ascend');
                UEs = UEs(I);
                
                
                pathLoss = ((lambda./(4*pi*dist)).^alpha)/systemLoss;
                
                %determine the SINR assuming each one is the signal and the
                %others are the interference
                SINR = (Pt*pathLoss(1))/(thermalNoise*noiseFigure + sum(Pt*pathLoss(2:end)));
                
                %determine the corresponding BLER, SINR needs to be in dB
                BLER = PSDCHSINR2BLER(10*log10(SINR),1);
                
                if rand > BLER
                    newDiscoveryList(j,UEs(1)) = 1;
                end
                
            end
        end
        
        
    end
end


















end

