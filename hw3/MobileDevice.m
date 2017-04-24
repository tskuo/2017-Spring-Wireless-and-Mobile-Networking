classdef MobileDevice
  properties
    regBS         % registered BS id
    pos_x         % x-coordinate
    pos_y         % y-coordinate
    timeLeft      % current veocity lasting time, initialize between [minT maxT]
    velocityPhase % [0 ~ 2pi]
    velocitySpeed % [minSpeed maxSpeed]
    minT = 1
    maxT = 6
    minSpeed = 1
    maxSpeed = 15
  end
  methods
    function obj = MobileDevice(bs, x, y)
      obj.regBS = bs;
      obj.pos_x = x;
      obj.pos_y = y;
    end
    function obj = randomWalk(obj)
      obj.timeLeft = obj.minT + (obj.maxT - obj.minT) * rand;
      obj.velocitySpeed = obj.minSpeed + (obj.maxSpeed - obj.minSpeed) * rand;
      obj.velocityPhase = rand * 2 * pi;
    end
  end
end