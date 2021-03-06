function [sopt Qopt Topt copt Qmax Tmax copt2] = snQTCpoissonOptFast3(Kr,K0,L,lamda,h,p,epsq,epst, estop, tmin, tmax)
copt = 10.0^30;   % the optimal (s,nQ,T) value; 
copt2 = 10.0^30;  % the optimal (s,nQ,T) value s.t. Q>epsilon
if nargin < 11
    tmax = 100;
end
if nargin < 10
    tmin = 5/lamda;
end
if nargin < 9  % if this value is one, run only for Q=0, i.e. run (R,T) policy
    estop = 0;
end
if nargin < 8  % time dimension precision
    epst = 1;
end
if nargin < 7  % batch size dimension precision
    epsq = 1;
end
T = tmin;
%T=1.e-6;  % start with continuous review cost (T~0)
%T = 5 / lamda;  % temporary Tmin
Qmax=0;
%options = optimset('MaxFunEvals',5000, 'TolFun', 1.0e-3, 'MaxIter', 3000);
s0 = 1;
s1 =1;
while T<=tmax+1.e-12
    Q=1;
    Hmdtprev = 10^25;
    while Q>0
        % let s' be the argmin. of c(s,Q,T)
        %s0=lamda*(L+T);
        %smax=(lamda+10*sqrt(lamda))*(L+T);
        %smin = -ceil(s0);
        % sqt=lsqnonlin(@(x) aTLCpoisseq(x,Q,T,L,lamda,h,p), s0, smin, smax);
        %[sqt c exitflag] = fmincon(@(x) snQTCpoisson(x,Q,T,Kr,K0,L,lamda,h,p), s0,[],[],[],[],smin,smax,[],options); 
        %[sqt c0] = findmins(Q,T,L,lamda,h,p,smin);
        sqt = findmins2(Q,T,L,lamda,h,p,0,s0);  % 0 is the p2 value
        if Q==1
            s1 = sqt;
        end
        s0 = sqt;
        c = snQTCpoisson(sqt,Q,T,Kr,K0,L,lamda,h,p);
        %if exitflag<=0
        %    error('optimization in snQTpoissonOptFast() failed');
        %end
        %sqt = fminsearch(@(x) snQTCpoisson(x,Q,T,Kr,K0,L,lamda,h,p), s0, options);
        %c = snQTCpoisson(sqt,Q,T,Kr,K0,L,lamda,h,p);
        if c < copt
           sopt = sqt;
           Qopt = Q;
           Topt = T;
           copt = c;
           disp(['found better value ' num2str(copt) ' Q=' num2str(Q) ' T=' num2str(T)]);  % itc: HERE rm asap
        end
        if c < copt2 && Q>1
            copt2 = c;
        end
        % find the Hmdt = min_{s}H(s,Q,T;Kr)
        Hmdt = snQTCpoisson(sqt,Q,T,Kr,0,L,lamda,h,p);
        if Hmdt > copt && Hmdt > Hmdtprev
            break;
        end
        Hmdtprev=Hmdt;
        if estop==1
            break;  % only run for Q=1 (i.e. (R,T) policy)
        end
        Q=Q+epsq;
        if Qmax < Q
            Qmax=Q;
        end
    end
    % find the Hm = min_{s,Q}H(s,Q,T;Kr)
    %v0=[sqt Q];
    % vmin = [0 1];
    % vmax = [(L+T)*(lamda+20*sqrt(lamda)) 10^30];
    % vsol = fmincon(@(v) aTLCpoisseq(v,T,Kr,L,lamda,h,p), v0,[],[],[],[],vmin,vmax,options);
    % vsol = fminsearch(@(v) aTLCpoisseqH(v,T,Kr,L,lamda,h,p), v0, options);
    % Hm = snQTCpoisson(vsol(1), vsol(2), T, Kr,0,L,lamda,h,p);
    Hm = snQTCpoisson(s1,1,T,0,0,L,lamda,h,p);  % used to be ...,T,Kr,0,...
    if Hm > copt
        break;
    end
    T=T+epst;
end
Tmax=T;
end

function sqt = findmins2(Q,T,L,lamda,h,phat,p,s0)
s = s0;
sqt = s;
c = snQTCpoisson(s,Q,T,0,0,L,lamda,h,phat,p);
cs = snQTCpoisson(s+1,Q,T,0,0,L,lamda,h,phat,p);
if c < cs 
   % keep decreasing s
   while true
       s = s-1;
       cs = snQTCpoisson(s,Q,T,0,0,L,lamda,h,phat,p);
       if cs >= c
           sqt = s+1;
           break;
       end
       c = cs;
       sqt = s;
   end
else if c > cs
        % keep increasing s
        while true
            s = s+1;
            cs = snQTCpoisson(s,Q,T,0,0,L,lamda,h,phat,p);
            if cs >= c
                sqt = s-1;
                break;
            end
            c = cs;
            sqt = s;
        end
    end
end
end