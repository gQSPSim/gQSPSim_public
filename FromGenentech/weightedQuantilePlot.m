function h = weightedQuantilePlot(t, x, w, col, varargin)

params = inputParser;
params.CaseSensitive = false;
params.addParameter('quantile',[0.025, 0.975],@(x)isnumeric(x));
params.addParameter('linestyle','-',@(x)ischar(x));
params.addParameter('meanlinewidth',0.5,@(x)isnumeric(x));
params.addParameter('boundarylinewidth',0.5,@(x)isnumeric(x));
params.addParameter('parent',[]);
params.addParameter('style','quantile');


params.parse(varargin{:});

%Extract values from the inputParser
q =  params.Results.quantile;
linestyle =  params.Results.linestyle;
meanlinewidth = params.Results.meanlinewidth;
boundarylinewidth = params.Results.boundarylinewidth;
parent = params.Results.parent;

style = params.Results.style;

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
if size(x,1) > 1
    ixNan = any(isnan(x));
    x = x(:,~ixNan);
    w = w(~ixNan);
else
    ixNan = isnan(x);
    x = x(~ixNan);
    w = w(~ixNan);
end

w = w/sum(w);
if isempty(w)
    h = [];
    return
end

for tIdx = 1:size(x,1)
    [y,ix] = sort(x(tIdx,:));

    % median
%     m(tIdx) = y*w(ix);
    
%     if strcmp(style, 'quantile')
        m(tIdx) = y(find(cumsum(w(ix)) >= 0.5,1,'first'));        
        q_l(tIdx) = y(find(cumsum(w(ix)) >= q(1),1,'first'));
        q_u(tIdx) = y(find(cumsum(w(ix)) >= q(2),1,'first'));
%     elseif strcmp(style, 'mean_std')
%         mean_y =  y*w(ix);
%         m(tIdx) = mean_y;
%         std_y = sqrt((y - mean_y).^2 * w(ix));
%         if strcmp(get(parent,'YScale'),'log')
%             q_l(tIdx) = max(1e-10, mean_y - 2*std_y);
%         else
%             q_l(tIdx) = mean_y - 2*std_y;
%         end
%         q_u(tIdx) = mean_y + 2*std_y;
%     end
    
    if isempty(q_u(tIdx))
        q_u(tIdx) = y(end);
    end
end

if length(t) > 1
    h = shadedErrorBar(t, m, [q_u-m; m-q_l], 'lineprops', {'Color', col, 'LineStyle', linestyle}, 'meanlinewidth', meanlinewidth, 'boundarylinewidth', boundarylinewidth, 'parent', parent);
else
    h = errorbar(t, m, m-q_l,q_u-m, 'Color', col, 'LineStyle', linestyle, 'LineWidth',  ...
        meanlinewidth, 'parent', parent, 'Marker', 'o');
end

