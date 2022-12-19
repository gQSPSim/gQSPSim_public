function PW = computePW_MLE(X,Y,varargin)

% uncertainty in the data statistics
if nargin>2
   SigY = varargin{1};
else
   SigY = diag(0.1 * abs(Y) + 1e-3);
end
    
if nargin>3
    W_max = 1/varargin{2};
else
    W_max = 0.1;
end

if nargin>4
    DIVERSIFY = varargin{3};
else
    DIVERSIFY = false;
end

if nargin>5
    % membership matrix
    m = varargin{4};
    M = [m; -m];
else
    M = [];
end

if nargin>6
    % target densities for distributions
    dens = varargin{5};
    e = dens*0.05; % 5pct tolerance
    d = [dens + e; -dens + e];
else
    d = [];
end


H = X' *inv(SigY) * X;
f = -(Y' * inv(SigY) * X);
N = size(X,2);
LB = zeros(N,1);
UB = W_max*ones(N,1);
X0 = 1/N*ones(1,N);

Aeq=ones(1,N);
beq=1;

[PW, fval] = quadprog(H,f',M,d,Aeq,beq,LB,UB,X0);

%% reweight to increase diversity of the samples

% second step
Err=X*PW-Y;
Del=abs(Y*0.025);
D = Y;


if ~DIVERSIFY
    % don't perform the second step if this should not be performed
    return
end

A=[X; -X];
b=[Err+Del+D; -Err+Del-D];
H=eye(N);
f=[];
options = optimoptions('quadprog','Display','iter-detailed');
PW = quadprog(H,f,A,b,Aeq,beq,LB,UB,X0, options);


