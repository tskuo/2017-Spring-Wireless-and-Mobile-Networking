% Two-ray-ground model: g(d) = (ht hr)^2/d^4

function g = two_ray_ground_model(h_transmitter, h_receiver, distance)
  g = (h_transmitter * h_receiver)^2 ./ (distance .^ 4);
end