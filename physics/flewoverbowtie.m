function [Dmu, L] = flewoverbowtie(A, B, bowtie, filter, samplekeV)
% projection on bowtie and filter, from position A to position B
% Dmu = flewoverbowtie(A, B, bowtie, filter, samplekeV);
% or typically,
% [Dmu, L] = flewoverbowtie(focalposition, detectorposition, bowtie, filter, samplekeV);

% x y z
xx = B(:,1) - A(:,1)';
yy = B(:,2) - A(:,2)';
zz = B(:,3) - A(:,3)';
% geometry
XYangle = atan2(yy, xx) - pi/2;
Zscale = sqrt(yy.^2+zz.^2)./yy;  
Dfscale = (sqrt(xx.^2+yy.^2+zz.^2)./yy);

% ini Dmu
Nd = size(xx, 1);
Nsample = length(samplekeV(:));
Dmu = zeros(Nd, Nsample);

% bowtie(s)
Nbowtie = length(bowtie);
for ibow = 1:Nbowtie
    bowtie_ii = bowtie{ibow};
    if isempty(bowtie_ii.bowtiecurve)
        % empty bowtie
        continue;
    end
    % D
    D_bowtie = interp1(bowtie_ii.anglesample, double(bowtie_ii.bowtiecurve), XYangle, 'linear', 'extrap');
    D_bowtie = D_bowtie.*Zscale;
    % mu
    mu_bowtie = interp1(bowtie_ii.material.samplekeV, bowtie_ii.material.mu_total, samplekeV);
    % I know in most case bowtie.material.samplekeV == samplekeV
    % + to Dmu
    Dmu = Dmu + D_bowtie(:)*mu_bowtie;
end

% filter(s)
Nfilter = length(filter(:));
for ifil = 1:Nfilter
    filter_ii = filter{ifil};
    % D
    if ~isfield(filter_ii, 'effect')
        D_filter = Dfscale.*filter_ii.thickness;
    elseif filter_ii.effect
        % do not scale by angle;
        D_filter = filter_ii.thickness;
    else
        D_filter = Dfscale.*filter_ii.thickness;
    end
    % mu
    mu_filter = interp1(filter_ii.material.samplekeV, filter_ii.material.mu_total, samplekeV);
    % + to Dmu
    Dmu = Dmu + D_filter(:)*mu_filter;
end

% drop by L 
L = sqrt(xx.^2+yy.^2+zz.^2);

end