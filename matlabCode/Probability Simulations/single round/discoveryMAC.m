function [newDiscoveryList] = discoveryMAC(PRB,oldDiscoveryList,Nr,Nt)
%resolves discoveries according to the MCM

newDiscoveryList = oldDiscoveryList;

for i = 1:Nr
    if sum(PRB == i) == 1
        newDiscoveryList(or(PRB == 0,mod(PRB,Nt) ~= mod(i,Nt)),PRB == i) = 1;
    end
end

end

