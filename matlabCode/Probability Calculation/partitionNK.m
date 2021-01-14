function [I] = partitionNK(n,k,l)
I = [];
if k < 1
    return
end
if k == 1
    if n >= l
        I = [n];
    end
    return
end
for i = l:(n+1)
    ITemp = partitionNK(n-i,k-1,i);
    if isempty(ITemp) == 0
        I = [I;[i*ones(size(ITemp,1),1),ITemp]];
    end
end
end