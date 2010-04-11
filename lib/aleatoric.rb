require 'composer'
require 'composer_lang'

require 'rubygems'
require 'optparse'
# require 'ruby-debug' ; Debugger.start

include Aleatoric

# SAMPLE DEBUGGER CALLS
#  Debugger.tracing = true
#  breakpoint if true == false
#  Debugger.tracing = false

# TODO Real cmd line args handling.  This is lame
def main
  options = {}
  optparse = OptionParser.new do |opts|
    options[:score_file_name] = ''
    opts.on('-s', '--score_name SCORE_FILE', "Score file name") do |s|
      options[:score_file_name] = s
    end
    options[:score_include_file_name] = ''
    opts.on('-i', '--score_include_name SCORE_INCLUDE_FILE', "CSound score include file name") do |i|
      options[:score_include_file_name] = i
    end  
    options[:format] = :csound
    opts.on('-f', '--format FORMAT_ARG', "Output format") do |f|
      options[:format] = f.to_sym
    end
    options[:preprocess_flag] = true     
    opts.on('-n', '--no_preprocessing', "Flag to support syntax without ruby block keywords (do/end). On by default.") do
      options[:preprocess_flag] = false
    end     
  end
  optparse.parse!   
  $csound_score_include_file_name = options[:score_include_file_name]
          
  # Append to the file name, this is the file processed by this job, opaque to user, not
  #  the script file they work with.  In default case we add all the do/end syntax, for example,
  #  and hide that from them.  And in all cases we add the module directive.
  file_name_tmp = options[:score_file_name] + '.tmp'
  
  # Get the name minus the last section of '.altc' which is the extension, if any
  # We can have a name like this though, My.Tune.altc -> My.Tune
  # NOTE: If user wants to include an external user_instruction file
  #  they need to add the path to lib/user_instruction.rb (as noted there)
  #  and the need to put the user_instruction file in that path and they need
  #  to name that file [file_name - extension]_user_instruction_rb
  # NOTE: ONLY SUPPORTS *.altc EXTENSION
  #  e.g. if the composition is "In_C.altc" then the 
  #  instruction file is "In_C_user_instruction.rb"
  user_instr_file_name = options[:score_file_name]
  ext_idx = options[:score_file_name].downcase.rindex(".altc")
  user_instr_file_name = options[:score_file_name][0..(ext_idx-1)] unless ext_idx.nil?
  user_instr_file_name += "_user_instruction.rb"
  
  # Set global format and make call to load consts for that format
  # TODO Make default format configurable
  $ARG_FORMAT = options[:format]
  if options[:format] == :csound
    set_csound_consts
  elsif options[:format] == :midi
    set_midi_consts
  end
  
  # TODO Verbose flag
  # LOGGING
  puts "Format set to #{$ARG_FORMAT}"
  
  script_lines = portable_readlines(options[:score_file_name])
    
  # Composer reuses some Ruby keywords which need to be modified so they don't get interpreted as Ruby
  # This is non-optional preprocessing
  # Returns the script lines preprocessed
  script_lines = ComposerAST.new.mandatory_preprocess_script(script_lines)
  
  # Now preprocess to add 'do/end' syntax, add 'do |index|/end' to repeat blocks
  #  and validate syntax and grammar (structure)
  if options[:preprocess_flag]      
    # LOGGING
    t = Time.now
    puts "Preprocessing started at #{t}"
    
    # Returns the script lines preprocessed, and joined into one big string, i.e. - the whole script preprocessed
    script = ComposerAST.new.optional_preprocess_script(script_lines, options[:score_file_name])

    # LOGGING
    t_new = Time.now
    puts "Preprocessing took #{(t_new - t) * 1000.0} milliseconds"
  else
    script = script_lines.join('')
  end
  
  # Wrap the script in necessary directives, so user doesn't have to 
  File.open(file_name_tmp, "w") do |f| 
    # LOGGING
    t = Time.now
    puts "Started writing preprocessed score file at #{t}"
      
    header = "require 'util'\nrequire 'global'\n"
    if user_instr_file_name.nil?
      header += "require 'user_instruction'\n"
    else
      header += "require '" + user_instr_file_name + "'\n"
  	end
  	header += "module Aleatoric\n\n"  
    f << header + script + "\n\nend\n"
    
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
