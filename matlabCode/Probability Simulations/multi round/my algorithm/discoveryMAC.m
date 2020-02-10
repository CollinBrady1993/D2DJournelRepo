function [newDiscoveryList,Nm] = discoveryMAC(PRB,oldDiscoveryList,Nr,Nt)
newDiscoveryList = oldDiscoveryList;
Nm = zeros(size(PRB));
for i = 1:Nr
    if sum(PRB == i) == 1
        newDiscoveryList(or(PRB == 0,mod(PRB,Nt) ~= mod(i,Nt)),PRB == i) = 1;
        Nm(PRB ~= i) = Nm(PRB ~= i) + 1;
    end
end



end

