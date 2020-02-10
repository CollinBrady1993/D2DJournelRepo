function [prob] = overallCollisionProbability(multiplyOccupiedPRB,numDiscoveriesNeeded,A,pCol)
%this function computes the overall collision probaility based on the
%number of multiply occipied PRB


q = factorial(multiplyOccupiedPRB)/(factorial(numDiscoveriesNeeded)*factorial(multiplyOccupiedPRB-numDiscoveriesNeeded));
prob = 0;
index = zeros(q,multiplyOccupiedPRB);
index(1,:) = [ones(1,numDiscoveriesNeeded),zeros(1,multiplyOccupiedPRB-numDiscoveriesNeeded)];
colProb = zeros(1,length(A));
for i = 1:length(A)
    colProb(i) = pCol(real(A(i)) + imag(A(i)),imag(A(i))+1);
end

%%{
for i = 2:q
    index(i,:) =shiftIndex(index(i-1,:),1);
end
%}


for i = 1:q%for each possible set of coTx for both collisions and not collisions
    
    
    PC = prod(1-colProb(logical(index(i,:))));
    PnotC = prod(colProb(not(logical(index(i,:)))));
    
    prob = prob + PC*PnotC;%total probability is formed of the sum of the probabilities of each indivisual set of coTx
    
    
end
end

