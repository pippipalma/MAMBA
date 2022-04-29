function d = default_distr(l)
% distr = default_distr(response_var)
%
% response_var: array of the response variable (default: binary labels)
% distr: default distribution for response_var
%
%   Author: Giuseppe Palma
%   Date: 08/10/2021

d = 'binomial';
if nargin < 1
    return
end
if size(l, 2) > 1
    d = 'cox';
elseif ~all(ismember(l, [0 1]))
    d = 'normal';
end