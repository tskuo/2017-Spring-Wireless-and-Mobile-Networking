% Signal-to-Interference-Plus-Noise ratio (SINR)
% SINR = (signal power) / (interference power + noise power)

function sinr = SINR(S, I, N)
  sinr = S / (I + N);
end