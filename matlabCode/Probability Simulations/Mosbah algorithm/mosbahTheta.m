function [theta] = mosbahTheta(Nue,Nr,Nt)
%MOSBAHTHETA Summary of this function goes here
%   Detailed explanation goes here

temp = (Nr*(Nt-2) + Nt)/(Nt-1);

if temp > Nue
    theta = 1;
else
    theta = (2*Nr + Nt*(Nue-1) - sqrt(4*Nr*(Nr-Nt) + Nt^2*(Nue-1)^2))/(2*Nue);
    theta = min(1,max(.25,theta));%limit to 3gpp bounds
end


end

