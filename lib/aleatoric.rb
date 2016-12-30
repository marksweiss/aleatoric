require 'optparse'

require_relative 'composer'

include Aleatoric


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
  end
  optparse.parse!   
  $csound_score_include_file_name = options[:score_include_file_name]
          
  file_name_tmp = options[:score_file_name] + '.tmp'
  # NOTE: If user wants to include an external user_instruction file
  #  they need to add the path to lib/user_instruction.rb (as noted there)
  #  and the need to put the user_instruction file in that path and they need
  #  to name that file [file_name - extension]_user_instruction.rb
  #  e.g. if the composition is "In_C.altc" then the instruction file is "In_C_user_instruction.rb"
  user_instr_file_name = options[:score_file_name]
  if user_instr_file_name.length > 0
    user_instr_file_name = user_instr_file_name.split("/").last
    user_instr_file_name = user_instr_file_name.split(".")[0] + "_user_instruction"
  end
  ext_idx = options[:score_file_name].downcase.rindex(".altc")
  
  $ARG_FORMAT = options[:format]
  if options[:format] == :csound
    set_csound_consts
  elsif options[:format] == :midi
    set_midi_consts
  end
  
  script_lines = portable_readlines(options[:score_file_name])
  script = script_lines.join('')
  # Wrap the script in necessary directives, so user doesn't have to 
  File.open(file_name_tmp, "w") do |f| 
    # VERBOSE
    t = Time.now; puts "Started writing preprocessed score file at #{t}"
 
    header = ""
    if user_instr_file_name.nil?
      header += "require_relative 'user_instruction'\n\n"
    else
      header += "require_relative '" + user_instr_file_name + "'\n\n"
    end
    f << "module Aleatoric\n\n" + header + script + "\n\nend\n"
    
    # VERBOSE
    t_new = Time.now; puts "Writing preprocessed score file took #{(t_new - t) * 1000.0} milliseconds"
  end  
  
  # VERBOSE
  t = Time.now; puts "Started interpreting and rendering score #{t}"   
  
  load file_name_tmp

  # VERBOSE
  t_new = Time.now; puts "Interpreting and rendering score took #{(t_new - t) * 1000.0} milliseconds"
end

main
