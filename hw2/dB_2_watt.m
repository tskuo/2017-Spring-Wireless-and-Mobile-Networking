% dB = 10 * log10(Watt)

function w = dB_2_watt(dB)
  w = 10 .^ (dB / 10);
end