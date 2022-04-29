function X = keep_rem(X, k, r)
% X = keep_rem(X, keep_vars, rem_vars)
%
% X: structure, table or cell array of character vectors
% keep_vars: variables to be kept (default: all)
% rem_vars: variables to be removed (default: none)
%
% Variables are not required to be in X
%
%   Author: Giuseppe Palma
%   Date: 04/08/2020

if nargin < 2
    return
end
if istable(X)
    fn = X.Properties.VariableNames;
elseif isstruct(X)
    fn = fieldnames(X);
else
    fn = X;
end
if isempty(k)
    k = fn;
end
if nargin < 3 || isempty(r)
    r = {};
end
i = ismember(fn, r) | ~ismember(fn, k);
if istable(X)
    X(:, i) = [];
elseif isstruct(X)
    X = rmfield(X, fn(i));
else
    X(i) = [];
end