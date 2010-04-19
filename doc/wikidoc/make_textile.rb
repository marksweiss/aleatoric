def make_textile(line)
  j = 0
  prefix = ''
  while line[j] == 32
    prefix.concat "&nbsp;"
    j += 1
  end
	line = line.strip
	if line.length > 0
  	prefix + '@' + line + "@<br/>" 
	else
		"<br/>"
	end
end


lines = 
'# First we create an ensemble, and put players and a phrase into it
#  The phrase is associated with the ensemble, so each player in the
#  ensemble will play it.
ensemble "In C Orchestra"
  players "Player 1", "Player 2"  
  
  phrase "Phrase 1"
    note "1"
      instrument  1 
      start       1.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
      
    note "2"
      instrument  2 
      start       2.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1


# ... then we refer to it here by name as one or more phrases
#  to be played by Aleatoric when performing the score ...
play
  phrases "Phrase 1"

# ... and finally we tell Aleatoric to include the notes from this phrase 
#  in the final sound file, again by listing it\'s name in the phrases list
render "my_composition.mid"
  phrases "Phrase 1"	
  format    midi'
 
lines.each do |line|
  puts(make_textile(line))
end