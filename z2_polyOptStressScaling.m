function  [fOpt,mResult,s,infoOut]=z2_polyOptStressScaling(D,fMax,mTarget,fo,p,q)


%z2_polyOptStressScaling - Perform Static Optimization with Stress Units
%
%
%[fOpt,mResult,s,infoOut]=z2_polyOptStressScaling(D,fMax,mTarget,fo,p,q)
%
%       Inputs:
%           D - Matrix (Joints by Muscle) of moments arms
%           fMax - Max Isometric Force for Each  (row vector)
%           mTarget - Moments at Each Joint (column vector)
%           fo - Initial guess for each force (row vector)
%           p - polynomial power to use
%           q - prescaler value
%
%       Outputs:
%           fOpt - Result Forces
%           mResults - result moments (should match mTarget)
%           s - value of objective function
%           infoOut - info returned from IPOPT



global c


c.D=D;
c.fMax=fMax;
c.pCsa=c.fMax/25e4;
c.n=p;
c.q=q;


% Set the bounds and constraints
options.lb = zeros(1,length(fo));  % Lower bound on the variables.
options.ub = c.fMax;  % Upper bound on the variables.
options.cl = mTarget;   % Lower bounds on the constraint functions.
options.cu = mTarget;   % Upper bounds on the constraint functions.

% Set the IPOPT options
%options.ipopt.jac_c_constant        = 'yes';
options.ipopt.hessian_approximation = 'limited-memory';
%options.ipopt.mu_strategy           = 'adaptive';
options.ipopt.tol                   = 1e-7;

% The callback functions.
funcs.objective         = @objFunc;
funcs.constraints       = @constrFunc;
funcs.gradient          = @gradObjFunc;
funcs.jacobian          = @constraintJac;
funcs.jacobianstructure = @() sparse(c.D);

%Run IPOPT
[fOpt infoOut] = ipopt(fo,funcs,options);
mResult=constrFunc(fOpt);
s=objFunc(fOpt);

%---------------------------------------------------
function s=objFunc(f)
%The objective to minimize
%   Input  f: muscle forces as provided by IPOPT

global c
s=sum((f./c.pCsa*c.q).^c.n);

%---------------------------------------------------
function ds_df=gradObjFunc(f)
%The gradient of the objective
%   Input  f: muscle forces as provided by IPOPT
%   Output ds_df: change in objective with change in force

global c
a=(c.q./c.pCsa).^c.n;
b=c.n.*(f.^(c.n-1));
ds_df=a.*b;

%---------------------------------------------------
function m=constrFunc(f)
%The constraints
%   Input  f: muscle forces as provided by IPOPT
%   Output m: moments at the joints

global c
m=c.D*f';  %Calculate the moments

%---------------------------------------------------
function dm_df=constraintJac(f)
%The jacobian (sparse gradient) of the constraints
%   Input  f: muscle forces as provided by IPOPT
%   Output dm_df: change in moments with change in forces

global c
dm_df=sparse(c.D);  %dm_df is just the moment arm