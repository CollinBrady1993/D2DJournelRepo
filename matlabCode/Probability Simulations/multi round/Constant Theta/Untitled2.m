


caseNum = 4;
temp = cell2mat(data{1,4});
numBins = ceil(log2(length(temp))) + 1;
[~,edges] = histcounts(temp,numBins,'normalization','probability');
binCenters = edges(1:end-1) + (edges(2)-edges(1))/2;
Pndct{caseNum,1} = binCenters;
h = zeros(100,numBins);
for i = 1:100
%a = histogram(temp(((i-1)*10000+1):i*10000),edges,'normalization','probability');
%h(i,:) = a.Values;
[h(i,:),~] = histcounts(temp(((i-1)*10000+1):i*10000),edges,'normalization','probability');
end
Pndct{caseNum,2} = mean(h);
Pndct{caseNum,3} = 1.96*std(h)/sqrt(100);











