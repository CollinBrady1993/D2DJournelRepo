function [newIndexes] = itterIndex(indexes,n,max)
indexes(n) = indexes(n) + 1;


if indexes(n) > max(n)
    indexes(n) = 1;
    indexes = itterIndex(indexes,n+1,max);
    newIndexes = indexes;
else
    newIndexes = indexes;
end



end