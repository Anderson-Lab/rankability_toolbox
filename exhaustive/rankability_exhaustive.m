function [k,p,P,stats] = rankability_exhaustive(D,varargin)
%% Usage:
% INPUT:  D = n by n data matrix of dominance information. 
%             Can be unweighted (binary) or weighted. e.g., D(i,j)=1 if i beat j. 
%             The diagonal terms must be 0. i.e., D(i,i) = 0
%             For weighted D matrices, 0 <= D(i,j) <= 1
% OUTPUT: k = minimum number of changes (links added or removed) to
%             transform the input graph to a dominance graph, which can be 
%             reordered to strictly upper triangular form.
% OUTPUT: p = cardinality of set P of rankings (dominance graphs) that can
%             be created if k perturbations are allowed. 
% OUTPUT: P = Set of rankings (dominance graphs) that can
%             be created if k perturbations are allowed. 

% set defaults for optional inputs
optargs = struct('normalize', false);
ix = find(strcmp(varargin,'normalize'),1);
if ~isempty(ix)
    optargs.normalize = varargin{ix+1};
end

test_inxs = find(D ~= 1 & D ~= 0);
unweighted = true;
if ~isempty(test_inxs) % for unweighted graph 
    unweighted = false;
end

n = size(D,1);
X=perms(1:n);
X=X';
fitness = zeros(1,size(X,2));
perfectRG=triu(ones(size(D,1)),1);
for l=1:size(X,2)
    perm=X(:,l);
    Dperm = D(perm,perm);
    if unweighted
        fitness(l)=sum(sum(abs(perfectRG-Dperm)));
    else
        fitness(l)=calc_k(Dperm);
    end
end
k=min(fitness);
indexk=find(fitness==k);
p=length(indexk);
P=X(:,indexk);

r = k*p;

stats = struct('r',r);
if optargs.normalize
    if ~exist('max_value')
        max_value = max(max(D)) - min(min(D));
    end
    kmax = max_value*(n^2-n)/2;
    if p == 1 % special case
        tau = 0;
        pval = NaN;
        rho = NaN;
        pval_flattened = NaN;
    else
        [rho,pval] = corr(P,'type','Kendall');
        pval_flattened = NaN*ones(1,(size(pval,1)^2-size(pval,1))/2);
        c = 1;
        for i = 1:size(pval,1)
            for j = (i+1):size(pval,1)
                pval_flattened(c) = pval(i,j);
                c = c + 1;
            end
        end
        tau = mean(pval_flattened);
    end
    rnorm = (kmax - k)/kmax/(p*(1-tau));
    stats.rnorm = rnorm;
    stats.pval = pval;
    stats.rho = rho;
    stats.pval_flattened = pval_flattened;
end