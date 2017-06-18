% g(d) = d^-n1 * ( 1 + d / b )^-n2

function g = smooth_transition_model( d )
  g = d .^ -2 .* ( 1 + d ./ 150 ) .^ -4
end