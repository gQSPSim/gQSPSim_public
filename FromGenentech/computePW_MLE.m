function PW = computePW_MLE(X,Y,varargin)

% uncertainty in the data statistics
if nargin>2
   SigY = varargin{1};
else
   SigY = diag(0.1 * abs(Y));
end
    
if nargin>3
    W_max = varargin{2};
else
    W_max = 0.1;
end

H = X' *inv(SigY) * X;
f = -(Y' * inv(SigY) * X);
N = size(X,2);

PW = quadprog(H,f',[],[],ones(1,N),1,zeros(N,1),W_max*ones(N,1));