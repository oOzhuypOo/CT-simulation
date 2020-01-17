function r = crossfit1(t, x, y, lambda, base)

n = length(y);
if nargin<5
    base = 0;
end
r = zeros(1, n+1);
y1 = 2.^(-x(2,:)) + (2.^(-x(3,:))-2.^(-x(1,:))).*(t+base);
y1(y1<0) = 1;
r(1:n) = -log2(y1) - y;
r(n+1) = t*sqrt(n)*lambda;


end