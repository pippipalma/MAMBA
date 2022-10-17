function varargout = local_moments(img, kern, varargin)
% [m, std, std_3, ...] = local_moments(img, kern, options)
%
% m: local means or binary dilation;
% std: local standard deviations;
% std_i: local i-th standardized moments;
% img: ND image or cell array of ND images;
% kern: filter kernel in the form of:
%   - edge half lengths of the MD moving window (parallelepiped)
%   - MD structuring element (output values will just retain the relative
%     weights of kern entries). M <= N;
%
% Options:
%   - mask: LD image mask (default = TRUE. If ischar, m = img dilated by
%     kern). M <= L <= N;
%   - imask: (L+1)th index of the img component for further output masking
%     (default = 0. If imask < 0, mask is dilated by kern);
%   - p: scalar power of the Holder mean (default = 1);
%   - norm: if false, the outputs are the weighted local sum of powers
%     (default: true);
%   - progress_bar: flag for displaying the progress bar (default: true);
%   - process: name of the progress bar (default: 'local_moments').
%
%   Author: Giuseppe Palma
%   Date: 14/10/2022

o = opt_pars('mask', true, 'imask', 0, 'p', 1, 'progress_bar', true, ...
    'process', 'local_moments', 'norm', true, varargin{:});
isc = iscell(img);
if isc
    sz = cellfun(@size, img, 'UniformOutput', false);
    if ~o.progress_bar && ...
            all(cellfun(@isnumeric, img(:))) && isequal(sz{1}, sz{:})
        img = cat(numel(sz{1}) + 1, img{:});
    else
        v = cell(nargout, 1);
        varargout(1 : nargout) = {cell(sz)};
        n = numel(img);
        ppm = ProgrBar(o.progress_bar, 'create', n, false, o.process);
        for i = 1 : n
            [v{:}] = local_moments(img{i}, kern, o);
            for j = 1 : nargout
                varargout{j}(i) = v(j);
            end
            ProgrBar(ppm, 'update')
        end
        ProgrBar(ppm, 'delete')
        return
    end
end
if isempty(img)
    varargout(1 : nargout) = {[]};
    return
end
if isvector(kern) && ndims(img) >= numel(kern)
    kern = ones(2*kern + 1);
end
ndk = ndims(kern);
r = floor(size(kern)/2);
s = size(img);
morph = ischar(o.mask);
if isscalar(o.mask) && ~morph
    o.mask = true(s(1 : ndk));
end
holder = o.p ~= 1;
nout = max(1, nargout);
if nout > 1 && (morph || holder)
    error('Too many output arguments')
end
sx = 2*r + s(1 : ndk);
inx(1 : ndk) = {[]};
for i = 1 : ndk
    inx{i} = r(i) + 1 : sx(i) - r(i);
end
tr = @(x) x(inx{:});
if morph
    o.mask = img;
    o.imask = -1;
end
ndm = ndims(o.mask);
if ~isequal(size(o.mask), s(1 : ndm))
    error('mask size mismatch')
end
c = zeros(s(1 : ndm));
in(1 : ndk) = {':'};
imax = prod(s(ndk + 1 : ndm));
for i = 1 : imax
    c(in{:}, i) = tr(ifftn(fftn(o.mask(in{:}, i), sx).*fftn(abs(kern), sx)));
end
if ~morph && ~o.imask
    out = logical(o.mask);
elseif o.imask > 0
    in2(1 : ndm) = {':'};
    out = o.mask & img(in2{:}, o.imask);
else
    out = abs(c) > 1e-6;
end
if morph
    varargout{1} = out;
else
    if holder
        img = img.^o.p;
    end
    varargout(1 : nout) = {zeros(s)};
    out = out./c;
    kt = fftn(kern, sx);
    for i = 1 : prod(s(ndk + 1 : end))
        i2 = mod(i - 1, imax) + 1;
        img(in{:}, i) = img(in{:}, i).*o.mask(in{:}, i2);
        for j = 1 : nout
            varargout{j}(in{:}, i) = tr(ifftn(fftn(img(in{:}, i).^j, sx).*kt)).*out(in{:}, i2);
            if holder
                varargout{1}(in{:}, i) = varargout{1}(in{:}, i).^(1/o.p);
            end
        end
    end
end
for j = nout : -1 : 2
    for i = 2 : j - 1
        varargout{j} = varargout{j} + nchoosek(j, i)*varargout{i}.*(-varargout{1}).^(j - i);
    end
    varargout{j} = varargout{j} + (-1)^(j - 1)*(j - 1)*varargout{1}.^j;
end
for j = 1 : nout
    if o.norm
        if j == 2
            varargout{j} = sqrt(max(0, varargout{j}));
        elseif j > 2
            varargout{j} = varargout{j}./varargout{2}.^j;
        end
    else
        varargout{j} = varargout{j}.*c;
    end
    varargout{j}(isnan(varargout{j})) = 0;
end
if isc
    varargout = cellfun(@(x) reshape(num2cell(x, 1 : numel(sz{1})), size(sz)), ...
        varargout, 'UniformOutput', false);
end