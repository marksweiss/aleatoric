require 'composer'
require 'composer_lang'
# require 'instrument'
include Aleatoric

def main
  # Get the name of the Composer score to render into a sound file
  file_name = ARGV[0]
  # Read file into memory, before changing name for write output and subsequent work
  # Line input because we write by line below in File.open() block
  script = File.readlines(file_name)
  # Append to the file name, this is the file processed by this job, opaque to user, not
  #  the script file they work with.  In default case we add all the do/end syntax, for example,
  #  and hide that from them.  And in all cases we add the module directive.
  file_name = file_name + '.tmp'
    
  # Now preprocess to add 'do/end' syntax, add 'do |index|/end' to repeat blocks
  #  and validate syntax and grammar (structure)
  preprocess_flag = true
  preprocess_flag = eval(ARGV[1]) if ARGV.length > 1
  if preprocess_flag
    script = ComposerAST.new(script).preprocess_script(file_name).to_s
    open(file_name , 'w') {|f| f << script}
  end
  
  # Wrap the script in ruby module directive, this is just so user doesn't have to 
  #  pollute their script with this
  File.open(file_name, "w") do |f|
    f << "module Aleatoric\nrequire 'util'\nrequire 'global'\n\n"  
    script.each do |line|
      f << line
    end    
    f << "\n\nend\n"
  end   
  
  # Run the script in Ruby, as a Ruby script, in the context of the 'Aleatoric' namespace included above
  load file_name
end

main
