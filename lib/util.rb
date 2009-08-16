module Aleatoric

DFLT_LT_N = 100
# Generates an integer and tests whether it is less than the test_val argument passed in
# @param [Integer] the value to test
# @param [Integer] the upper limit used in the test. test_val must be less than n.
def lt_N?(test_val, n=nil)
  n ||= DFLT_LT_N
  test_val < rand(n) 
end

# The only way to debug any statements running in the context of the #load call in aleatoric.rb
# Call this to write log statements to file, which will include all the current context
# of the script execution in composer_lang.rb and composer.rb.
def debug_log(msg)
  File.open("..\\test\\test_debug_log.txt", File::WRONLY|File::APPEND|File::CREAT) do |f|
    f << Time.now.to_s + "\t" + msg.to_s + "\n"
  end
end

# Offsets a value within a range
# swing(0.98, 5, 0.01) ==> 0.98 - 1.02
def swing(base_val, num_steps, swing_step)
  base_val + (rand(num_steps) * swing_step)
end

# Generates and tests an integer for odd/even
def sign
  rand(2) % 2 == 0 ? 1 : -1
end

class Array
  # Adds a #sum method to Kernel class Array
  def sum
    inject(0) {|sum, x| sum + x}
  end  
end

end