
% Problem description

% 19 base stations are located in an urban area with temperature 27¢XC,
% which form a 19-cell map shown in Fig. 1. The coordination of the 
% central BS is (0, 0) and ISD (inter site distance) is 500 m.
% The channel bandwidth is 10MHz. All BSs use the same carrier frequency
% (frequency reuse factor =1).The power of each base station is 33dBm.
% The power of each mobile device is 23dBm. The transmitter antenna gain 
% and the receiver antenna gain for each device, including base station 
% and mobile devices, are 14 dB. The height of each base station is 1.5m,
% which is located on the top of a 50m high building. The position of each
% mobile device is 1.5m high from the ground.

clear;
clc;

% given parameters
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

base_station_X = ISD/sqrt(3).*[0, 0, -1.5, -1.5, 0, 1.5, 1.5, 0, -1.5, -3, -3, -3, -1.5, 0, 1.5, 3, 3, 3, 1.5];
base_station_Y = ISD.*[0, 1,  0.5, -0.5, -1, -0.5, 0.5, 2, 1.5, 1, 0, -1, -1.5, -2, -1.5, -1, 0, 1, 1.5];
% Consider the path loss only radio propagation (without shadowing and fading).
% Use Two-ray-ground model as the propagation model for simulation.

% 1. [Downlink]
% Assume there are 50 mobile devices uniformly random distributed in the central
% cell. All the BSs are transmitting at the same time. The downlink interference
% for a specific mobile device comes from other BSs. Do not consider ISI
% (inter-symbol interference) in the case.

% 1.1
% Please plot the location of the central BS and 50 uniformly random distributed
% mobile devices in the central cell. Don¡¦t plot the location of other BSs and 
% other mobile devices in other cells. The unit of x-axis and y-axis should be
% ¡§meter¡¨. The central BS is located at (0, 0). Also, use mark or color to 
% differentiate the central BS from mobile devices.

mobile_device_num = 50;

[xv, yv] = gen_hexagon(0,0,ISD/sqrt(3));
[xq, yq] = gen_hexrand(0, 0, xv, yv, ISD/sqrt(3), mobile_device_num);
figure('Name', '1-1');
plot(xv, yv, '-k', 'linewidth', 2);
xlabel('x-direction (meter)');
ylabel('y-direction (meter)');
title('Figure 1-1');
hold on;
plot(xq, yq, 'bx');
hold on;
plot(0, 0, 'r*');
hold off;

% 1.2
% Based on the map in 1-1, please plot a figure with the received power
% (in dB) of a mobile device in a central BS as y-axis, and with the distance
% between the corresponding mobile device and the central BS as x-axis.
% Also, write down how to calculate the received power of a mobile device.
d_12   = sqrt(xq.^2 + yq.^2);
y_12   = received_power_dB(base_station_power, building_height + base_station_height, ...
                           mobile_device_height, d_12, transmitter_gain, receiver_gain);
figure('Name', '1-2');
plot(d_12,y_12, 'bx');
xlabel('Distance (m)');
ylabel('Received Power (dB)');
title('Figure 1-2');

% 1.3
% According to 1-2, please plot a figure with the SINR (in dB) of a mobile
% device in the central cell as y-axis, and with the distance between the
% corresponding mobile device and the central BS as x-axis. Also, write down
% how to calculate the SINR in your report.

% HINT: Both thermal noise and received power of a mobile device from other
% BSs should be taken into consideration.

thermal_noise_power_13 = thermal_noise_power(temperature, bandwidth);
y_13 = zeros(mobile_device_num,1);
for i = 1:mobile_device_num
  interference_13 = 0;
  for j = 2:19
    distance_13 = sqrt((xq(i,1)-base_station_X(1,j))^2 + (yq(i,1)-base_station_Y(1,j))^2);
    interference_13 = interference_13 ...
                    + dB_2_watt(received_power_dB(base_station_power, building_height + base_station_height, ...
                      mobile_device_height, distance_13, transmitter_gain, receiver_gain));
  end
  y_13(i,1) = watt_2_dB(dB_2_watt(y_12(i,1))/(interference_13+thermal_noise_power_13));
end

figure('Name', '1-3');
plot(d_12,y_13, 'bx');
xlabel('Distance (m)');
ylabel('SINR (dB)');
title('Figure 1-3');

% 2. [Uplink]
% Consider only the central cell in this problem. Assume 50 uniformly random
% distributed mobile devices uplink to the central BS at the same time.
% The uplink interference for a specific mobile device happens at the BS side
% due to the concurrent uplink transmission of other mobile devices.

% 2.1
% Please plot the location of the central BS and 50 uniformly random distributed
% mobile devices in the central cell. Don¡¦t plot the location of other BSs and
% other mobile devices in other cells. The unit of x-axis and y-axis should be
% ¡§meter¡¨. The central BS is located at (0, 0). Also, use mark or color to
% differentiate the central BS from mobile devices.

[xv_2, yv_2] = gen_hexagon(0,0,ISD/sqrt(3));
[xq_2, yq_2] = gen_hexrand(0, 0, xv_2, yv_2, ISD/sqrt(3), mobile_device_num);
figure('Name', '2-1');
plot(xv_2, yv_2, '-k', 'linewidth', 2);
xlabel('x-direction (meter)');
ylabel('y-direction (meter)');
title('Figure 2-1');
hold on;
plot(xq_2, yq_2, 'bx');
hold on;
plot(0, 0, 'r*');
hold off;

% 2.2
% Based on the map in 2-1, please plot a figure with the received power (in dB)
% of the central BS from a specific mobile device as y-axis, and with the distance
% between the corresponding mobile device and the central BS as x-axis. Also,
% write down how to calculate the received power of the central BS from a 
% specific mobile device.

% HINT: There should be 50 points in the figure.

d_22   = sqrt(xq_2.^2 + yq_2.^2);
y_22   = received_power_dB(base_station_power, building_height + base_station_height, ...
                           mobile_device_height, d_22, transmitter_gain, receiver_gain);
figure('Name', '2-2');
plot(d_22,y_22, 'bx');
xlabel('Distance (m)');
ylabel('Received Power (dB)');
title('Figure 2-2');

% 2.3
% According to 2-1, please plot a figure with SINR of the central BS (in dB)
% as the y-axis and the distance between the BS and the corresponding mobile
% device (in meter) as the x-axis. Also, write down how to calculate the SINR
% in your report.

% HINT: Both thermal noise and received power of the central BS from other
% mobile devices within the same cell should be taken into consideration.
% We don¡¦t consider the uplink interference from mobile devices in other cells.
% No need to calculate inter-symbol interference (ISI).

thermal_noise_power_23 = thermal_noise_power(temperature, bandwidth);
y_23 = zeros(mobile_device_num,1);
for i = 1:mobile_device_num
  interference_23 = 0;
  for j = 1:mobile_device_num
    if i == j
      continue;
    end
    distance_23 = sqrt((xq_2(j,1))^2 + (yq_2(j,1))^2);
    interference_23 = interference_23 ...
                    + dB_2_watt(received_power_dB(base_station_power, building_height + base_station_height, ...
                      mobile_device_height, distance_23, transmitter_gain, receiver_gain));
  end
  y_23(i,1) = watt_2_dB(dB_2_watt(y_22(i,1))/(interference_23+thermal_noise_power_23));
end

figure('Name', '2-3');
plot(d_22,y_23, 'bx');
xlabel('Distance (m)');
ylabel('SINR (dB)');
title('Figure 2-3');

% Bonus [Uplink]
% Consider 19 cells shown in Fig. 1 in this problem. There are 50 uniformly
% random distributed mobile devices in each cell. Assume all the uniformly
% distributed mobile devices uplink to their corresponding BSs at the same time.
% The uplink interference for a specific mobile device happens at the BS side
% due to the concurrent uplink transmission of other mobile devices.

% B-1 Please plot the location of the 19 BSs and 50 uniformly random distributed
% mobile devices in each cell. The unit of x-axis and y-axis should be ¡§meter¡¨.
% The central BS is located at (0, 0). Also, use mark or color to differentiate
% BSs from mobile devices.

% HINT: There should be 19 BSs and 50x19 mobile devices in this figure.
mobile_device_num = 50;
xv_b = {};
yv_b = {};
xq_b = {};
yq_b = {};
for i = 1:19
  [xv_tmp, yv_tmp] = gen_hexagon(base_station_X(1,i), base_station_Y(1,i), ISD/sqrt(3));
  [xq_tmp, yq_tmp] = gen_hexrand(base_station_X(1,i), base_station_Y(1,i), xv_tmp, yv_tmp, ISD/sqrt(3), mobile_device_num);
  xv_b =cat(1, xv_b, xv_tmp);
  yv_b =cat(1, yv_b, yv_tmp);
  xq_b =cat(1, xq_b, xq_tmp);
  yq_b =cat(1, yq_b, yq_tmp);
end

figure('Name', 'B-1');
xlabel('x-direction (meter)');
ylabel('y-direction (meter)');
title('Figure B-1');
for i = 1:19
  plot(xv_b{i,:,:}, yv_b{i,:,:}, '-k', 'linewidth', 2);
  hold on;
  plot(xq_b{i,:,:}, yq_b{i,:,:}, 'bx');
  hold on;
  plot(base_station_X(1,i), base_station_Y(1,i), 'r*');
  hold on;
end
hold off;

% B-2
% Based on the map in B-1, please plot a figure with the received power (in dB)
% of each BS from a specific mobile device as y-axis, and with the distance
% between the corresponding mobile device and the BS (in meter) as x-axis.
% Also, write down how to calculate the received power of a BS from a specific
% mobile device.

% HINT: There should be 50x19 points in the figure.

d_b2 = [];
for i = 1:19
  d_b2 = cat(1, d_b2, sqrt((xq_b{i,1}-base_station_X(1,i)).^2 + (yq_b{i,1}-base_station_Y(1,i)).^2));
end
y_b2   = received_power_dB(base_station_power, building_height + base_station_height, ...
                           mobile_device_height, d_b2, transmitter_gain, receiver_gain);
figure('Name', 'B-2');
plot(d_b2,y_b2, 'bx');
xlabel('Distance (m)');
ylabel('Received Power (dB)');
title('Figure B-2');

% B-3
% According to B-1, please plot a figure with SINR of each BS (in dB) from
% a specific mobile device as the y-axis and the distance between the BS 
% and the corresponding mobile device (in meter) as the x-axis. Also, write
% down how to calculate the SINR in your report.

% HINT: Both thermal noise and received power of each BS from other mobile
% devices (instead of the specific mobile device) within/outside the cell
% should be considered. Different from question 2-3, we should consider the
% uplink interference due to concurrent transmission of other mobile devices
% in other cells. No need to calculate inter-symbol interference (ISI).

figure('Name', 'B-3');
xlabel('Distance (m)');
ylabel('SINR (dB)');
title('Figure B-3');
hold on;
thermal_noise_power_b3 = thermal_noise_power(temperature, bandwidth);
cmap = hsv(19);
% cmap = rand(19,3); % for darker color dots
for i = 1:19
  y_b3 = zeros(mobile_device_num,1);
  d_b3 = zeros(mobile_device_num,1);
  for j = 1:mobile_device_num
    interference_b3 = 0;
    for k = 1:19
      for p = 1:mobile_device_num
        if i == k && j == p
          continue;
        end
        distance_b3 = sqrt((base_station_X(1,i) - xq_b{k,1}(p,1))^2 ...
                          +(base_station_Y(1,i) - yq_b{k,1}(p,1))^2);
        interference_b3 = interference_b3 ...
                        + dB_2_watt(received_power_dB(base_station_power, building_height + base_station_height, ...
                          mobile_device_height, distance_b3, transmitter_gain, receiver_gain));
      end
    end
    y_b3(j,1) = watt_2_dB(dB_2_watt(y_b2(50*(i-1)+j,1))/(interference_b3+thermal_noise_power_b3));
    d_b3(j,1) = sqrt((base_station_X(1,i) - xq_b{i,1}(j,1))^2 + (base_station_Y(1,i) - yq_b{i,1}(j,1))^2);
  end
  plot(d_b3,y_b3, 'x', 'Color',cmap(i,:));
  hold on;
end
hold off;

