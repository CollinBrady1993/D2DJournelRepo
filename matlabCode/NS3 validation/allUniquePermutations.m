function[out] = allUniquePermutations(A)
%determines a list of all permutations of the input vector A

J = makeJ(A,max(A));
n = length(A);

out = zeros(factorial(n)/prod(factorial(J)),n);
breaks = [0];
for i = 1:n%for each index in the resulting permutation
    if i == 1
        tempi = 1;
        for j = 1:length(J)
            tempJ = J;
            if tempJ(j) > 0
                tempJ(j) = tempJ(j)-1;
                MP = factorial(n-i)/prod(factorial(tempJ));
                
                out(tempi:(tempi+MP-1),i) = j*ones(MP,1);
                tempi = MP+tempi;
                breaks = [breaks;tempi-1];
                
            end
        end
    else
        tempBreaks = breaks;%this will serve as the break points for this round, breaks itself will be changing
        addCount = 0;
        for j = 1:(length(tempBreaks)-1)
            tempi = tempBreaks(j) + 1;
            
            for k = 1:length(J)
                tempJ = J - makeJ(out(tempBreaks(j+1),:),length(J));
                if tempJ(k) > 0
                    addCount = addCount + 1;
                    tempJ(k) = tempJ(k)-1;
                    MP = factorial(n-i)/prod(factorial(tempJ));
                    
                    out(tempi:(tempi+MP-1),i) = k*ones(MP,1);
                    tempi = MP+tempi;
                    if ~ismember(tempi-1,breaks)
                        breaks = [breaks(1:addCount);tempi-1;breaks(1+addCount:end)];
                    end
                end
            end
        end
    end
end


end

