function X = name_match(X, pattern)
% name_subset = name_match(name_set, pattern)
%
% Extract from name_set the subset of names matching the pattern
%
%   Author: Giuseppe Palma
%   Date: 02/08/2020

m = regexpi(X, regexptranslate('wildcard', pattern), 'match');
X = X(arrayfun(@(x) ismember(X{x}, m{x}), 1 : numel(X)));