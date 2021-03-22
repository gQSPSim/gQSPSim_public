function makeItalicized(t, idx)
% add style
s = uistyle;
s.FontColor = [0.6 0.6 0.6]; % gray color
s.FontAngle  = 'italic';

addStyle(t, s, 'cell', [idx(1),idx(2)]);

% %
% if isnumeric(str)
%     str = num2str(str);
% end
% validateattributes(str,{'char'},{});
% str = sprintf('<html><i><font color="gray">%s</font>',str);