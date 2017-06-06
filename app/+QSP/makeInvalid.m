function str = makeInvalid(str)
validateattributes(str,{'char'},{});
str = sprintf('<html><font color="red">%s (INVALID)</font>',str);
