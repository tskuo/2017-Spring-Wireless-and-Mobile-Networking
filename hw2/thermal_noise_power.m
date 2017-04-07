% Thermal noise power : N = k * T * B
%                       k : Boltzman¡¦s constant= 1.38*10^-23 
%                       T : temperature (degree Kelvin)
%                       B : bandwidth of channel (Hz)

function n = thermal_noise_power(temperature, bandwidth)
  n = 1.38 * 10^(-23) * temperature * bandwidth; 
end