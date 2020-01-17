function [J] = makeJ(A,N)
%creates the J vector for the vector A, the J cevtors are counts of how
%many elements of A are equal to 1:N

J = zeros(size(A,1),N);

for i = 1:size(J,1)
    for j = 1:N
        J(i,j) = sum(A(i,:) == j);
    end
end

end

