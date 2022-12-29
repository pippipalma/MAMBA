function x = isICT
% x = isICT
%
%   Author: Giuseppe Palma
%   Date: 24/12/2022

persistent y
if isempty(y)
    y = license('test', 'Instr_Control_Toolbox') && ~isempty(ver('instrument'));
end
x = y;