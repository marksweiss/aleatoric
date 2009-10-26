require 'util'

include Aleatoric

##########################################################
# PLACE YOUR MAPPINGS AND INSTRUCTION IMPLEMENTATIONS HERE

# NOTE: ALL nooks MUST take a container arg, the object they are loaded into
#       For player hooks this is a Player, for ensemble hooks it's an Ensemble
#       The container is the mechanism for accessing the public methods of that type
#        and all the current public attributes of the object the method is loaded into.
#        each_player() below is an example of this
# NOTE: player preplay hooks must ALSO take a Score as an argument and return a Score
# NOTE: player postplay hooks and ensemble preplay and postplay just take container

fortissimo = lambda do |container, score|
  score.notes.each do |note|
    note.amplitude(note.amplitude * 2)
  end
  score
end
set_player_preplay_instruction("Fortissimo", &fortissimo)

pianissimo = lambda do |container, score|
  score.notes.each do |note|
    note.amplitude((note.amplitude.to_f * 0.5).to_i)
  end
  score
end
set_player_preplay_instruction("Pianissimo", &pianissimo)


# "Each Player Appends Another Player's First Note"
# NOTE: container type == Ensemble
each_player = lambda do |container|
  # Get players for this ensemble once, since order not guaranteed, and use the local var
  # TODO - CAN WE FIX THIS LEAK IN THE ABSTRACTION?
  players = container.players
    
  # If there aren't at least two players, the players can't add notes, so just exit
  return if players.length < 1
  
  # Use a standard name for the score we're adding
  new_score_name = "each_player Score"  

  # Handle case of the last player first, he'll play the first player's note
  # Each other player will play the note from the next player in the players list  
  last_player = players.last
  first_player = players.first
  # Handle case of player didn't play any notes in last iteration, no note case
  last_player.append_note_to_output(first_player.output.first) if not first_player.output_empty?
  # Now cycle the rest of the players
  (players.length - 1).times do |j|
    players[j].append_note_to_output(players[j+1].output.first) if not players[j+1].output_empty?
  end
end
# Postplay because description indicates players repeat notes played by other players
# We want to include any preplay changes to the note played before its copied here
set_ensemble_postplay_instruction("Each Player Appends Another Player's First Note", &each_player)


get_alternate_before_play = lambda do |container, score|
  if not container.get_state("alternate_flag") 
    score.notes.each do |note|
      note.amplitude(0)
    end
  end
  score
end
# NOTE: postplay Player hooks take containing object argument and return nothing
set_alternate_after_play = lambda do |container|
  alt_flag = container.get_state("alternate_flag") || false  
  container.set_state("alternate_flag", ! alt_flag) 
end
# NOTE: Set both hooks, each a different type, under the same name from the Composer score
set_player_preplay_instruction("Alternate", &get_alternate_before_play)
set_player_postplay_instruction("Alternate", &set_alternate_after_play)

 
# NOTE: Ensemble preplay hook just takes container, ref to self, doesn't assume Score input
# NOTE: Ensemble preplay hook returns nil, unlike Player which returns a Score
get_alternate_before_play_ens = lambda do |container|  
  if not container.get_state("alternate_flag")
    container.players.each do |player|
      # get a copy of the current score
      score = player.current_score
      # store a copy of the current score in the ensemble
      container.set_state(player.name, score.dup)
      # alter the score to have no amp on each note
      score.notes.each do |note|
        note.amplitude(0)
      end
      # set the altered score as the score for that score.name for the player
      # Effectively, we have stored a copy and replaced what was there with a silent score
      
      # TEMP DEBUG
      debug_log "score.name #{score.name}"
      
      player.set_score(score.name, score)
    end
  end
end

set_alternate_after_play_ens = lambda do |container|
  # toggle the flag
  alt_flag = container.get_state("alternate_flag") || false  
  container.set_state("alternate_flag", ! alt_flag) 
  # Now afterward, always restore the saved unaltered copy of the current score
  #  back into each player for the ensemble
  container.players.each do |player|
    score = container.get_state(player.name)
    player.set_score(score.name, score)
  end
end
set_ensemble_preplay_instruction("Alternate Ensemble", &get_alternate_before_play_ens)
set_ensemble_postplay_instruction("Alternate Ensemble", &set_alternate_after_play_ens)

# NOTE: Improv hooks take no args and return a Score
improvise_whole_c = lambda do
  note = Note.new("", {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})
  score = Score.new()
  score << [note]
  score
end
set_improvisation("Play a whole note on Middle C", &improvise_whole_c)

improvise_whole_d = lambda do
  note = Note.new("", {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.02000, :func_table=>1})
  score = Score.new()
  score << [note]
  score
end
set_improvisation("Play a whole note on Middle D", &improvise_whole_d)

# /PLACE YOUR MAPPINGS AND INSTRUCTION IMPLEMENTATIONS HERE
##########################################################
