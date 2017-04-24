classdef BaseStation
  properties
    id
    pos_x  % BS location
    pos_y  % BS location
    xv     % matlab hexagon contour
    yv     % matlab hexagon contour
    power  % total recived power from devices
  end
  methods
    function obj = BaseStation(id, x, y, xv, yv)
      obj.id = id;
      obj.pos_x = x;
      obj.pos_y = y;
      obj.xv = xv;
      obj.yv = yv;
    end
  end
end