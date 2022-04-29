function s = opt_pars(varargin)
% s = opt_pars(vars)
%
% vars may include in arbitrary order:
%     filename: MAT-filename (including the extension)
%     s: option scalar structure
%     field, value: pair of option name and value
%
%   Author: Giuseppe Palma
%   Date: 02/08/2020

s = struct;
c = 0;
while c < nargin
    c = c + 1;
    if isstruct(varargin{c})
        s = s_merge(s, varargin{c});
    elseif isvarname(varargin{c})
        s.(varargin{c}) = varargin{c + 1};
        c = c + 1;
    else
        s = s_merge(s, load(varargin{c}));
    end
end

function s = s_merge(s, s2)
if isempty(fieldnames(s))
    s = s2;
else
    fn = fieldnames(s2);
    for i = 1 : numel(fn)
        s.(fn{i}) = s2.(fn{i});
    end
end