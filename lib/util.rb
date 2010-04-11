module Aleatoric

# TODO Get rid of this, it's a relic of the bad old days
DFLT_LT_N = 100
# Generates an integer and tests whether it is less than the test_val argument passed in
# @param [Integer] the value to test
# @param [Integer] the upper limit used in the test. test_val must be less than n.
def lt_N?(test_val, n=nil)
  n ||= DFLT_LT_N
  test_val < rand(n) 
end

NO_FACTOR = 1.0
# NOTE: 0.0 >= threshold < 1.0
# TODO Use seeding of srand() to get repeatable psuedo-random sequences for testing
def meets_condition?(threshold)
  rand <= threshold
end

# Have seen both forms on Windows platforms, even though both installed from
#  Win binary installer of 1.8.6.
def include_win?
  RUBY_PLATFORM.include?('mswin') or RUBY_PLATFORM.include?('mingw')
end

def include_mac?
  RUBY_PLATFORM.include?('darwin')  
end

# Returns correct path for Win and Mac/*nix, regardless of what comes in
# Intended as a macro wrapping hard-coded paths in code, e.g. esp. in tests
def psub(path)
  if include_win?
    path.gsub("/", "\\")
  else
    path.gsub("\\", "/")
  end
end

# The only way to debug any statements running in the context of the #load call in aleatoric.rb
# Call this to write log statements to file, which will include all the current context
# of the script execution in composer_lang.rb and composer.rb.
def debug_log(msg)
  if include_win?  
    File.open("..\\test\\test_debug_log.txt", File::WRONLY|File::APPEND|File::CREAT) do |f|
      f << Time.now.to_s + "\t" + msg.to_s + "\n"
    end
  else
    File.open("../test/test_debug_log.txt", File::WRONLY|File::APPEND|File::CREAT) do |f|
      f << Time.now.to_s + "\t" + msg.to_s + "\n"
    end    
  end
end

# Splits a file into an array of lines properly ended with newlines.  Gets around the fact
#  that #IO.readline in Ruby on OSX has a dependency on the Readline library, which itself
#  requires XCode to compile, and (even better) requires a custom compiled version of Ruby
#  compiled with the --readlines flag.  All of which are ridiculous dependencies for this application
def portable_readline(file_name, delim="\n")
  f = File.open(file_name, "r")
  lines = f.read.split(delim)
  f.close
  lines.length.times {|j| lines[j] = lines[j] + delim}
  lines
end
alias portable_readlines portable_readline

#  returns a factor to multiply note.duration and note.start by
#  base_val - the smallest possible swing factor
#  num_steps - the number of values incremented up from the base_val
#  swing_step - the size of each step value increment
# So, example: swing(0.98, 5, 0.01) -> returns one of 5 discrete values [0.98, 0.99, 1.0, 1.01, 1.02]
def swing(base_val, num_steps, swing_step)
  base_val + (rand(num_steps) * swing_step)
end

# Utility function so clients don't have to understand logic of swing()
#  to determine whether a combination of base_val and num_steps can yield a positive swing value
# Of course, clients should understand the function to use it, which means they could/should figure this out
#  but this is cleaner
def swing?(base_val, num_steps)
  base_val != 1.0 and num_steps != 0
end

# Another utility function so clients can abstract away how swing() works
def no_swing
  0.0
end

# Generates and tests an integer for odd/even, returns identity or -identity, so assumes will be used as a factor
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

