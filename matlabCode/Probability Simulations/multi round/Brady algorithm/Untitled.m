


AthetaENDCT = zeros(1,39);
AthetaENDCTError = zeros(1,39);
theta1ENDCT = zeros(1,39);
theta1ENDCTError = zeros(1,39);

theta25ENDCT = zeros(1,39);
theta25ENDCTError = zeros(1,39);


for i = 1:39
    AthetaENDCT(i) = mean(thetaAData{i,4});
    AthetaENDCTError(i) = 1.96*std(thetaAData{i,4})/sqrt(length(thetaAData{i,4}));
    
    
    
    
    theta1ENDCT(i) = mean(cell2mat(theta1Data{i,4}));
    theta1ENDCTError(i) = 1.96*std(cell2mat(theta1Data{i,4}))/sqrt(length(cell2mat(theta1Data{i,4})));
    
    
    theta25ENDCT(i) = mean(cell2mat(theta25Data{i,4}));
    theta25ENDCTError(i) = 1.96*std(cell2mat(theta25Data{i,4}))/sqrt(length(cell2mat(theta25Data{i,4})));
    
    
end
