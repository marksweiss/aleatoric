module Aleatoric

def debug_log(msg)
  File.open("..\\test\\test_debug_log.txt", File::WRONLY|File::APPEND|File::CREAT) do |f|
    f << Time.now.to_s + "\t" + msg.to_s + "\n"
  end
end

# swing(0.98, 5, 0.01) ==> 0.98 - 1.02
def swing(base_val, num_steps, swing_step)
  base_val + (rand(num_steps) * swing_step)
end

def sign
  rand(2) % 2 == 0 ? 1 : -1
end

class Array
  def sum
    inject(0) {|sum, x| sum + x}
  end  
end

end