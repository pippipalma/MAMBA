function wk = parfor_det(workers)
% number_of_workers = parfor_det(workers_opt)
%
%   Author: Giuseppe Palma
%   Date: 11/04/2023

persistent nw
p = gcp('nocreate');
if isempty(p)
    if isempty(nw)
        if isPCT
            pc = parcluster;
            nw = pc.NumWorkers;
        else
            nw = 0;
        end
    end
    n = nw;
else
    n = p.NumWorkers;
end
if workers == 1
    wk = n;
else
    wk = min(n, double(workers));
end