
Nx = 5000;
% x0 = rand(Nx,1);
x0 = linspace(0,1,Nx)';
% a0 = [0.2 0.3 1.1 0.5];
a0 = [1.7 -0.4 1.1 0.5];
Na = length(a0);
y0 = polyval(a0, x0);
x1 = x0 + randn(Nx,1).*0.05;
p1 = polyfit(x1, y0, Na-1);


u_ini = zeros(1, Na);
u_ini(end-1:end) = [1 0];
Niter = 10;
% u = zeros(Niter+1, Na);
% u(1, :) = u_ini;
u = u_ini;
x_ii = [];
alpha = 1.0;
tol = 1e-8;
for iter = 1:Niter
%     u_ii = u(iter, :);
    x_ii = invpolyval(u, y0, x_ii);
    r = x_ii - x1;
    
    du = (Na-1:-1:1).*u(1:end-1);
    dy = polyval(du, x_ii);
    A = (x_ii.^(Na-1:-1:0))./dy;
    AA = A'*A;
    r_u = AA\(A'*r);
    u = u + r_u'.*alpha;
    if all(abs(r_u)<tol)
        break;
    end
end

y1 = polyval(p1, x0);
y2 = polyval(u, x0);

figure; hold on
plot(x1, y0, 'c.', 'MarkerSize', 2.0);
plot(x0, y0, 'g--', 'LineWidth', 2.0);
plot(x0, y1, 'r', 'LineWidth', 1.0);
plot(x0, y2, 'b',  'LineWidth', 1.0);
grid on