% SINR = signal / ( interference + noise ) (Watt)

function sinr = SINR( S_dB, I ,N )
  sinr = watt_2_dB( dB_2_watt( S_dB ) ./ ( I + N ) );
end