function [newIndex] = shiftIndex(oldIndex,n)
%shifts the index of and index vector by 1, so shiftIndex([0,0,1]) = [0,1,0]

count = 0;

for i = length(oldIndex):-1:1
    if oldIndex(i) == 1
        count = count + 1;
        if count == n
            if i < (length(oldIndex) - n + 1)
                oldIndex(i+1) = 1;
                oldIndex(i) = 0;
            else
                oldIndex = shiftIndex(oldIndex,n+1);
                oldIndex(i) = 0;
                for j = (i-1):-1:1
                    if oldIndex(j) == 1
                        oldIndex(j+1) = 1;
                        break
                    end
                end
            end
        end
    end
end


newIndex = oldIndex;



end

