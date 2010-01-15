function C = matmult(s, A, B) 
% MATMULT: Compute C = A * B
%
% NOTE: This is not intended for actual use.
% It is only intended to be an example use
% of NetWorkSpaces.

% Split B into a cell array of column vectors
colsB = mat2cell(B, size(B, 1), repmat(1, 1, size(B, 2)));

% Execute the matrix/vector multiplies
colsC = eachElem(s, @(y, x) x * y, {colsB}, A);

% Join the column vectors into a matrix
C = [colsC{:}];
