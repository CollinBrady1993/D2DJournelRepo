function [ solutions ] = makeA(Nu,Nb,r)
%this function makes the set of vectors, A, which are representative of
%PRB occupancies. imaginary numbers indicate occupants who have already
%been discovered
%Nu: total number of UE which are transmitting
%Nb: number of transmitting UE who are already discovered
%r: number of occupied PRB


if Nb == 0
    solutions = partitionNK(Nu,r,1);
    return
end
if r == Nu
    solutions = [1i*ones(1,Nb),ones(1,Nu-Nb)];
    return
end




%% find the starting point
AR = fliplr(partitionNK(Nu,r,1));%this is the initial A, it is also |A|
AI = cell(1,min(Nb,r));%get all possible way to partiton the imaginary numbers
for i = 1:min(Nb,r)
    AI{i} = fliplr(partitionNK(Nb,i,1));
end

%factorial(Nr)/(factorial(r)*factorial(Nr - r))



%% find A
%from here we allocate the Nb UE who have already been found

solutions = zeros(size(AR,1)*1000,r);
solCount = 1;
for i = 1:size(AR,1)%for every whole vector
    
    Xa = AR(i,:);
    for j = 1:length(AI)
        i;
        j;
        for k = 1:size(AI{j},1)%j,k make up for every partition of the imaginary numbers
            if sum(Xa < [AI{j}(k,:),zeros(1,length(Xa)-length(AI{j}(k,:)))]) == 0
                index = [ones(1,j),zeros(1,r-j)];
                Xb = allUniquePermutations(AI{j}(k,:));
                
                for q = 1:(nchoosek(r,j))%for every length j subset of positions
                    
                    for l = 1:size(Xb,1)%for every unique permutation of the imaginary permutation
                        l;
                        if sum(Xa(logical(index)) < Xb(l,:)) == 0%if any elements of Xb are greater than Xa, dont try
                            tempSol = Xa;
                            tempSol(logical(index)) = tempSol(logical(index)) - Xb(l,:)*(1-1i);
                            for w = 1:(solCount)
                                if solutions(w,:) == sort(tempSol)
                                    break
                                elseif w == solCount
                                    solutions(solCount,:) = sort(tempSol);
                                    solCount = solCount+1;
                                end
                            end
                        end
                    end
                    index = shiftIndex(index,1);
                end
            end
        end
    end
end


solutions = fliplr(solutions(1:(solCount-1),:));
end