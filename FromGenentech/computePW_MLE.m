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

H = X' *inv(SigY) * X;
f = -(Y' * inv(SigY) * X);
N = size(X,2);
LB = zeros(N,1);
UB = W_max*ones(N,1);
X0 = 1/N*ones(1,N);

Aeq=ones(1,N);
beq=1;

[PW, fval] = quadprog(H,f',[],[],Aeq,beq,LB,UB,X0);

%% reweight to increase diversity of the samples

% second step
Err=X*PW-Y;
Del=abs(Y*0.025);
D = Y;


% this is awesome
A=[X; -X];
b=[Err+Del+D; -Err+Del-D];
H=eye(N);
f=[];
PW = quadprog(H,f,A,b,Aeq,beq,LB,UB,X0);


