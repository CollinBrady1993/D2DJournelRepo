ENDCT = zeros(length(NUE),1);
for i = 1:length(NUE)
ENDCT(i) = mean(cell2mat(data{i,4}));
end

errorNDCT = zeros(length(NUE),1);
for i = 1:length(NUE)
errorNDCT(i) = 1.96*std(cell2mat(data{i,4}))/sqrt(trials);
end

temp = [ENDCT,errorNDCT];
csvwrite('tempData.csv',temp)
