function makeItalicizedStyle(t, idx)

% add style
s = uistyle;
s.FontColor = [0.6 0.6 0.6]; % gray color
s.FontAngle  = 'italic';

addStyle(t, s, 'cell', [idx(1),idx(2)]);