function str = makeMissing(str)
validateattributes(str,{'char'},{});
str = sprintf('<html><i><font color="gray">%s</font>',str);
