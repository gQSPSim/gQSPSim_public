function h = weightedQuantilePlot(t, x, w, col, varargin)

params = inputParser;
params.CaseSensitive = false;
params.addParameter('quantile',[0.025, 0.975],@(x)isnumeric(x));
params.addParameter('linestyle','-',@(x)ischar(x));
params.addParameter('meanlinewidth',0.5,@(x)isnumeric(x));
params.addParameter('boundarylinewidth',0.5,@(x)isnumeric(x));
params.addParameter('parent',[]);

params.parse(varargin{:});

%Extract values from the inputParser
q =  params.Results.quantile;
style =  params.Results.linestyle;
meanlinewidth = params.Results.meanlinewidth;
boundarylinewidth = params.Results.boundarylinewidth;
parent = params.Results.parent;

if isrow(w)
    w = reshape(w,[],1);
end
if iscolumn(t)
    t = reshape(t,1,[]);
end
% if iscolumn(x)
%     x = reshape(x,1,[]);
% end

% filter Nans
ixNan = any(isnan(x));
x = x(:,~ixNan);
w = w(~ixNan);
w = w/sum(w);
if isempty(w)
    h = [];
    return
end

for tIdx = 1:size(x,1)
    [y,ix] = sort(x(tIdx,:));

    % median
%     m(tIdx) = y*w(ix);
    m(tIdx) = y(find(cumsum(w(ix)) >= 0.5,1,'first'));
    
    q_l(tIdx) = y(find(cumsum(w(ix)) >= q(1),1,'first'));
    q_u(tIdx) = y(find(cumsum(w(ix)) >= q(2),1,'first'));
    if isempty(q_u(tIdx))
        q_u(tIdx) = y(end);
    end
end

h = shadedErrorBar(t, m, [q_u-m; m-q_l], 'lineprops', {'Color', col, 'LineStyle', style}, 'meanlinewidth', meanlinewidth, 'boundarylinewidth', boundarylinewidth, 'parent', parent);


