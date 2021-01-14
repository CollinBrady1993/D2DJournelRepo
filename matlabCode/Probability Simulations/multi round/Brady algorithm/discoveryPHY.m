function [newDiscoveryList,Nm] = discoveryPHY(PRB,oldDiscoveryList,Nr,d,Pt,thermalNoise,noiseFigure,lambda,alpha,systemLoss)
newDiscoveryList = oldDiscoveryList;
Nm = zeros(size(PRB));
for i = 1:Nr
    if sum(PRB == i) >= 1%if the PRB is occupied
        UEs = find(PRB == i);%determine which UEs is transmitting on the PRB
        for j = 1:length(PRB)%for each other UE
            if ~ismember(j,UEs)%dont bother calculating SINR for the transmitter
                
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
                %SINR = zeros(length(UEs),1);
                %for k = 1%:length(UEs)
                    %ITransmitters = UEs(2:end);
                    %ITransmitters(k) = [];
                    SINR = (Pt*pathLoss(1))/(thermalNoise*noiseFigure + sum(Pt*pathLoss(2:end)));
                %end
                
                %we sort them because we want to start checking the high
                %SINR UE first, then try the low SINR UE after.
                %[SINR,I] = sort(SINR,'descend');
                %UEs = UEs(I);
                
                %determine the corresponding BLER, SINR needs to be in dB
                BLER = PSDCHSINR2BLER(10*log10(SINR),1);
                
                %for k = 1:length(UEs)
                    if rand > BLER
                        newDiscoveryList(j,UEs(1)) = 1;
                        Nm(j) = Nm(j) + 1;
                        %break
                    end
                %end
                
            end
        end
        
        
    end
end


















end

