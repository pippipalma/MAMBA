function [d, msk, EVs_inx, s] = destr(d0, varargin)
% [variables, patient_masks, EVs_inx, options] = destr(d, options)
%
% variables: [#patients #voxels #variables] 3D array
% patient_masks: [#patients #voxels] 2D arrays
% EVs_inx: indices of selected explanatory variables
% options: structure of processed options
%
% d: patient dataset in form of:
%   - #patients-by-#variables table
%   - [#patients #dim1 ... #dimN #variables] (2+N)D array of variables
%   - structure with fields:
%     - variables: [#patients #dim1 ... #dimN #variables] (2+N)D array of
%       variables
%     - msk: [#patients #dim1 ... #dimN] (1+N)D array of patients'
%       (weighted) masks (default: option mfix for each patient)
%   Each of the previous arrays (variables in table; variables and masks in
%   array/structure) could appear independently linearized in the spatial
%   dimensions.
%
% Options:
%   - vars: name of the columns to be selected (default: ':'). 'mpat' is
%     excluded from vars.
%   - labels: variables corresponding to the response variable that need to
%     be removed from vars (default: {})
%   - EVs_inx: variables for which the output indices are required
%     (default: {})
%   - mfix: [#dim1 ... #dimN] (possibly linearized) array of the global
%     mask (default: true)
%   - subsampling: additional mask (same size of mfix), or scalar or vector
%     (of length = ndims(mfix)) defining the intervals for subsampling
%     (default: 1)
%   - dim_vars: scalar integer specifying the dimension associated to the
%     (2+N)D array of variables in which different variables are indexed
%     By default it is set to the number of dimensions of the d or
%     d.variables, unless a non scalar mfix is defined. It is necessary if
%     mfix is a scalar and there is a single spatial variable, which is not
%     linearized; otherwise, the spatial variables will be interpreted as a
%     list of (N-1)D variables (e.g., if d is a [#patients #dim1 ... #dimN]
%     (1+N)D array, please specify dim_vars = N+2.
%     It has no effect if d is a table.
%   - progress_bar: flag for displaying the progress bar (default: true)
%
%   Author: Giuseppe Palma
%   Date: 23/06/2022

s = opt_pars('EVs_inx', {}, 'subsampling', 1, 'labels', {}, ...
    'vars', ':', 'mfix', true, 'keep_all_voxels', false, ...
    'progress_bar', true, 'rc_name', 'patients', varargin{:});
if isempty(d0)
    d = [];
    msk = [];
    EVs_inx = [];
    return
end
dm = @(x) error([x ' does not match previous sizes.']);
s.mfix = logical(s.mfix);
if istable(d0)
    vn = d0.Properties.VariableNames;
    s.vars = keep_rem(ind2name(s.vars, vn), [], ['mpat' ind2name(s.labels, vn)]);
    s.EVs_inx = i2n(s.EVs_inx, @ind2name);
    d0 = keep_rem(d0, [s.vars 'mpat']);
    vn = d0.Properties.VariableNames;
    for i = vn
        arrayfy(d0{1, i{:}}{:}, i{:})
    end
    mf = kav;
    mf = sparsify_mask(mf, s.subsampling);
    N = height(d0);
    sz = [N sum(mf(:))];
    mp = nargout > 1 && ismember('mpat', vn);
    if mp
        if islogical(d0{1, 'mpat'}{:})
            msk = false(sz);
        else
            msk = zeros(sz);
        end
    elseif nargout > 1
        msk = true(sz);
    end
    M = numel(s.vars);
    d = zeros([sz M]);
    ppm = ProgrBar(s.progress_bar, 'create', N, false, ['Standardizing ' s.rc_name]);
    for i = 1 : N
        if mp
            msk(i, :) = d0{i, 'mpat'}{:}(mf);
        end
        for j = 1 : M
            if isscalar(d0{i, s.vars{j}}{:})
                d(i, :, j) = d0{i, s.vars{j}}{:};
            else
                d(i, :, j) = d0{i, s.vars{j}}{:}(mf);
            end
        end
        ProgrBar(ppm, 'update')
    end
    ProgrBar(ppm, 'delete')
    EVs_inx = i2n(s.EVs_inx, @(y) cellfun(@(x) find(strcmp(x, s.vars)), y));
else
    ppm = ProgrBar(s.progress_bar, 'create', 1, false, ['Standardizing ' s.rc_name]);
    if isfield(d0, 'msk')
        msk = d0.msk;
    else
        msk = true;
    end
    if isstruct(d0)
        d0 = d0.variables;
    end
    szd = size(d0);
    szm = size(msk);
    a = numel(s.mfix);
    b = prod(szd(2 : end));
    c = prod(szd(2 : max(2, end - 1)));
    d = prod(szm(2 : end));
    Nvox = max([a c d]);
    if any(Nvox ~= [a d] & 1 ~= [a d]) || ~any(Nvox == [b c] | 1 == c)
        error('Dimension mismatch')
    end
    s = opt_pars('dim_vars', ndims(d0) + any(b == [1 Nvox]), s);
    a = 1 : size(d0, s.dim_vars);
    s.vars = cell2arr(s.vars, a);
    s.labels = cell2arr(s.labels, a);
    if ~isempty(s.labels)
        s.vars(any(s.labels' == s.vars, 1)) = [];
    end
    EVs_inx = i2n(i2n(s.EVs_inx, @cell2arr), ...
        @(y) arrayfun(@(x) find(x == s.vars), y));
    inx = repmat({':'}, 1, ndims(msk) - 1);
    arrayfy(shiftdim(msk(1, inx{:})), 'masks')
    inx = repmat({':'}, 1, s.dim_vars - 2);
    d0 = d0(:, inx{:}, s.vars);
    arrayfy(shiftdim(d0(1, inx{:}, 1)), 'variables')
    mf = kav;
    mf = sparsify_mask(mf, s.subsampling);
    sz = [szd(1) sum(mf(:))];
    if isscalar(msk(1, :))
        msk = repmat(msk, sz./size(msk(:, :)));
    else
        msk = msk(:, mf);
    end
    if isscalar(d0(1, inx{:}, 1))
        d = reshape(repmat(d0, 1, sz(2)), sz(1), sz(2), []);
    else
        d = zeros([sz numel(s.vars)]);
        inx = repmat({':'}, 1, s.dim_vars - 1);
        for i = 1 : numel(s.vars)
            di = d0(inx{:}, i);
            d(:, :, i) = di(:, mf);
        end
    end
    ProgrBar(ppm, 'delete')
end
    function mf = kav
        mf = s.mfix;
        if s.keep_all_voxels
            mf(:) = true;
            s.subsampling(:) = 1;
        end
    end
    function x = ind2name(x, a)
        if nargin < 2
            a = s.vars;
        end
        if ischar(x)
            x = {x};
        elseif isnumeric(x)
            x = num2cell(x);
        end
        I = cellfun(@isnumeric, x);
        x(I) = vn(cell2mat(x(I)));
        x = x(:)';
        for I = flip(find(strcmp(x, ':')))
            x = [x(1 : I - 1) a x(I + 1 : end)];
        end
    end
    function y = cell2arr(x, a)
        if nargin < 2
            a = s.vars;
        end
        if ischar(x)
            x = {x};
        end
        if iscell(x)
            y = x;
            x = [];
            for I = 1 : length(y)
                if strcmp(y{I}, ':')
                    x = [x a];
                else
                    x = [x y{I}];
                end
            end
        end
        y = x(:)';
    end
    function arrayfy(x, varname)
        if ~isscalar(x)
            S = size(x);
            if isscalar(s.mfix)
                s.mfix = repmat(s.mfix, S);
            elseif ~isequal(size(s.mfix), S)
                if numel(s.mfix) == prod(S)
                    if isvector(s.mfix)
                        s.mfix = reshape(s.mfix, S);
                    elseif ~isvector(x)
                        dm(['''' varname ''''])
                    end
                else
                    dm(['''' varname ''''])
                end
            end
        end
    end
end
function x = i2n(x, f)
if isstruct(x)
    for I = fieldnames(x)'
        x.(I{:}) = f(x.(I{:}));
    end
else
    x = f(x);
end
end