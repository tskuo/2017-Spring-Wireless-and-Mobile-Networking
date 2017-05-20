clear;
clc;

%% given parameters
temperature          = 27 + 273.15;  % unit: K
ISD                  = 500;          % unit: m
bandwidth            = 10 * 10 ^ 6;  % unit: Hz
freq_reuse_factor    = 1;            % unit: None
base_station_power   = 33;           % unit: dBm
mobile_device_power  = 0;            % unit: dBm
transmitter_gain     = 14;           % unit: dB
receiver_gain        = 14;           % unit: dB
base_station_height  = 1.5;          % unit: m
building_height      = 50;           % unit: m
mobile_device_height = 1.5;          % unit: m
mobile_device_num    = 50;           % number of devices
base_station_num     = 19;           % number of base stations
simulation_time      = 1000;         % unit: second
BS_buffer            = 6 * 10^6;     % unit: bits

base_station_X = ISD/sqrt(3).*[0, 0, -1.5, -1.5, 0, 1.5, 1.5, 0, -1.5, -3, -3, -3, -1.5, 0, 1.5, 3, 3, 3, 1.5];
base_station_Y = ISD.*[0, 1,  0.5, -0.5, -1, -0.5, 0.5, 2, 1.5, 1, 0, -1, -1.5, -2, -1.5, -1, 0, 1, 1.5];

%% 1-1
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

%% 1-2
d_12 = sqrt(xq.^2 + yq.^2);
B_12 = bandwidth / mobile_device_num;
N_12 = thermal_noise_power(temperature, B_12);
S_12 = dB_2_watt(received_power_dB(base_station_power, ...
                                   building_height + base_station_height, ...
                                   mobile_device_height, ...
                                   d_12, ...
                                   transmitter_gain, ....
                                   receiver_gain));
I_12 = zeros(mobile_device_num,1);

for i = 2:base_station_num
  d_tmp = sqrt((xq - base_station_X(i)).^2 + (yq - base_station_Y(i)).^2);
  I_12 = I_12 + dB_2_watt(received_power_dB(base_station_power, ...
                                   building_height + base_station_height, ...
                                   mobile_device_height, ...
                                   d_tmp, ...
                                   transmitter_gain, ....
                                   receiver_gain));
end

C_12 = B_12 .* log2(1+SINR(S_12, I_12, N_12));

figure('Name', '1-2');
plot(d_12,C_12, 'bx');
xlabel('Distance (m)');
ylabel('Shannon Capacity (bits/s)');
title('Figure 1-2');

%% 1-3

CBR_type_13  = 3;
CBR_13    = 10^6 .* [0.1, 0.5, 1]; % Xlow, Xmedium, Xhigh
buffer_13 = BS_buffer / mobile_device_num;

lossbits_13  = zeros(CBR_type_13,1);
totalbits_13 = zeros(CBR_type_13,1);

for i = 1:CBR_type_13
  in_buffer_13 = zeros(mobile_device_num, 1);
  for t = 1:simulation_time
    for k = 1:mobile_device_num
      totalbits_13(i) = totalbits_13(i) + CBR_13(i);
      if (CBR_13(i) + in_buffer_13(k)) <= C_12(k) % no loss bit
        in_buffer_13(k) = 0; % clear buffer
      elseif CBR_13(i) >= C_12(k)
        if in_buffer_13(k) < buffer_13 % buffer not full yet
          overflow = CBR_13(i) - C_12(k);
          if in_buffer_13(k) + overflow <= buffer_13 % buffer will not be full even adding overflow
            in_buffer_13(k) = in_buffer_13(k) + overflow;
          else % buffer will be full after adding overflow
            lossbits_13(i) = lossbits_13(i) + in_buffer_13(k) + overflow - buffer_13;
            in_buffer_13(k) = buffer_13;
          end
        else % buffer is already full
          lossbits_13(i) = lossbits_13(i) + (CBR_13(i) - C_12(k));
        end
      else % (CBR_13(i) + in_buffer_13(k)) > C_12(k)) && (CBR_13(i) < C_12(k))
        in_buffer_13(k) = in_buffer_13(k) - (C_12(k) - CBR_13(i)); % relief buffer
      end
    end
  end
end

loss_prob = lossbits_13 ./ totalbits_13;
figure_3 = figure('Name', '1-3');
bar(loss_prob);
set(gca,'XTickLabel',{'low','medium','high'})
for i = 1:3
    text(i, loss_prob(i)+0.05, num2str(loss_prob(i)));
end
xlabel('Traffic Load');
ylabel('Bits Loss Probability');
title('Figure 1-3: Constant Bits Rate');
axis([0.5,3.5,0,1]);

%% B-1
[xv_b, yv_b] = gen_hexagon(0,0,ISD/sqrt(3));
[xq_b, yq_b] = gen_hexrand(0, 0, xv_b, yv_b, ISD/sqrt(3), mobile_device_num);
figure('Name', 'B-1');
plot(xv_b, yv_b, '-k', 'linewidth', 2);
xlabel('x-direction (meter)');
ylabel('y-direction (meter)');
title('Figure 1-1');
hold on;
plot(xq_b, yq_b, 'bx');
hold on;
plot(0, 0, 'r*');
hold off;

%% B-2
d_b2 = sqrt(xq_b.^2 + yq_b.^2);
B_b2 = bandwidth / mobile_device_num;
N_b2 = thermal_noise_power(temperature, B_b2);
S_b2 = dB_2_watt(received_power_dB(base_station_power, ...
                                   building_height + base_station_height, ...
                                   mobile_device_height, ...
                                   d_b2, ...
                                   transmitter_gain, ....
                                   receiver_gain));
I_b2 = zeros(mobile_device_num,1);

for i = 2:base_station_num
  d_tmp = sqrt((xq_b - base_station_X(i)).^2 + (yq_b - base_station_Y(i)).^2);
  I_b2 = I_b2 + dB_2_watt(received_power_dB(base_station_power, ...
                                   building_height + base_station_height, ...
                                   mobile_device_height, ...
                                   d_tmp, ...
                                   transmitter_gain, ....
                                   receiver_gain));
end

C_b2 = B_b2 .* log2(1+SINR(S_b2, I_b2, N_b2));

figure('Name', 'B-2');
plot(d_b2,C_b2, 'bx');
xlabel('Distance (m)');
ylabel('Shannon Capacity (bits/s)');
title('Figure B-2');

%% B-3

type_b3      = 3;
lambda_b3    = 10^6 .* [0.1, 0.5, 1]; % Xlow, Xmedium, Xhigh
buffer_b3 = BS_buffer / mobile_device_num;

lossbits_b3  = zeros(type_b3,1);
totalbits_b3 = zeros(type_b3,1);

for i = 1:type_b3
  in_buffer_b3 = zeros(mobile_device_num, 1);
  for t = 1:simulation_time
    for k = 1:mobile_device_num
      transmitbits = poissrnd(lambda_b3(i));
      totalbits_b3(i) = totalbits_b3(i) + transmitbits;
      if (transmitbits + in_buffer_b3(k)) <= C_b2(k) % no loss bit
        in_buffer_b3(k) = 0; % clear buffer
      elseif transmitbits >= C_b2(k)
        if in_buffer_b3(k) < buffer_b3 % buffer not full yet
          overflow = transmitbits - C_b2(k);
          if in_buffer_b3(k) + overflow <= buffer_b3 % buffer will not be full even adding overflow
            in_buffer_b3(k) = in_buffer_b3(k) + overflow;
          else % buffer will be full after adding overflow
            lossbits_b3(i) = lossbits_b3(i) + in_buffer_b3(k) + overflow - buffer_b3;
            in_buffer_b3(k) = buffer_b3;
          end
        else % buffer is already full
          lossbits_b3(i) = lossbits_b3(i) + (transmitbits - C_b2(k));
        end
      else 
        in_buffer_b3(k) = in_buffer_b3(k) - (C_b2(k) - transmitbits); % relief buffer
      end
    end
  end
end

loss_prob_b3 = lossbits_b3 ./ totalbits_b3;
figure_b3 = figure('Name', 'B-3');
bar(loss_prob);
set(gca,'XTickLabel',{'low','medium','high'})
for i = 1:3
    text(i, loss_prob_b3(i)+0.05, num2str(loss_prob_b3(i)));
end
xlabel('Traffic Load');
ylabel('Bits Loss Probability');
title('Figure B-3: Poisson Traffic Arrival');
axis([0.5,3.5,0,1]);