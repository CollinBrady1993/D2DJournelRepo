%this script reads in data, if neccessary, then calculates the first round
%pmf of discoveries, and the pdf of discoveries based on how many have
%already been discovered.


%% setting
%these first four are the simulations we want to access and calculate,
%since this is mac collisions only, for the moment, gamme/alpha are not
%inculded.
Nue = 12;%number of UE
theta = 1;%transmission probability
Nr = 24;%number of PRB
Nt = 6;%number of timeslots
PtdBm = -10;%transmit power in dbm, this is awkward because for reasons the file titles are reversed sign, so if power is -10 dBm then the file lists it as 10 dBm
R = 1000;%play field radius
fc = 23280;%center frequency

macCol = 1;%indicates mac/phy collisions

%settings on what to do, we may not need to read in data more than once
readData = 0;%flag to run the read data, dont need to read in data if its already there
findExperimentalPMF = 0;%flag to run the experimental PMF finder
findExperimentalCDF = 0;
calculatePMF = 1;
calculateCDF = 1;%if you want to calculate this, you also have to calculate the PMF

if readData
    run('dataReadScript.m');
end

%% determining experimental pmfs
if findExperimentalPMF
    PMF = zeros(min(Nue-1,Nr+1),min(Nue,Nr));%this matrix is going to hold all the PMF for the number of discoveries in a round
    %the ith row represents the number of discoveries with i-1 previous
    %discoveries. the jth column represents the probability of discovering j-1
    %UE in a round with i-1 previous discoveries.
    
    PMFRaw = cell(1,min(Nue,Nr)+1);%this is going to hold the data that is used to form the PMFs
    for i = 1:length(PMFRaw)
        PMFRaw{i} = zeros(1,size(data,1));
    end
    a = ones(1,size(PMFRaw,2));
    
    
    
    %% gathering round 1 discoveries PMF data
    disp('Gathering Round 1 Discovery Data')
    for i = 1:size(data,1)
        disp(strcat(num2str(100*(i-1)/size(data,1)),'% complete'))
        discPeriods = size(data{i},1);%the last disc period can be screwed up because the sim can finish in the middle of a disc period
        for j = 1:(discPeriods-1)
            for k = 1:Nue
                if ~isempty(data{i}{j})
                    PMFRaw{1}(a(1)) = sum(data{i}{j}(:,2) == k);
                    a(1) = a(1)+1;
                else
                    PMFRaw{1}(a(1)) = 0;
                    a(1) = a(1)+1;
                end
            end
        end
    end
    disp(strcat('100% complete'))
    
    %% gathering round >1 discoveries PMF data
    disp('Gathering Round >1 Discovery Data')
    for Np = 1:(length(PMFRaw) - 1)
        Np
        %start by finding a position that has Np discoveries
        keep = 0;
        for i = 1:(a(1)-1)
            if PMFRaw{1}(i) == Np
                keep = i;
                break
            end
        end
        
        %next we're going to find the [i,j,k] set that coresponds to that
        %Np value
        if keep > 0
            count = 0;
            kflag = 0;
            jflag = 0;
            for i = 1:size(data,1)
                discPeriods = size(data{i},1);
                for j = 1:(discPeriods-1)
                    for k = 1:Nue
                        count = count + 1;
                        if count == keep
                            kflag = 1;
                            break
                        end
                    end
                    if kflag == 1
                        jflag =1;
                        break
                    end
                end
                if jflag == 1
                    break
                end
            end
            
            keep = [i,j,k];
            
            UEDisc = data{keep(1)}{keep(2)}(data{keep(1)}{keep(2)}(:,2) == keep(3),3);
            
            for i = 1:size(data,1)
                discPeriods = size(data{i},1);%the last disc period can be screwed up because the sim can finish in the middle of a disc period
                for j = 1:(discPeriods-1)
                    for k = 1:Nue
                        if ~isempty(data{i}{j+1})
                            nextUEDisc = data{i}{j+1}(data{i}{j+1}(:,2) == k,3);%UE that it discovers the next round
                        else
                            nextUEDisc = [];
                        end
                        
                        PMFRaw{Np+1}(a(Np+1)) = (length(nextUEDisc) - sum(ismember(UEDisc,nextUEDisc)));%[PMFRaw{preDisc+1},(length(nextUEDisc) - sum(ismember(UEDisc,nextUEDisc)))];
                        
                        a(Np+1) = a(Np+1) + 1;
                    end
                end
            end
            
        end
    end
    
    disp(strcat('100% complete'))
    
    %% calculating the experimental PMFs
    for i = 1:size(PMF,1)
        disp(strcat('Determining experimental PMF: ',num2str(i),'/',num2str(size(PMF,1))))
        h = histogram(PMFRaw{i},-.5:1:(min(Nue,Nr)-.5),'normalization','pdf');
        PMF(i,:) = h.Values;
        close 1
    end
    
    PMF = [zeros(size(PMF,1),1),PMF];
    
    for i = 1:size(PMF,1)
        PMF(i,1) = length(PMFRaw{i});
    end
    
    clear('UEDisc','nextUEDisc','preDisc','h','i','j','k')
end

%% calculating the experimental CMF
if findExperimentalCDF
    
    CDFRaw = zeros(1,Nue*size(data,1));%represents the number of rounds it took each UE to complete
    a = 1;
    
    for i = 1:Nue%for each UE
        i
        datestr(now)
        for j = 1:size(data,1)%for each trial
            discPeriods = size(data{j},1);
            discList = [];%a variable that holds the UE that have been discovered
            
            for k = 1:discPeriods%for each discovery period, hopefully we dont go through them all
                if ~isempty(data{j}{k}) && length(data{j}{k}(:,2)) > 1
                    discListTemp = data{j}{k}((data{j}{k}(:,2) == i),3)';
                else
                    discListTemp = [];
                end
                discList = unique([discList,discListTemp]);
                if length(discList) == (Nue-1)
                    break
                end
            end
            
            CDFRaw(a) = k;
            a = a+1;
        end
    end
    
    h = histogram(CDFRaw,-.5:1:(max(CDFRaw)+.5),'normalization','pdf');
    CDF = h.Values;
    close all
    
    CDF = cumsum(CDF);
end

%% calculating the empirical PMF/CMF
%%{
if calculatePMF
    PMFCalc = zeros(Nue,min(Nue,Nr+1));
    
    for i = 0:Nue-1
        disp(strcat('Calculating PMF: ',num2str(i+1),'/',num2str(Nue)))
        datestr(now)
        temp = probOfKCaptures(Nue,i,theta,Nr,Nt,PtdBm,R,macCol);
        PMFCalc(i+1,:) = [temp,zeros(1,size(PMFCalc,2) - length(temp))];
    end
    clear('temp','i')
    
    if calculateCDF
        
        T = zeros(Nue,Nue);%this is the state transition matrix
        T(1,:) = [PMFCalc(1,:),zeros(1,Nue-length(PMFCalc(1,:)))];
        T(end,end) = 1;
        for i = 2:(size(PMFCalc,1)-1)
            T(i,i:(i+length(PMFCalc(i,:))-1)) = PMFCalc(i,:);
        end
        T = T(:,1:Nue);
        
        CDFCalc = 0;%this will store the CMF
        i = 1;
        tempT = T;
        while tempT(1,end) < .9999%some threshold close to 1
            tempT = T^i;
            CDFCalc = [CDFCalc,tempT(1,end)];
            i = i+1;
        end
        
        
        
        
    end
end



clear('readData','findExperimentalPMF','calculatePMF','plottingUtility','findExperimentalCMF','calculateCMF')














