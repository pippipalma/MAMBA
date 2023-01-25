function [tab, CCS] = image_clin_merge(varargin)
% [tab, CCS] = image_clin_merge(options)
% [tab, CCS] = image_clin_merge(img, CCS, options)
%
% Options:
%   - clin_table
%   - clin_vars
%   - der_vars
%   - include_all_patients
%   - keep_all_columns
%   - MVA_opt
%   - outcome
%   - refine_mask
%   - select_patients
%   - vars
%   Further options are shared with function image_read.
%
%   Author: Giuseppe Palma
%   Date: 17/01/2023

if istable(varargin{1})
    [tab, CCS] = varargin{1 : 2};
    varargin(1 : 2) = [];
else
    [tab, CCS] = image_read(varargin{:});
    varargin = {};
end
s = keep_rem(CCS.config.image_read_default(1 : 2 : end), [], ...
    {'ID_include' 'ID_exclude' 'masks' 'mobile_masks' 'progress_bar'});
dv = keep_rem(tab.Properties.VariableNames, CCS.config.images);
s = opt_pars('clin_table', 'clin.mat', 'der_vars', {}, 'outcome', {}, ...
    'clin_vars', {}, 'categ_vars', {}, 'MVA_opt', {}, ...
    'vars', dv, 'refine_mask', '', ...
    'include_all_patients', false, 'keep_all_columns', false, ...
    'select_patients', '', ...
    keep_rem(CCS.config, [], s), varargin{:}, keep_rem(CCS.config, s));
s.masks = norm_fields(s.masks);
s.mobile_masks = norm_fields(s.mobile_masks);
if istable(s.clin_table)
    T = s.clin_table;
else
    T = load(s.clin_table);
    n = fieldnames(T);
    T = T.(n{:});
end
if s.include_all_patients
    j = @outerjoin;
else
    j = @innerjoin;
end
tab = j(tab, T(ID_select(T.Properties.RowNames, s.ID_include, s.ID_exclude), :), 'Keys', 'Row');
UO = {'UniformOutput' false};
for i = 1 : width(tab)
    if ~iscell(tab.(i)) || ~isvector(tab.(i))
        tab.(i) = arrayfun(@(x) NaN2empty(tab.(i)(x, :)), (1 : height(tab))', UO{:});
    end
end
l = height(tab);
if ~isempty(s.der_vars) && ischar(s.der_vars{1})
    s.der_vars = {s.der_vars};
end
CCSv = @(x) strcmp('#', x(1 : min(end, 1))) && isfield(CCS, x(2 : end));
ops = {{'xor' 'symmdiff' 1} {'and' '&' 1} {'or' '|' 1} {'lt' '<' 0} ...
    {'gt' '>' 0} {'eq' '==' '=' 0} {'ne' '~=' '<>' 0} {'le' '<=' 0} ...
    {'ge' '>=' 0} {'plus' '+' 1} {'minus' '-' 1} {'mtimes' '*' 1} ...
    {'times' '.*' 1} {'rdivide' './' 1} {'mrdivide' '/' 1} {'ldivide' '.\' 1} ...
    {'mldivide' '\' 1} {'mpower' '^' 1} {'power' '.^' 1} {'difference' 1}};
n = numel(s.der_vars);
tab(:, cellfun(@(x) x{1}, s.der_vars, UO{:})) = cell(l, n);
tabv = @(x) ismember(x, tab.Properties.VariableNames);
ppm = ProgrBar(s.progress_bar, 'create', [l n], false, ...
    {'Patients' 'Derived variables'});
for i = 1 : l
    for j = 1 : n
        tab{i, s.der_vars{j}{1}} = {combine(s.der_vars{j}{2})};
        ProgrBar(ppm, 'update')
    end
end
ProgrBar(ppm, 'delete')
if ismember(s.select_patients, tab.Properties.VariableNames)
    tab(cellfun(@(x) isempty(x) || ~x, tab{:, s.select_patients}), :) = [];
end
s.outcome = norm_fields(s.outcome);
s.clin_vars = norm_fields(s.clin_vars);
clinvar = parse_var(s.clin_vars);
imput = find(cellfun(@(x) iscell(x) && ...
    all(cellfun(@(y) isempty(y) || isscalar(y), tab{:, x{1}})), clinvar));
l = length(imput);
clin_nv = cell(height(tab), l);
if ~isempty(imput)
    tab{:, [clinvar{imput}]} = cellfun(@double, tab{:, [clinvar{imput}]}, UO{:});
end
ppm = ProgrBar(s.progress_bar, 'create', l, false, 'Imputation');
for i = 1 : l
    cvi = clinvar{imput(i)};
    clin_nv(:, i) = tab{:, cvi{1}};
    rows = ~cellfun(@isempty, tab{:, cvi});
    p_imp = find(~rows(:, 1));
    [empty_patt, ~, ip] = unique(rows(p_imp, 2 : end), 'rows');
    for j = 1 : size(empty_patt, 1)
        tr_pat = all(rows(:, [true empty_patt(j, :)]), 2);
        ts_pat = p_imp(ip == j);
        v = cell2mat(clin_nv(tr_pat, i));
        if sum(empty_patt(j, :)) == 0
            yy = repmat(mean(v), size(ts_pat));
        else
            vars = cvi([false empty_patt(j, :)]);
            prd = cell2mat(tab{tr_pat, vars});
            prdt = cell2mat(tab{ts_pat, vars});
            [vv, ~, ix] = unique(v);
            if length(vv) == 2
                yy = vv(1) + diff(vv)*glmval(glmfit(prd, ix - 1, 'binomial'), prdt, 'logit');
            else
                yy = glmval(glmfit(prd, v), prdt, 'identity');
            end
        end
        clin_nv(ts_pat, i) = num2cell(yy);
    end
    clinvar{imput(i)} = cvi{1};
    ProgrBar(ppm, 'update')
end
ProgrBar(ppm, 'delete')
for i = 1 : l
    tab{:, clinvar{imput(i)}} = clin_nv(:, i);
end
if isempty(s.clin_vars) || ~isscalar(s.outcome) || ...
        any(cellfun(@(x) numel(x) > 1, tab{:, s.outcome}))
    cvr = {};
    s.MVA = [];
else
    vv = [clinvar s.outcome];
    s.categ_vars = norm_fields(s.categ_vars);
    ppm = ProgrBar(s.progress_bar, 'create', 1, false, 'Variable selection');
    [cvr, s.MVA] = MVA(tab(~any(cellfun(@isempty, tab{:, vv}), 2), vv), ...
        s.outcome, 'categ_vars', parse_var(s.categ_vars), s.MVA_opt{:});
    ProgrBar(ppm, 'delete')
end
s.vars = reshape(union(parse_var(norm_fields(s.vars)), cvr), 1, []);
if ~(s.include_all_patients || isempty([s.vars s.outcome]))
    tab(any(cellfun(@isempty, tab{:, [s.vars s.outcome]}), 2), :) = [];
end
if s.join_images
    CCS.mfix = false;
    for j = 1 : length(s.masks)
        CCS.mfix = CCS.mfix | CCS.(s.masks{j});
    end
    if ~any(CCS.mfix, 'all')
        r = keep_rem(fieldnames(CCS), [CCS.config.masks s.template_images s.images]);
        CCS.mfix = true(size(CCS.(r{1})));
    end
    if ~isempty(s.refine_mask)
        if ischar(s.refine_mask)
            s.refine_mask = str2func(s.refine_mask);
        end
        ar = {tab CCS};
        CCS.mfix = CCS.mfix & s.refine_mask(ar{1 : nargin(s.refine_mask)});
    end
    if ~isempty(s.mobile_masks)
        l = height(tab);
        mmob = cell(l, 1);
        mpat = mmob;
        lg = islogical(tab{1, s.mobile_masks{1}}{:});
        if lg
            ic = false;
            fun = @or;
        else
            ic = 0;
            fun = @plus;
        end
        ppm = ProgrBar(s.progress_bar, 'create', l, false, 'Patients'' masks');
        for j = 1 : l
            mmob{j} = ic;
            for k = 1 : length(s.mobile_masks)
                if ~isempty(tab{j, s.mobile_masks{k}}{:})
                    mmob{j} = fun(mmob{j}, tab{j, s.mobile_masks{k}}{:});
                end
            end
            if lg
                mpat{j} = CCS.mfix & ~mmob{j};
            else
                mpat{j} = max(0, CCS.mfix - mmob{j});
            end
            ProgrBar(ppm, 'update')
        end
        ProgrBar(ppm, 'delete')
        tab{:, 'mmob'} = mmob;
        tab{:, 'mpat'} = mpat;
    else
        tab{:, 'mpat'} = {CCS.mfix};
    end
end
if ~s.keep_all_columns
    tab = keep_rem(tab, ['mpat' s.vars s.outcome]);
end
CCS.config = s;
    function pvar = parse_var(var)
        pvar = {};
        for V = 1 : length(var)
            if ischar(var{V})
                pvar = [pvar proc_var(var{V})];
            else
                tvar = {};
                for W = 2 : length(var{V})
                    tvar = [tvar proc_var(var{V}{W})];
                end
                pvar = [pvar {[var{V}{1} tvar]}];
            end
        end
    end
    function proc = proc_var(str)
        proc = keep_rem({str}, [], s.outcome);
    end
    function o = combine(o)
        alt = true;
        if iscell(o)
            for I = 1 : length(o)
                if I == 1 && ~(tabv(o{I}) || CCSv(o{I}))
                    alt = false;
                else
                    o{I} = combine(o{I});
                end
            end
        elseif ischar(o)
            if tabv(o)
                o = tab{i, o}{:};
            elseif CCSv(o)
                o = CCS.(o(2 : end));
            end
        end
        if alt
            return
        end
        switch o{1}
            case [ops{:}]
                I = cellfun(@(x) ismember(o{1}, x(1 : end - 1)), ops);
                f = @(X) empty_handle(str2func(ops{I}{1}), X);
                L = ops{I}{end};
                if ismember(o{1}, {'minus' '-'}) && numel(o) == 2
                    o(2 : 3) = [0 o(2)];
                end
            otherwise
                L = false;
                if strcmp(o{1}, '~')
                    o{1} = 'not';
                end
                f = @(X) feval(o{1}, X{:});
        end
        dm = o(2 : end);
        if L
            o = itr(f, dm);
        else
            o = f(dm);
        end
        if isnumeric(o) && any(isnan(o), 'all')
            o = [];
        end
    end
end

function x = first(varargin)
i = find(~cellfun(@isempty, varargin), 1);
if isempty(i)
    x = [];
else
    x = varargin{i};
end
end

function a = difference(a, b)
a = a & ~b;
end

function m = itr(op, arr)
m = arr{1};
for i = 2 : length(arr)
    m = op({m arr{i}});
end
end

function x = NaN2empty(x)
if isnumeric(x) && any(isnan(x)) || isdatetime(x) && any(isnat(x))
    x = [];
end
end

function x = empty_handle(f, x)
if any(cellfun(@isempty, x))
    x = [];
else
    x = f(x{:});
end
end