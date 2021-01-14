


K = cell(size(MCMSimData{1,3}));

KNP5 = zeros(522208,1);
a = 1;
count = 0;



for i = 1:size(MCMSimData{1,3},1)
    i
    for j = 1:size(MCMSimData{1,3}{i},2)
        for k = 1:size(MCMSimData{1,3}{i}{j},1)
            
            K{i}(k,j) = sum(MCMSimData{1,3}{i}{j}(k,:))-1;
            
            
            if K{i}(k,j) == 5 && j ~= size(MCMSimData{1,3}{i},2)
                KNP5(a) =  sum(or(MCMSimData{1,3}{i}{j}(k,:),MCMSimData{1,3}{i}{j+1}(k,:))) - sum(MCMSimData{1,3}{i}{j}(k,:));
                a = a+1;
            end
            if K{i}(k,j) == 1
                count = count+1;
            end
        end
    end
end
KNP5(a:end) = [];







