function [w1New,w2New] = thetaUpdate(Nm,theta,w1,w2,period,eta1,eta2,a,b)
%This function performs a stochastic gradient descent step on the
%parameters w1,w2
g = [(2*((theta)*exp(-(theta-.625)*w2))*(w1*(theta)*(exp(-(theta-.625)*w2)) - Nm)),(-2*(theta-.625)*theta*exp(-(theta-.625)*w2)*(w1*(theta)*exp(-(theta-.625)*w2) - Nm))];
%g = [(2*((theta)*exp(-(theta-.625)*w2))*(w1*(theta)*(exp(-(theta-.625)*w2)) - Nm)),(-2*w1*(theta-.625)*theta*exp(-(theta-.625)*w2)*(w1*(theta)*exp(-(theta-.625)*w2) - Nm))];
%g = [(2*((theta)*exp(-(theta)*w2))*(w1*(theta)*(exp(-(theta)*w2)) - Nm)),(-2*w1*(theta)*theta*exp(-(theta)*w2)*(w1*(theta)*exp(-(theta)*w2) - Nm))];
%g = [(2*((theta)*exp(-(theta-.625)*(w2+10)))*(w1*(theta)*(exp(-(theta-.625)*(w2+10))) - Nm)),(-2*(theta-.625)*theta*exp(-(theta-.625)*(w2+10))*(w1*(theta)*exp(-(theta-.625)*(w2+10)) - Nm))];


if isnan(g(1))
    w1New = w1;
else
    w1New = max(w1 - eta1*g(1),0);
end
if isnan(g(2))
    w2New = w2;
else
    w2New = max(w2 - eta2*g(2),0);
    %w2New = w2 - eta2*g(2);
end



end

