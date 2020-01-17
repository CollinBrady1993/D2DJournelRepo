function [newDiscoveryList,Nm] = discoveryMAC(PRB,oldDiscoveryList,Nr)
newDiscoveryList = oldDiscoveryList;
Nm = zeros(size(PRB));
for i = 1:Nr
    if sum(PRB == i) == 1
        newDiscoveryList(:,PRB == i) = ones(size(oldDiscoveryList,1),1);
        Nm(PRB ~= i) = Nm(PRB ~= i) + 1;
    end
end

%Nm = sum(newDiscoveryList-oldDiscoveryList,2);


end

