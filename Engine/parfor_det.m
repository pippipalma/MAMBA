function wk = parfor_det(workers)
% number_of_workers = parfor_det(workers_opt)
%
%   Author: Giuseppe Palma
%   Date: 19/04/2022

persistent nw
if isempty(nw)
    if isPCT
        pc = parcluster;
        nw = pc.NumWorkers;
    else
        nw = 0;
    end
end
if workers == 1
    wk = nw;
else
    wk = min(nw, double(workers));
end