function f = asCell(X)
if iscell(X)
    f = cell2mat(X);
else
    f = X;
end