function str = makeInvalid(str)
if isnumeric(str)
    str = num2str(str);
end
validateattributes(str,{'char'},{});
str = sprintf('<html><font color="red">%s (INVALID)</font>',str);
