function x = isPCT
% x = isPCT
%
%   Author: Giuseppe Palma
%   Date: 19/04/2022

persistent y
if isempty(y)
    y = true;
    try
        getCurrentTask;
    catch err
        if ~strcmp(err.identifier, 'MATLAB:UndefinedFunction')
            rethrow(err);
        end
        y = false;
    end
end
x = y;