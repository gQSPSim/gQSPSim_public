function makeInvalidStyle(t, idx)

% add style
s = uistyle;
s.FontColor = [1 0 0]; % red color

addStyle(t, s, 'cell', [idx(1),idx(2)]);