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
  
  # Set global format and make call to load consts for that format
  # TODO Make default format configurable
  $ARG_FORMAT = :csound  
  fmt_arg = '' 
  fmt_arg = ARGV[1] if ARGV.length > 1
  fmt_arg = fmt_arg.strip.downcase
  $ARG_FORMAT = fmt_arg.to_sym if (fmt_arg == 'csound' || fmt_arg == 'midi') 

  if $ARG_FORMAT == :csound
    set_csound_consts
  elsif $ARG_FORMAT == :midi
    set_midi_consts
  end
  
  # TODO Verbose flag
  # LOGGING
  puts "Format set to #{$ARG_FORMAT}"
  
  script_lines = File.readlines src_file_name
  # Composer reuses some Ruby keywords which need to be modified so they don't get interpreted as Ruby
  # This is non-optional preprocessing
  # Returns the script lines preprocessed
  script_lines = ComposerAST.new.mandatory_preprocess_script(script_lines)
  
  # Now preprocess to add 'do/end' syntax, add 'do |index|/end' to repeat blocks
  #  and validate syntax and grammar (structure)
  preprocess_flag = true
  preprocess_flag = eval(ARGV[2]) if ARGV.length > 2
  if preprocess_flag      
    # LOGGING
    t = Time.now
    puts "Preprocessing started at #{t}"
    
    # Returns the script lines preprocessed, and joined into one big string, i.e. - the whole script preprocessed
    script = ComposerAST.new.optional_preprocess_script(script_lines)

    # LOGGING
    t_new = Time.now
    puts "Preprocessing took #{(t_new - t) * 1000.0} milliseconds"
  else
    script = File.readlines file_name
  end
  
  # Wrap the script in necessary directives, so user doesn't have to 
  File.open(file_name_tmp, "w") do |f| 
    # LOGGING
    t = Time.now
    puts "Started writing preprocessed score file at #{t}"
  
    f << "require 'util'\nrequire 'global'\nrequire 'user_instruction'\nmodule Aleatoric\n\n"  
    script.each do |line|
      f << line
    end    
    f << "\n\nend\n"
    
    # LOGGING
    t_new = Time.now
    puts "Writing preprocessed score file took #{(t_new - t) * 1000.0} milliseconds"    
  end  
  
  # *********************************
  # Run the script in Ruby, as a Ruby script, 
  #  in the context of the 'Aleatoric' namespace included above
  #  with all the constants loaded above
  
  # LOGGING
  t = Time.now
  puts "Started interpreting and rendering score #{t}"   
  
  load file_name_tmp

  # LOGGING
  t_new = Time.now
  puts "Interpreting and rendering score took #{(t_new - t) * 1000.0} milliseconds"     
end

main
