function r = alignfit(y, w, x)
% x = fzero(@(x) alignfit(y, w, x), x0);

y = y(:)';
N = length(y);
xx = 1:N;

y2 = interp1(xx, y, xx-x, 'linear', 0);
w2 = sum(y2.*xx)/sum(y2);
r = w2-w;

end

% function [r, y3] = alignfit(y1, y2, x)
% % x = fzero(@(x) alignfit(y1, y2, x), x0);
% 
% y1 = y1(:)';
% y2 = y2(:)';
% N1 = length(y1);
% N2 = length(y2);
% 
% x1 = 1:N1;
% x2 = 1:N2;
% 
% % r = interp1(x1, y1, x2-x) - y2;
% % r = fillmissing(r, 'nearest');
% 
% % r = -interp1(x1, y1, x2-x).*y2;
% % r = fillmissing(r, 'constant', 0);
% 
% w2 = sum(y2.*x2)/sum(y2);
% y3 = interp1(x1, y1, x2-x);
% w3 = sum(y3.*x2, 'omitnan')/sum(y3, 'omitnan');
% 
% r = w3-w2;
% 
% end