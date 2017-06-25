% N = k * T * B
% k: Boltzman's constant = 1.38 * 10 ^ ( -23 )

function N = thermal_noise_power( T, B )
  N = 1.38 * 10 ^ ( -23 ) * T * B;
end