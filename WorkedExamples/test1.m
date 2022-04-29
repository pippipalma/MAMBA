function test1(clin_table, path_proc, folder_out)

if nargin < 1
    clin_table = 'clin.mat';
end

if nargin < 2
    path_proc = '';
end

if nargin < 3
    folder_out = '';
end

conf = 'test1.mat';

[T, CCS] = image_clin_merge('clin_table', clin_table, 'path_proc', path_proc, conf);

p = ones(size(CCS.mfix));
p0 = p;
beta = zeros(size(CCS.mfix));

beta(CCS.mfix) = VBmodel(T, CCS.config.outcome, conf, 'vars', CCS.config.vars,...
    'outs', 'beta');
p(CCS.mfix) =  perm_test(T, CCS.config.outcome, conf, 'dump2file', false, ...
    'vars', CCS.config.vars, 'subsampling', [4 4 2], 'N', 1000, 'rng', 1);
p0(CCS.mfix) =  perm_test(T, CCS.config.outcome, conf, 'dump2file', false, ...
    'vars', CCS.config.vars, 'N', 1000, 'rng', 1, 'perm_test_workers', false);

mkdir(folder_out)
save(fullfile(folder_out, ['out_' conf]), 'p', 'p0', 'CCS', 'beta')