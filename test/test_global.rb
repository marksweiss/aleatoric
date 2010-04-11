# global utils because want to use psub() to wrap include calls that in turn
#  import /lib path to get to utils.rb.  So if we put this in utils.rb we
#  couldn't use it to import utils.rb.  Doh.
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
