require 'composer'

include Aleatoric

##########################################################
# PLACE YOUR MAPPINGS AND INSTRUCTION IMPLEMENTATIONS HERE


# NOTE: Instruction hooks must take a Score as an argument and return a Score
fortissimo = lambda do |score|
  score.notes.each do |note|
    note = note.dup
    note.amplitude(note.amplitude * 2)
  end
  score
end
set_preplay_instruction("Fortissimo", &fortissimo)


# /PLACE YOUR MAPPINGS AND INSTRUCTION IMPLEMENTATIONS HERE
##########################################################