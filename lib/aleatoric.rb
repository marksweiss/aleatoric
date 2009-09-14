require 'composer'
require 'composer_lang'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

include Aleatoric

# SAMPLE DEBUGGER CALLS
#  Debugger.tracing = true
#  breakpoint if true == false
#  Debugger.tracing = false

# TODO Real cmd line args handling.  This is lame
def main
  script = ""
  
  # Get the name of the Composer score to render into a sound file
  file_name = ARGV[0]
    
  # Append to the file name, this is the file processed by this job, opaque to user, not
  #  the script file they work with.  In default case we add all the do/end syntax, for example,
  #  and hide that from them.  And in all cases we add the module directive.
  file_name_tmp = file_name + '.tmp'
  
  $ARG_FORMAT = :midi #:csound
  $ARG_FORMAT = ARGV[1].to_sym if (ARGV.length > 1 && ARGV[1] == ('csound' || 'midi')) 
    
  # Now preprocess to add 'do/end' syntax, add 'do |index|/end' to repeat blocks
  #  and validate syntax and grammar (structure)
  preprocess_flag = true
  preprocess_flag = eval(ARGV[2]) if ARGV.length > 2
  if preprocess_flag  
    script = ComposerAST.new.preprocess_script(file_name).to_s
  else
    script = File.readlines file_name
  end
  
  # Wrap the script in necessary directives, so user doesn't have to 
  File.open(file_name_tmp, "w") do |f|
    f << "require 'util'\nrequire 'global'\nrequire 'user_instruction'\nmodule Aleatoric\n\n"  
    script.each do |line|
      f << line
    end    
    f << "\n\nend\n"
  end  
  
  # Run the script in Ruby, as a Ruby script, in the context of the 'Aleatoric' namespace included above
  load file_name_tmp
end

main
