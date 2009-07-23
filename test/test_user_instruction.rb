require 'util'

include Aleatoric

##########################################################
# PLACE YOUR MAPPINGS AND INSTRUCTION IMPLEMENTATIONS HERE

# NOTE: ALL nooks MUST take a container arg, the object they are loaded into

# NOTE: Instruction hooks must ALSO take a Score as an argument and return a Score
fortissimo = lambda do |container, score|
  score.notes.each do |note|
    note.amplitude(note.amplitude * 2)
  end
  score
end
set_preplay_instruction("Fortissimo", &fortissimo)

pianissimo = lambda do |container, score|
  score.notes.each do |note|
    note.amplitude((note.amplitude.to_f * 0.5).to_i)
  end
  score
end
set_preplay_instruction("Pianissimo", &pianissimo)

# "Each Player Appends Another Player's First Note"
# NOTE: containr type == Ensemble
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
# Postplay because descriptiont indicates players repeat notes played by other players
# We want to include any preplay changes to the note played before its copied here
set_postplay_instruction("Each Player Appends Another Player's First Note", &each_player)

get_alternate_before_play = lambda do |container, score|
  alt_flg = container.get_state("alternate_flag")
  if alt_flg == nil or alt_flg = false    
    score.notes.each do |note|
      note.amplitude(0)
    end
  end
  score
end
# NOTE: postplay Player hooks take containing object argument and return nothing
set_alternate_after_play = lambda do |container|
  alt_flg = container.get_state("alternate_flag") 
  if alt_flg == nil or alt_flg == false
    container.set_state("alternate_flag", true) 
  else
    container.set_state("alternate_flag", false) 
  end
end
# NOTE: Set both hooks, each a different type, under the same name from the Composer score
set_preplay_instruction("Alternate", &get_alternate_before_play)
set_postplay_instruction("Alternate", &set_alternate_after_play)

# /PLACE YOUR MAPPINGS AND INSTRUCTION IMPLEMENTATIONS HERE
##########################################################
