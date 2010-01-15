% operation must be a string representation of +, -, / or *. 

function Z = calculate(X, Y, operation)
Z = eval([mat2str(X) operation mat2str(Y)]);
