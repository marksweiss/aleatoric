include Aleatoric

##########################################################
# PLACE YOUR MAPPINGS AND INSTRUCTION IMPLEMENTATIONS HERE


# NOTE: Instruction hooks must take a Score as an argument and return a Score
fortissimo = lambda do |score|
  score.notes.each do |note|
    note.amplitude(note.amplitude * 2)
  end
  score
end
set_preplay_instruction("Fortissimo", &fortissimo)

pianissimo = lambda do |score|
  score.notes.each do |note|
    note.amplitude((note.amplitude.to_f * 0.5).to_i)
  end
  score
end
set_preplay_instruction("Pianissimo", &pianissimo)


# /PLACE YOUR MAPPINGS AND INSTRUCTION IMPLEMENTATIONS HERE
##########################################################


