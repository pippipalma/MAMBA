function [x, iTrim] = array_trim(x)
% [y, iTrim] = array_trim(x)
%
%   x:      ND array;
%   y:      x without leading or trailing (N-1)D zeros;
%   iTrim:  N-by-2 array with cropping indexes;
%
%   Author: Giuseppe Palma
%   Date: 03/03/2017
n = ndims(x);
iTrim = zeros(n, 2);
inx(1 : n) = {[]};
for i = 1 : n
    in = 1 : n;
    in(i) = [];
    xn = permute(x, [i in]);
    lin = max(xn(:, :), [], 2);
    iTrim(i, :) = [find(lin, 1) find(lin, 1, 'last')];
    inx{i} = iTrim(i, 1) : iTrim(i, 2);
end
x = x(inx{:});