% dB = 10 * log10( Watt )

function watt = dB_2_watt( dB )
  watt = 10 .^ ( dB ./ 10 );
end