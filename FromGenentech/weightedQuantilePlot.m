function h = weightedQuantilePlot(t, x, w, col, varargin)
if nargin>5
    q = varargin{1};
else
    q = [0.025, 0.975];
end

if nargin > 5
    style = varargin{2};
else
    style = '-';
end
if isrow(w)
    w = reshape(w,[],1);
end
if iscolumn(t)
    t = reshape(t,1,[]);
end
% if iscolumn(x)
%     x = reshape(x,1,[]);
% end

for tIdx = 1:size(x,1)
    [y,ix] = sort(x(tIdx,:));

    % median
    m(tIdx) = y*w(ix);
    q_l(tIdx) = y(find(cumsum(w(ix)) >= q(1),1,'first'));
    q_u(tIdx) = y(find(cumsum(w(ix)) >= q(2),1,'first'));
    if isempty(q_u(tIdx))
        q_u(tIdx) = y(end);
    end
end

h = shadedErrorBar(t, m, [q_u-m; m-q_l], 'lineprops', {'Color', col, 'LineStyle', style});


