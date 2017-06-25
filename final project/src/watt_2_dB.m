% dB = 10 * log10( Watt )

function dB = watt_2_dB( watt )
  dB = 10 .* log10( watt );
end