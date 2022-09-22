function [D, n, asub, o] = BED(D, n, asub, varargin)
% [bed, n, alphabeta, options] = BED(D, n, alphabeta, options)
%
% bed: BED or EQDx
% n: number of fractions (default: inf)
% alphabeta: alpha/beta (default: 3)
%
% D: dose
%
% Options:
%   - dt: dose threshold for LQL model (default: inf)
%   - EQDx: reference dose for EQDx computation (default: 0)
%   - gammaalpha: gamma/alpha (default: 1 + 2*dt/alphabeta)
%
%   Author: Giuseppe Palma
%   Date: 23/06/2022

if nargin < 3 || isempty(asub)
    asub = 3;
end
if nargin < 2 || isempty(n)
    n = inf;
end
o = opt_pars('dt', inf, 'EQDx', 0, varargin{:});
o = opt_pars('gammaalpha', 1 + 2.*o.dt./asub, o);
if ~nargin
    D = [];
    return
end
o.gammaalpha = o.gammaalpha + zeros(size(o.dt));
o.gammaalpha(isinf(o.dt) | false(size(o.gammaalpha))) = 0;
d = min(o.dt.*n, D);
x = min(o.dt./o.EQDx, 1);
D = ((asub + D./n).*d + asub.*(D - d).*o.gammaalpha)./ ...
    ((asub + o.EQDx).*x + asub.*(1 - x).*o.gammaalpha);