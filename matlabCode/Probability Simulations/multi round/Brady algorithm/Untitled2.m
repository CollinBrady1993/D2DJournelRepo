k = 8;
temp = cell2mat(descentData);
Nm = temp(:,3:6:end);
T = cell2mat(thetaData);
w1 = temp(:,4:6:end);
w2 = temp(:,5:6:end);

%plot(mean(T))


%plot(mean(cell2mat(thetaData)))



Nk = 20;%2:2:10;
a = cell(length(Nk),1);


for i = 1:length(Nk)
    a{i} = zeros(size(T,1),periods-Nk(i),1);
end

for i = 1:length(Nk)
    i
    for j = 1:size(T,1)
        j
        for k = 20:10:(periods)
            t = T(j,(k-Nk(i)+1):k);
            nm = Nm(j,(k-Nk(i)+1):k);
            if t(1)~=t(20)
                a{i}(j,k) = (mean(nm(11:20))-mean(nm(1:10)))/(mean(t(11:20))-mean(t(1:10)));
                
                if a{i}(j,k) < 1e-5 && a{i}(j,k) > -1e-5
                    a{i}(j,k) = 0;
                end
            end
        end
    end
end
a = a{1}(:,20:10:end);
%plot(conv(sign(a),.01*ones(1,100),'same'))

%temp = sign(a).*log(abs(a));
%temp(isnan(temp)) = 0;







