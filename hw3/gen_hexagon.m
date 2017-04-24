% generate hexagon with radius r center at (x,y)

function [xv, yv] = gen_hexagon(x, y, r)
  L = linspace(0,2.*pi,7);
  xv = x + r .* cos(L)';
  yv = y + r .* sin(L)';
end