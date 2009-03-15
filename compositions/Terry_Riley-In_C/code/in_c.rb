require 'ensemble'
require 'in_c_notes'
require 'yaml'
include In_C

def load_config
    conf = YAML.load_file("ensemble.yml")
    num_players = conf["ensemble"]["num_players"]
 
    conf = YAML.load_file("csound.yml")   
    num_note_functions = conf["csound"]["num_note_functions"]
    score_file_name = conf["csound"]["score_file_name"]
    score_include_file_name = %{"#{conf["csound"]["score_include_file_name"]}"}   # '"oscil_sine_ftables.txt"'
    orc_file_name = conf["csound"]["orc_file_name"]
    partition_output_by_player = conf["csound"]["partition_output_by_player"]
    out_file_name = conf["csound"]["out_file_name"]
    
    return num_players,\
           num_note_functions, score_file_name, score_include_file_name, orc_file_name,\
           partition_output_by_player, out_file_name
end

def load_phrases_and_init_players(num_players, num_note_functions, score)  
  # For each player we are creating, get a *copy* of all the note phrases 
  #  (each phrase is itself a Score object) and load them into a new Player
  # Each Player gets the same output Score; the result is the composition  
  players = []; j = 0
  num_players.times do 
    # A deep copy of the phrases
    phrases = In_C::phrases_dup
    # A easy cheesy way to distribute players over different note functions --
    # Note functions assign different weights to harmonic partials and so
    #  have different timbres with the CSound Gen code being used
    phrases.each {|phrase| phrase.each {|note| note.func((j % num_note_functions) + 1)}}
    players.push(In_C::Player.new(phrases, score))
    # Increment to set to the next note function for the next player
    j += 1
  end
  
  players
end

def render_output(partition_output_by_player, num_players, score_file_name, orc_file_name, out_file_name)
  # Now render the file in CSound
  if partition_output_by_player then
    # TODO Eventually a real generic runner for rendering
    out_file_base, out_file_ext = out_file_name.split(".")
    sco_file_base, sco_file_ext = score_file_name.split(".")
    num_players.times do |j| 
      system("consound -m0 -d -s -W -o#{out_file_base}#{j+1}.#{out_file_ext} #{orc_file_name} #{sco_file_base}#{j+1}.#{sco_file_ext}")
    end
  else
      # TEMP DEBUG
      # puts "consound -m0 -d -s -W -o#{out_file_name} #{orc_file_name} #{score_file_name}"
  
      system("consound -m0 -d -s -W -o#{out_file_name} #{orc_file_name} #{score_file_name}")
  end
end

def main
  num_players, num_note_functions, score_file_name, score_include_file_name, orc_file_name, partition_output_by_player, out_file_name = load_config
  
  # Load cmd line args
  opt_no_render = (ARGV.length > 0 and ARGV[0] == "--no_render")
    
  # Play the composition and generate the output Score Notes in memory
  score = CSnd::Score.new  
  # Gets phrases, modifies them as needed, loads phrases and score into Players collection
  players = load_phrases_and_init_players(num_players, num_note_functions, score)
  # Creates an Ensemble, passes it the Players, performs the piece, creates the Score
  ensemble = In_C::Ensemble.new players 
  ensemble.perform  
  # Write the output score to file, or files if output is partitioned by Player  
  if partition_output_by_player then
    # Write unpartitioned also so can hear output in one file -- useful when "debugging" different
    #  configurations of parameters and you don't want to somehow consolidate the separate tracks
    #  each time before hearing the result    
    score.write(score_file_name, score_include_file_name)
    score.write_partitioned(score_file_name, score_include_file_name)
  else
    score.write(score_file_name, score_include_file_name)
  end
  
  if not opt_no_render then
    # Render the output score files into actual sound files, in this case by calling
    #  CSound with the appropriate args and giving it the Score file(s) written
    if partition_output_by_player then
      render_output(partition_output_by_player, num_players, score_file_name, orc_file_name, out_file_name)
    end
    # Write unpartitioned no matter what so can hear output in one file -- useful when "debugging" different
    #  configurations of parameters and you don't want to somehow consolidate the separate tracks
    #  each time before hearing the result  
    render_output(false, num_players, score_file_name, orc_file_name, out_file_name)
  end
end
main
