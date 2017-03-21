% Problem description

% A base station and a mobile device locate in an urban area with temperature 27¢XC.
% Here, we consider a downlink case. The channel bandwidth is 10MHz. The power of 
% the base station is 33dBm. The transmitter gain and the receiver gain are both 14 dB.
% The height of the base station is 1.5m, which is located on the top of a 50m high building.
% The position of the mobile device is 1.5m high from the ground.

clear;
clc;

% given parameters
temperature          = 27 + 273.15;  % unit: K
bandwidth            = 10 * 10 ^ 6;  % unit: Hz
base_station_power   = 33;           % unit: dBm
transmitter_gain     = 14;           % unit: dB
receiver_gain        = 14;           % unit: dB
base_station_height  = 1.5;          % unit: m
building_height      = 50;           % unit: m
mobile_device_height = 1.5;          % unit: m

% setting parameters
distance_max         = 1000;         % unit: m

% 1. Consider the path loss only radio propagation (without shadowing and fading).
%    Use Two-ray-ground model as the propagation model for your simulation.
%    HINT: Please refer to slide 48 of Lec 2 for two-ray-ground model.

% Two-ray-ground model: g(d) = (ht hr)^2/d^4 (Path Loss)
% Thermal noise power : N = k * T * B
%                       k : Boltzman¡¦s constant= 1.38*10^-23 
%                       T : temperature (degree Kelvin)
%                       B : bandwidth of channel (Hz)

% 1-1. Please plot a figure with the received power of the mobile device (in dB) as the
% y-axis and the distance (in meter) between the BS and the mobile device as the x-axis.

x_11 = 0:1:distance_max;
y_11 = watt_2_dB(dBm_2_watt(base_station_power)) ...
       + watt_2_dB(two_ray_ground_model(building_height + base_station_height, mobile_device_height, x_11)) ...
       + transmitter_gain + receiver_gain;
   
figure('Name', '1-1');
plot(x_11,y_11,'linewidth',2);
xlabel('Distance (m)');
ylabel('Received Power (dB)');
title('Figure 1-1');

% 1-2. According to 1-1, please plot a figure with SINR of the mobile device (in dB) as
% the y-axis and the distance between the BS and the mobile device (in meter) as the x-axis.

x_12 = 0:1:distance_max;
noise_12 = thermal_noise_power(temperature, bandwidth);
interference_12 = 0;
y_12 = watt_2_dB(SINR(dB_2_watt(y_11), interference_12, noise_12));

figure('Name', '1-2');
plot(x_12,y_12,'linewidth',2);
xlabel('Distance (m)');
ylabel('SINR (dB)');
title('Figure 1-2');

% 2. Consider both the path loss and shadowing (without fading). Apply log-normal shadowing
%    to model the shadowing effect. The path loss model should be the same as 1-1.
%    HINT: Please refer to slide 52 and slide 53 of Lec 2 for log-normal distribution.
%    Please set £m = 6dB in the simulation.

% 2-1. Please plot a figure with the received power of the mobile device (in dB) as the y-axis
% and the distance (in meter) between the BS and the mobile device as the x-axis.
% log-normal shadowing

sigma = 6; % unit: dB
mean = 0;
shadowing = normrnd(mean, sigma, 1, distance_max+1); % unit: dB
      % R = normrnd(mu,sigma,m,n,...) generates an m-by-n-by-... array
x_21 = 0:1:distance_max;
y_21 = y_11 + shadowing;

figure('Name', '2-1');
plot(x_21,y_21,'linewidth',2);
xlabel('Distance (m)');
ylabel('Received Power (dB)');
title('Figure 2-1');

% 2-2. According to 2-1, please plot a figure with SINR of the mobile device (in dB) as the y-axis
% and the distance between the BS and the mobile device (in meter) as the x-axis.

x_22 = 0:1:distance_max;
noise_22 = thermal_noise_power(temperature, bandwidth);
interference_22 = 0;
y_22 = watt_2_dB(SINR(dB_2_watt(y_21), interference_22, noise_22));

figure('Name', '2-2');
plot(x_22,y_22,'linewidth',2);
xlabel('Distance (m)');
ylabel('SINR (dB)');
title('Figure 2-2');