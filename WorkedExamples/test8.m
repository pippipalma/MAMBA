function test8(clin_table, path_proc, folder_out)

if nargin < 1
    clin_table = 'clin.mat';
end

if nargin < 2
    path_proc = '';
end

if nargin < 3
    folder_out = '';
end

conf = 'test8.mat';

[T, CCS] = image_clin_merge('clin_table', clin_table, 'path_proc', path_proc, conf);

p = ones(size(CCS.mfix));
beta = zeros(size(CCS.mfix));

beta(CCS.mfix) = VBmodel(T, CCS.config.outcome, conf, 'mfix', CCS.mfix, ...
    'vars', CCS.config.vars, 'outs', 'beta');
p(CCS.mfix) =  perm_test(T, CCS.config.outcome, conf, 'mfix', CCS.mfix, ...
    'vars', CCS.config.vars, 'subsampling', [4 4 2], 'dump2file', false, 'N', 1000, 'rng', 1);

mkdir(folder_out)
save(fullfile(folder_out, ['out_' conf]), 'p', 'CCS', 'beta')