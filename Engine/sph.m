function se = sph(r, type, ext)
% se = sph(r, type, ext)
%
%   se:     ND array with spherical (logical) or gaussian kernel;
%   r:      N vector (or scalar) corresponding to radii or gaussian sigma;
%   type:   {'sharp' (default) | 'gauss' | 'sigma'};
%   ext:    scalar value specifying the support in units of r
%           (default: 1 [sharp]; 3 [gauss]; 10 [sigma])
%
%   Author: Giuseppe Palma
%   Date: 11/12/2018
if nargin < 2
    type = 'sharp';
end
type = lower(type);
if nargin < 3
    switch type
        case 'sharp'
            ext = 1;
        case 'gauss'
            ext = 3;
        case 'sigma'
            ext = 10;
    end
end
if isscalar(r)
    r = r*ones(1, 3);
end
d = r <= 0;
[~, i1] = sort(d);
[~, i1] = sort(i1);
r(d) = [];
nd = numel(r);
cc(1 : nd) = {[]};
l0 = ceil(r*ext);
for i = 1 : nd
    cc{i} = -l0(i) : l0(i);
end
[cc{:}] = ndgrid(cc{:});
se = zeros(size(cc{1}));
for i = 1 : nd
    se = se + (cc{i}/r(i)).^2;
end
switch type
    case 'sharp'
        se = se <= 1;
    case 'gauss'
        se = exp(-se/2);
    case 'sigma'
        se = sqrt(se);
        se = 2/pi./(exp(se) + exp(-se));
end
se = permute(array_trim(se), i1);