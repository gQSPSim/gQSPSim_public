function c = asCell(x)

if iscell(x)
    c = x;
else
    c = {x};
end
