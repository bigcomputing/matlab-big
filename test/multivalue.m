function [x, y] = multivalue(varargin)
x = sum([varargin{:}]);
y = length(varargin);
