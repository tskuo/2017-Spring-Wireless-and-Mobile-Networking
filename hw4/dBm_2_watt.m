% dBm = 10 * log10( Watts / 10^-3 )

function d = dBm_2_watt(dBm)
  d = 10 .^ (dBm / 10) * 10^(-3);
end