function [w1New,w2New,w3New,w4New] = thetaUpdate(Nm,theta,w1,w2,w3,w4)
%This function performs a stochastic gradient descent step on the
%parameters w1,w2,w3
eta = .05;%learning rate

w1New = w1 - eta*(2*theta^2*exp(-2*w3*theta)*(w1*theta^2 - w2*theta + Nm*exp(w3*theta)));
w2New = w2 - eta*(-2*theta*exp(-2*w3*theta)*(w1*theta^2 - w2*theta + Nm*exp(w3*theta)));
w3New = w3 - eta*(-2*theta^2*exp(-2*w3*theta)*(w1*theta-w2)*(w1*theta^2 - w2*theta + Nm*exp(w3*theta)));
w4New = w4;

end

