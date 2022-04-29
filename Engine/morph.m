function x = morph(x, k, mod)
% y = morph(x, kern, mod)
%
%   y:      binary morphology operation;
%   x:      input binary image;
%   kern:   structuring element;
%   mod:    operation:
%           'd': dilation (default);
%           'e': erosion;
%           'c': closing;
%           'o': opening.
%
%   Author: Giuseppe Palma
%   Date: 06/07/2016
%
% Dependencies:
%   - local_moments
if nargin < 3
    mod = 'd';
end
switch lower(mod)
    case {'d' 'dilate' 'dilation'}
        x = local_moments(x, k, 'mask', 'd');
    case {'e' 'erode' 'erosion'}
        k(end : -1 : 1) = k;
        x = ~local_moments(~x, k, 'mask', 'd');
    case {'c' 'close' 'closing'}
        x = morph(morph(x, k), k, 'e');
    case {'o' 'open' 'opening'}
        x = morph(morph(x, k, 'e'), k);
end