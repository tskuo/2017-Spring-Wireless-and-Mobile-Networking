classdef MobileDevice
    
  properties    
    id_BS               % BS id
    x                   % MD position
    y                   % MD position
    timeLeft            % lasting time for current speed, initialized between [ minT, maxT ]
    direction           % [ 0, 2£k ]
    speed               % [ minSpeed, maxSpeed ]
    avgSpeed            %
    handover_timeLeft   %
  end
  
  properties (Constant)
    minT        = 1;    % s
    maxT        = 6;    % s
  end
  
  methods
      
    function obj = MobileDevice( id_BS, x, y, spd )
      obj.id_BS = id_BS;
      obj.x = x;
      obj.y = y;
      obj.handover_timeLeft = 5;
      obj.timeLeft = 0;
      obj.avgSpeed = spd;
    end
    
    function obj = move( obj )
      if obj.timeLeft == 0
        obj.timeLeft = obj.minT + randi( obj.maxT - obj.minT );
        obj.speed = normrnd( obj.avgSpeed, 0.5 * obj.avgSpeed );
        obj.direction = rand * 2 * pi;
      end
      obj.timeLeft = obj.timeLeft - 1;
      obj.x = obj.x + obj.speed * cos( obj.direction );
      obj.y = obj.y + obj.speed * sin( obj.direction );
    end
    
  end
  
end