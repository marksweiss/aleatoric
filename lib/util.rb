module Aleatoric

# swing(0.98, 5, 0.01) ==> 0.98 - 1.02
def swing(base_val, num_steps, swing_step)
  base_val + (rand(num_steps) * swing_step)
end

def sign
  rand(2) % 2 == 0 ? 1 : -1
end

end