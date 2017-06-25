% g(d) = ( h_t * h_r ) ^ 2 / d ^ 4

function g = two_ray_ground_model( h_t, h_r, d )
  g = ( h_t * h_r ) ^ 2 ./ d .^ 4;
end