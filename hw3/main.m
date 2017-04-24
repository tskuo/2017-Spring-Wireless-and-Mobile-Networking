%% [100 moving mobile device, uplink]
%   In this problem, only uplink case is considered. 100 mobile devices do
%   uplink communication and moves based on random walk mobility model as
%   described below.

clear;
clc;

%% given parameters
temperature          = 27 + 273.15;  % unit: K
ISD                  = 500;          % unit: m
bandwidth            = 10 * 10 ^ 6;  % unit: Hz
freq_reuse_factor    = 1;            % unit: None
base_station_power   = 33;           % unit: dBm
mobile_device_power  = 23;           % unit: dBm
transmitter_gain     = 14;           % unit: dB
receiver_gain        = 14;           % unit: dB
base_station_height  = 1.5;          % unit: m
building_height      = 50;           % unit: m
mobile_device_height = 1.5;          % unit: m
mobile_device_num    = 100;          % number of devices
base_station_num     = 19;           % number of base stations
simulation_time      = 900;          % unit: second

base_station_X = ISD/sqrt(3).*[0, 0, -1.5, -1.5, 0, 1.5, 1.5, 0, -1.5, -3, -3, -3, -1.5, 0, 1.5, 3, 3, 3, 1.5];
base_station_Y = ISD.*[0, 1,  0.5, -0.5, -1, -0.5, 0.5, 2, 1.5, 1, 0, -1, -1.5, -2, -1.5, -1, 0, 1, 1.5];
extend_central_X = ISD/sqrt(3).*[7.5, 4.5, -3, -7.5, -4.5, 3];
extend_central_Y = ISD.*[-0.5, 3.5, 4, 0.5, -3.5, -4];
extend_central_num = 6;
% Consider the path loss only radio propagation (without shadowing and fading).
% Use Two-ray-ground model as the propagation model for simulation.

default_show_extend_cells  = false;
default_show_extend_border = false;

%% Initilize
% arrange 19 BS cell IDs
BSs = cell(1,base_station_num);
for i = 1:base_station_num
   [xv_tmp, yv_tmp] = gen_hexagon(base_station_X(1,i), base_station_Y(1,i), ISD/sqrt(3));
   bs_tmp = BaseStation(i, base_station_X(1,i), base_station_Y(1,i), xv_tmp, yv_tmp);
   BSs{1,i} = bs_tmp;
   if i == 1
     central_xv = xv_tmp;
     central_yv = yv_tmp;
   else
     [central_xv, central_yv] = polybool('union', central_xv, central_yv, xv_tmp, yv_tmp ); 
   end
end

% 100 mobile devices
MSs = cell(1,mobile_device_num);
for i = 1:mobile_device_num
  BSid = randi(base_station_num); % uniformly distributed integer between 1:base_station_num
  [x, y] = gen_hexrand(BSs{1,BSid}.pos_x, ...
                       BSs{1,BSid}.pos_y, ...
                       BSs{1,BSid}.xv, ...
                       BSs{1,BSid}.yv, ...
                       ISD/sqrt(3),1);
  ms_tmp = MobileDevice(BSid, x, y);
  ms_tmp = ms_tmp.randomWalk();
  MSs{1,i} = ms_tmp;
end

% extend surrounding cells
extend_BSs = cell(1,extend_central_num);
extend_xv  = cell(1,extend_central_num);
extend_yv  = cell(1,extend_central_num);
for i = 1:extend_central_num
  extend_BS_tmp = cell(1,base_station_num);
  for j = 1:base_station_num
    x = extend_central_X(1,i) + base_station_X(1,j);
    y = extend_central_Y(1,i) + base_station_Y(1,j);
    [xv_tmp, yv_tmp] = gen_hexagon(x, y, ISD/sqrt(3));
    bs_tmp = BaseStation(j, x, y, xv_tmp, yv_tmp);
    extend_BS_tmp{1,j} = bs_tmp;
    if j == 1
      xv_total = xv_tmp;
      yv_total = yv_tmp;
    else
      [xv_total, yv_total] = polybool('union', xv_total, yv_total, xv_tmp, yv_tmp );
    end
  end
  extend_xv{1,i} = xv_total;
  extend_yv{1,i} = yv_total;
  extend_BSs{1,i} = extend_BS_tmp;
end

% plot initial location
figure('Name', 'B-2');
xlabel('x-direction (meter)');
ylabel('y-direction (meter)');
title('Figure B-2');
for i = 1:base_station_num
  plot(BSs{1,i}.xv, BSs{1,i}.yv, '-k', 'linewidth', 2);
  hold on;
  plot(BSs{1,i}.pos_x, BSs{1,i}.pos_y, 'r*');
  hold on;
  txt = int2str(i);
  text(BSs{1,i}.pos_x, BSs{1,i}.pos_y, txt);
end
for i = 1:mobile_device_num
  plot(MSs{1,i}.pos_x, MSs{1,i}.pos_y, 'bx');
  hold on;
end
if default_show_extend_cells
  for i = 1:extend_central_num
    for j = 1:base_station_num
      plot(extend_BSs{1,i}{1,j}.xv, extend_BSs{1,i}{1,j}.yv, '-k', 'linewidth', 1);
      hold on;
    end
  end
end
if default_show_extend_border
  for i = 1:extend_central_num
    plot(extend_central_X(1,i), extend_central_Y(1,i), 'g*');
    hold on;
    plot(extend_xv{1,i}, extend_yv{1,i}, '-k', 'linewidth', 1);
    hold on;
  end
end
hold off;

% thermal noise
N = thermal_noise_power(temperature, bandwidth);

% table init
time = [];
Source_Cell_ID = [];
Destination_Cell_ID = [];

% counter init
counter = 0;

%% simulation loop
for t = 0:simulation_time
  % compute BSs total received power
  for i = 1:base_station_num
    total_power = 0;
    for j = 1:mobile_device_num
      distance = sqrt((BSs{1,i}.pos_x-MSs{1,j}.pos_x)^2 + (BSs{1,i}.pos_y-MSs{1,j}.pos_y)^2);
      power = dB_2_watt(received_power_dB(mobile_device_power, building_height + base_station_height, ...
                        mobile_device_height, distance, transmitter_gain, receiver_gain));
      total_power = total_power + power;
    end
    BSs{1,i}.power = total_power;
  end

  % compute SINR for each MSs, update registered BS id if necessary
  for j = 1:mobile_device_num
    maxBS = MSs{1,j}.regBS;
    maxSINR = 0;
    for i = 1:base_station_num
      distance = sqrt((BSs{1,i}.pos_x-MSs{1,j}.pos_x)^2 + (BSs{1,i}.pos_y-MSs{1,j}.pos_y)^2);
      power = dB_2_watt(received_power_dB(mobile_device_power, building_height + base_station_height, ...
                        mobile_device_height, distance, transmitter_gain, receiver_gain));
      S = power;
      I = BSs{1,i}.power - power;
      sinr = SINR(S, I, N);
      if sinr > maxSINR
        maxBS = BSs{1,i}.id;
        maxSINR = sinr;
      end
    end
    if maxBS ~= MSs{1,j}.regBS
      if t ~= 0
        time = [time t];
        Source_Cell_ID = [Source_Cell_ID MSs{1,j}.regBS];
        Destination_Cell_ID = [Destination_Cell_ID maxBS];
        counter = counter + 1;
      end
      MSs{1,j}.regBS = maxBS;
    end
  end
  
  % move MSs according to their velocities
  for i = 1:mobile_device_num
    MSs{1,i}.pos_x = MSs{1,i}.pos_x + MSs{1,i}.velocitySpeed*cos(MSs{1,i}.velocityPhase);
    MSs{1,i}.pos_y = MSs{1,i}.pos_y + MSs{1,i}.velocitySpeed*sin(MSs{1,i}.velocityPhase);
    MSs{1,i}.timeLeft = MSs{1,i}.timeLeft - 1;
    if MSs{1,i}.timeLeft == 0
      MSs{1,i}.randomWalk()
    end
    % if out of range have to update pos_x and pos_y, DO NOT UPDATE regBS
    if inpolygon(MSs{1,i}.pos_x, MSs{1,i}.pos_y, central_xv, central_yv) == 0
      for j = 1:extend_central_num
        if inpolygon(MSs{1,i}.pos_x, MSs{1,i}.pos_y, extend_xv{1,j}, extend_yv{1,j}) == 1
          diff_x = MSs{1,i}.pos_x - extend_central_X(1,j);
          diff_y = MSs{1,i}.pos_y - extend_central_Y(1,j);
          MSs{1,i}.pos_x = diff_x;
          MSs{1,i}.pos_y = diff_y;
          break;
        end
      end
    end
  end
end

% plot table
f = figure('Name', 'B-3');
table = uitable(f);
time = time.';
Source_Cell_ID = Source_Cell_ID.';
Destination_Cell_ID = Destination_Cell_ID.';
data = cat(2, time, Source_Cell_ID, Destination_Cell_ID);
table.Data = data;
table.ColumnName = {'Time','Source Cell ID','Destination Cell ID'};

% write in csv file
csvwrite('output.csv', data);
