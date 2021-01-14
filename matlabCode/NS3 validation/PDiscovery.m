function [fk] = PDiscovery(Nut,Npt,Nr,pCol,a)
%this is the Pdisc for the case where Nut UE undiscovered UE are 
%transmitting and Npt previously discovered UE are transmitting parameters
%are:
%Nut: number of undiscovered UE transmitting
%Npt: number of previously discovered UE transmitting
%Nr: number of PRB used in discovery
%pCol: probability of collision matrix
%a: the collection of A vectors

fk = zeros(1,min(Nut+1,Nr+1));

%% a catch for if no one transmits
if Nut == 0
    fk = 1;
    return
end

%% clculate Fk
prob = (1/Nr)^(Nut)*(1/Nr)^(Npt);
for r = 1:min(Nr,Nut+Npt)
    
    A = a{:,:,r};%finds all partitions of Nu-1, given r bins are used
    %mathematically the undiscovered UE are represented as real numbers and 
    %the previously discovered UE as imaginary, all references to real
    %numbers(AR, JR, etc.) are references to the undiscovered UE, and
    %references to imaginary numbers(AI, JI, etc.) are references to the
    %previously discovered UE.
    AR = real(A);
    AI = imag(A);
    JR = makeJ(AR,Nut+Npt);%incidence counts for AR from 1:Nut+Npt
    JI = makeJ(AI,Nut+Npt);%incidence counts for AI from 1:Nut+Npt
    
    for i = 1:size(A,1)
        num = (factorial(Nr)/(factorial(r)*factorial(Nr-r)))*factorial(Nut)/prod(factorial(AR(i,:)))*factorial(Npt)/prod(factorial(AI(i,:)))*(factorial(r)/(factorial(length(AR(i,AR(i,:)>0)))*factorial(r - length(AR(i,AR(i,:)>0)))))*(factorial(length(AR(i,AR(i,:)>0)))/prod(factorial(JR(i,:))))*numWaysToDistributeDiscUsers(AR(i,:),AI(i,:),Nut+Npt);
        for k = sum(A(i,:)==1):sum(JR(i,:))%the number of discoveries cant be less than the number of ones, and cant be more than the number of PRB occupied by undiscovered UE
            
            colProb = overallCollisionProbability(sum(JR(i,:))-sum(A(i,:)==1),k-sum(A(i,:)==1),A(i,(AR(i,:)>1) | (AR(i,:)>0) & (AI(i,:)>0)),pCol);
            fk(k+1) = fk(k+1) + num*prob*colProb;
        end
    end
end
end