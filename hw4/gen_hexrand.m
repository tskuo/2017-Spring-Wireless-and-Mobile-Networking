% generate n random dots within hexagon
% xv, yv: hexagon
% r: radius of hexagon ( distance from center to corner )
% n: number of dots

function [x, y] = gen_hexrand(base_station_X, base_station_Y, xv, yv, r, n)
  % rng default;
  x = zeros(n, 1);
  y = zeros(n, 1);
  counter = 1;
  while counter <= n
    x_tmp = (2 * r) * rand - r + base_station_X;
    y_tmp = (2 * r) * rand - r + base_station_Y;
    if inpolygon(x_tmp, y_tmp, xv, yv) == 1
      x(counter,1) = x_tmp;
      y(counter,1) = y_tmp;
      counter = counter + 1;
    end
  end
end