function imgfix = antiringonimage(img, center, Lb, Ub)
% anti-ring on image space
% img = antiringonimage(img, center, Lb, Ub);

% gray cut
img(img<Lb) = Lb;
img(img>Ub) = Ub;

Ntheta = 180;
d = 1.0;
flag_even = true;
restcut = 0.1;
Nsect = 4;

% r-theta
raw = rthetatrans(img, center, Ntheta, d, flag_even);
Nb = size(raw, 1);
% Nth = size(raw, 2);
raw = reshape(raw, Nb, []);

% rawfix
% rawfix = conv2(raw, [-1/4 -1/4 1 -1/4 -1/4]');
% rawfix = rawfix(3:end-2, :);
rawring = conv2(raw, [-1/2 1 -1/2]');
rawring = rawring(2:end-1, :);

% restaint
fixrest = [zeros(1, size(raw, 2)); diff(raw)];
fixrest = abs(fixrest) + flipud(abs(fixrest));
fixrest = 1 - (fixrest./(Ub-Lb).*restcut).^2;
fixrest(fixrest<0) = 0;
% apply
rawring = rawring.*fixrest;

% full
rawring = reshape(rawring, Nb, Ntheta, []);
rawring = [rawring flipud(rawring)];

% loop sections
Nimg = size(img, 3);
ringact = zeros(Nb, Nsect+1, Nimg);
for isect = 1:Nsect
    Nv = floor(Ntheta*2/Nsect);
    index = (1 : Nv*2+1) + Nv*(isect-1);
    index = mod(index-1, Ntheta*2)+1;
    ringact(:, isect+1, :) = median(rawring(:, index, :), 2, 'omitnan');
end
% interp
ringact(:, 1, :) = ringact(:, Nsect+1, :);
theta = (0:Ntheta-1).*(pi/Ntheta);
thetaact = linspace(0, pi*2, Nsect+1);
[intp_index, intp_alpha] = interpprepare(thetaact, theta, 'extrap');
rawfix = ringact(:, intp_index(:, 1), :).*intp_alpha(:, 1)' + ringact(:, intp_index(:, 2), :).*intp_alpha(:, 2)';
rawfix = rawfix.*2;

% rawring = median(rawring, 2, 'omitnan');

% radius cut
Na = size(img, 1);
% Nb = size(rawfix, 1);
Ncut = max(ceil((Nb-Na)/2), 0);
rawfix(1:Ncut, :, :) = 0;
rawfix(end-Ncut+1:end, :, :) = 0;

% % rep
% rawring = repmat(rawring, 1, Ntheta);

% inv r-theta
imgfix = rthetainv(rawfix, center, Na, d);

end