# Convert a line of a block to textile
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

# Convert a block of a composer_test test case block to textile
def make_composer_test_textile(line)
  return '' if line.match('# TESTING PURPOSES ONLY') or line.match('reset_script_state')
  
  # test for the comment line with test name, convert to textile headline
  if line.match('# test__')
    line.strip!
    lbound = ('# test__'.length)
    rbound = line.length
    if line.match('_lite_syntax')
      rbound -= '_lite_syntax'.length
    end
    line = line[lbound..rbound]
    words = line.split("_")
    ret = "<br/>*"
    words.each do |word|
      ret += word.capitalize + ' '
    end

    return ret.rstrip + "*<br/>"
  end
       
  return make_textile(line)
end

################################################

# Use for an arbitrary example block
lines = ''

# Use for an array of example blocks from composer_test.rb
list_of_lines = [
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__measure_lite_syntax

measure "Measure 1"

  note "1"
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1

  note "2"
    instrument  1 
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1

measure "Measure 2"

  note "3"
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1200
    pitch       7.03
    func_table  1

  note "4"
    instrument  1 
    start       1.0 
    duration    1.0
    amplitude   1300
    pitch       7.04
    func_table  1
    
write "composer_test_results.txt"
  format    csound
  measures   "Measure 1", "Measure 2"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__copy_measure_lite_syntax

measure "Measure 1"

  note "1"
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1

  note "2"
    instrument  1 
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1

# NOTE: copy_measure automatically adjusts start times of new measure to be in NEXT position
#  after end of last note in measure being copied, intended for sequence of notes
# TODO: IS THIS USEFUL? MODERATELY, but only serves that one use case, NOT a really useful general
#  cloning mechanism
copy_measure "Measure 1", "Measure 2"
    
write "composer_test_results.txt"
  format    csound
  measures
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__tempo

# Define a simple function to test tempo handling complex
#  expression for duration
times_two: x
  2.0 * x

# Tempo is specified in bpm, i.e. 60 == 60 quarter notes/min
#  or a quarter note is 1 sec. or a whole note is 4 secs.
# Default tempo is 60, so if this isn't set above holds
# If it is set, AND durations are specified using duration constants
#  such as WHL, HLF, etc.  The reason for this is that if the score specifies
#  exact tempos in seconds, not just "relative" lengths such as WHL etc. then
#  those exact tempos should be honored
tempo 30

# Test expression rather than simple 2-token line
measure "Measure 1"
  note "1"
    instrument  1 
    start       0.0 
    duration    WHL+HLF  
    amplitude   1000
    pitch       7.01
    func_table  1

  note "2"
    instrument  1 
    start       EITH
    duration    times_two: HLF 
    amplitude   1100
    pitch       7.02
    func_table  1

  note "3"
    instrument  1 
    start       0.0 
    duration    QRTR
    amplitude   1200
    pitch       7.03
    func_table  1

# You can reset tempo whenever you want. Now it's twice as fast as default
tempo 120

# Test expression rather than simple 2-token line
measure "Measure 2"
  note "4"
    instrument  1 
    start       0.0 
    duration    WHL+HLF  
    amplitude   1000
    pitch       7.01
    func_table  1

  note "5"
    instrument  1 
    start       QRTR + QRTR 
    duration    HLF
    amplitude   1100
    pitch       7.02
    func_table  1

  note "6"
    instrument  1 
    start       0.0 
    duration    QRTR
    amplitude   1200
    pitch       7.03
    func_table  1

write "composer_test_results.txt"
  format    csound
  measures   "Measure 1", "Measure 2"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__tempo_default

# Don't set tempo and default is 60 bpm, quarter note == 1 sec
# tempo 30

measure "Measure 1"
  note "1"
    instrument  1 
    start       0.0 
    duration    WHL
    amplitude   1000
    pitch       7.01
    func_table  1

  note "2"
    instrument  1 
    start       1.0 
    duration    HLF
    amplitude   1100
    pitch       7.02
    func_table  1

  note "3"
    instrument  1 
    start       0.0 
    duration    QRTR
    amplitude   1200
    pitch       7.03
    func_table  1

write "composer_test_results.txt"
  format    csound
  measures   "Measure 1"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__section_lite_syntax

section "Intro Section"

phrase "Intro Phrase"

  note "3"
    instrument  3 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.03
    func_table  1
  
  note "4"
    instrument  4
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.04
    func_table  1

write "composer_test_results.txt"
  format    csound
  sections   "Intro Section"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__sections_phrases_lite_syntax

section "Intro Section"
  phrase "Intro Phrase"
    note "5"
      instrument  1 
      start       0.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
    
    note "6"
      instrument  1
      start       1.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

  phrase "Coda"
    note "7"
      instrument  1 
      start       0.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1

    note "8"
      instrument  1
      start       1.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

write "composer_test_results.txt"
  format    csound
  sections  "Intro Section"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__repeat_index_lite_syntax

phrase "Loop"
  repeat 2
    note "1"
      instrument 1
      start       1.0 * index
      duration    0.2
      amplitude   1000 + (100 * index) 
      pitch       7.02
      func_table  1
      
    note "2"
      instrument 1
      start       1.0 * index
      duration    0.2
      amplitude   1000 + (100 * index) 
      pitch       7.02
      func_table  1
      
write "composer_test_results.txt"
  format    csound
  phrases   "Loop"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__render_lite_syntax

phrase "Intro Phrase"

  note "1"
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1
  
  note "2"
    instrument  1
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1

write "composer_test_results.txt"
  format    csound
  phrases   "Intro Phrase"

render "composer_test.wav"
  orchestra  "markov_opt_1.orc"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__render_lite_syntax_default_write

phrase "Intro Phrase"

  note "1"
    instrument  1 
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1
  
  note "2"
    instrument  1
    start       1.0 
    duration    1.0
    amplitude   1100
    pitch       7.02
    func_table  1

render "composer_test.wav"
  phrases   "Intro Phrase"
  format    csound
  orchestra  "markov_opt_1.orc"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__assignment

note_name_3 = "3"
note_name_4 = "4"
instr_num_3 = 3
instr_num_4 = 4
pitch_3 = 7.03
pitch_4 = 7.04

section "Intro Section"
  phrase "Intro Phrase"
    note note_name_3
      instrument  instr_num_3 
      start       0.0 
      duration    0.5
      amplitude   1000
      pitch       pitch_3
      func_table  1
      
    note note_name_4
      instrument  instr_num_4
      start       1.0 
      duration    1.0
      amplitude   1100
      pitch       pitch_4
      func_table  1

write "composer_test_results.txt"
  format    csound
  sections   "Intro Section"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__assignment_comment

note_name_3 = "3"  # comment blah blah
note_name_4 = "4"
instr_num_3 = 3      # comment blah blah
instr_num_4 = 4 # comment blah blah
pitch_3 = 7.03
pitch_4 = 7.04

 # comment blah blah
section "Intro Section"   # comment blah blah
  phrase "Intro Phrase"     # comment blah blah
    note note_name_3    # comment blah blah
      instrument  instr_num_3    # comment blah blah
      start       0.0 
      duration    0.5
      amplitude   1000
      pitch       pitch_3
      func_table  1
# comment blah blah
    note note_name_4
      instrument  instr_num_4
      start       1.0 
      duration    1.0
      amplitude   1100
      pitch       pitch_4
      func_table  1
          # comment blah blah
write "composer_test_results.txt"
  # comment blah blah
  format    csound
  sections   "Intro Section"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__assignment_2

note_name_3 = "3"

phrase "Intro Phrase"

  note note_name_3
    instrument  1
    start       0.0 
    duration    0.5
    amplitude   1000
    pitch       7.01
    func_table  1

write "composer_test_results.txt"
  format    csound
  phrases   "Intro Phrase"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__repeat_assignment

loop_len = 2

phrase "Loop"
  repeat loop_len
    note
      instrument  1
      start       1.0 * index
      duration    0.2
      amplitude   1000 + (100 * index) 
      pitch       7.02
      func_table  1

write "composer_test_results.txt"
  format    csound
  phrases   "Loop"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__repeat_until

player "Player 1"

phrase "Loop"
  repeat until "I want to stop"
    note
      instrument  1
      start       1.0 * index
      duration    0.2
      amplitude   1000 + (100 * index) 
      pitch       7.02
      func_table  1

instruction "Exit Loop"
  description "call repeat_until_stop('I want to stop')"
  players     "Player 1"

play
  players "Player 1"

write "composer_test_results.txt"
  format    csound
  phrases   "Loop"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__func

start_f: factor, idx
  factor * idx

amp_f: base, factor, idx
  base + (factor * idx)

phrase "Loop"
  repeat 2
    note
      instrument 1
      start       start_f: 1.0, index
      duration    0.2
      amplitude   amp_f: 1000, 100, index
      pitch       7.02
      func_table  1

write "composer_test_results.txt"
  format    csound
  phrases   "Loop"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__next

measure "Loop"
    note
      instrument 1
      start       0.0
      duration    1.0
      amplitude   1000
      pitch       7.01
      func_table  1

    note
      instrument 1
      start       NEXT
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1
      
write "composer_test_results.txt"
  format    csound
  measures   "Loop"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__ensemble

# NOTE: CANNOT do non-block "lite" syntax with 'dump*' calls !!!
# The dump call ends up within the block scope because it's not specified
#  in composer_lang as a block closing keyword
ensemble "In C Orchestra" do
  players "Player 1", "Player 2"  
end

# FOR TESTING ONLY    
dump_last_ensemble  
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__ensemble_phrase_play_players

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

play
  players "Player 1", "Player 2" 
  
write "composer_test_results.txt"
  format    csound
  players "Player 1", "Player 2"
  # ensembles "In C Orchestra"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__instruction_players

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

# Just tell one player in the ensemble to follow this instruction
# impl. in test_user_instruction.rb
instruction "Fortissimo"
  description "Player should play each note twice as loud as the notated volume of the note."
  players     "Player 1"

# Just tell one player in the ensemble to follow this instruction
# impl. in test_user_instruction.rb
instruction "Pianissimo"
  description "Player should play each note half as loud as the notated volume of the note."
  players     "Player 2"

# Tell all players in the ensemble to play
play
  ensembles "In C Orchestra"
  
# Output notes from all players in the ensemble, generated by 'play' statement
write "composer_test_results.txt"
  format    csound
  ensembles "In C Orchestra"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__instruction_players_ensembles

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  

player "Player 1"  
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

player "Player 2"  
  phrase "Phrase 1"
    note "3"
      instrument  3 
      start       3.0 
      duration    1.5
      amplitude   1200
      pitch       7.03
      func_table  1
      
    note "4"
      instrument  4 
      start       4.0 
      duration    2.0
      amplitude   1300
      pitch       7.04
      func_table  1      
      
# Just tell one player in the ensemble to follow this instruction
# impl. in test_user_instruction.rb
instruction "Fortissimo"
  description "Player should play each note twice as loud as the notated volume of the note."
  players     "Player 1"

# Just tell one player in the ensemble to follow this instruction
# impl. in test_user_instruction.rb
instruction "Pianissimo"
  description "Player should play each note half as loud as the notated volume of the note."
  players     "Player 2"
  
# impl. in test_user_instruction.rb
instruction "Each Player Appends Another Player's First Note"
  description "Each member of the ensemble should repeat the first note played by another member of the ensemble as their last note."
  ensembles   "In C Orchestra"

# Tell all players in the ensemble to play
play
  ensembles "In C Orchestra"
  
# Output notes from all players in the ensemble, generated by 'play' statement
write "composer_test_results.txt"
  format    csound
  ensembles "In C Orchestra"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__phrase_midi_lite_syntax

phrase "Intro Phrase"
  
  # Using aliased MIDI property names for note. Note 'channel' is midi-only
  note "1"
    instrument  1  
    time       0.0
    duration    1.0
    velocity    100
    pitch       64 
    channel     1 

  # Using csound and "Aleatoric normal" property names for a note. Note 'channel' is midi-only
  note "2"
    instrument  1
    start       1.0
    duration    1.0
    amplitude   100
    pitch       65 
    channel     1
    
  # Using csound and "Aleatoric normal" property names for a note, but switch to use 'volume' for 'velocity.' Note 'channel' is midi-only
  note "3"
    instrument  1
    start       2.0
    duration    1.0
    volume      100
    pitch       66 
    channel     1     
    
write "composer_test_results.txt"
  format    midi
  phrases   "Intro Phrase"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__phrase_midi_format_top

format midi

phrase "Intro Phrase"
  
  # Using aliased MIDI property names for note. Note 'channel' is midi-only
  note "1"
    instrument  1  
    time       0.0
    duration    1.0
    velocity    100
    pitch       64 
    channel     1 

  # Using csound and "Aleatoric normal" property names for a note. Note 'channel' is midi-only
  note "2"
    instrument  1
    start       1.0
    duration    1.0
    amplitude   100
    pitch       65 
    channel     1
    
  # Using csound and "Aleatoric normal" property names for a note, but switch to use 'volume' for 'velocity.' Note 'channel' is midi-only
  note "3"
    instrument  1
    start       2.0
    duration    1.0
    volume      100
    pitch       66 
    channel     1     
    
write "composer_test_results.txt"
  phrases   "Intro Phrase"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__ensemble_instrument_channel_midi_render

format midi

player "Player 1"
  instrument 1
  channel 1
player "Player 2"  
  instrument 2
  channel 2

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  

  phrase "Intro Phrase"
  
    note "1"
      time       0.0
      duration    1.0
      velocity    100
      pitch       64 

    note "2"
      start       1.0
      duration    1.0
      amplitude   100
      pitch       65 
    
    note "3"
      start       2.0
      duration    1.0
      volume      100
      pitch       66 

play
  ensembles "In C Orchestra"
  
write "composer_test_results.txt"
  ensembles "In C Orchestra"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__phrase_midi_format_consts

format midi

phrase "Intro Phrase"
  
  # Using aliased MIDI property names for note. Note 'channel' is midi-only
  note "1"
    instrument  MIDI_Acoustic_Grand_Piano  
    time       0.0
    duration    1.0
    velocity    100
    pitch       Bneg1 
    channel     1 

  # Using csound and "Aleatoric normal" property names for a note. Note 'channel' is midi-only
  note "2"
    instrument  MIDI_Bright_Acoustic_Piano
    start       1.0
    duration    1.0
    amplitude   100
    pitch       C4 
    channel     1
    
  # Using csound and "Aleatoric normal" property names for a note, but switch to use 'volume' for 'velocity.' Note 'channel' is midi-only
  note "3"
    instrument  MIDI_Electric_Grand_Piano
    start       2.0
    duration    1.0
    volume      100
    pitch       B5 
    channel     1     
    
write "composer_test_results.txt"
  phrases "Intro Phrase"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__phrase_csound_format_consts

format csound

phrase "Intro Phrase"
  
  note "1"
    instrument  1  
    start       0.0
    duration    1.0
    amplitude   100
    pitch       C4 
    func_table  1 

  note "2"
    instrument  2
    start       1.0
    duration    1.0
    amplitude   100
    pitch       C5 
    func_table  1
    
  note "3"
    instrument  3
    start       2.0
    duration    1.0
    amplitude   100
    pitch       C6 
    func_table  1     
    
write "composer_test_results.txt"
  phrases "Intro Phrase"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__player_instrument

format csound

player "Player 1"
  instrument 1
player "Player 2"
  instrument 2

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  
  
  phrase "Phrase 1"
    note "1"
      start       1.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
      
    note "2"
      start       2.0 
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

play
  players "Player 1", "Player 2" 
  
write "composer_test_results.txt"
  players "Player 1", "Player 2"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__player_instrument_channel

format midi

player "Player 1"
  instrument 1, channel=0
player "Player 2"
  instrument 2, channel=1

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  
  
  phrase "Phrase 1"
    note "1"
      start       1.0 
      duration    0.5
      volume      100
      pitch       60
      
    note "2"
      start       2.0 
      duration    1.0
      volume     110
      pitch       61

play
  players "Player 1", "Player 2" 
  
write "composer_test_results.txt"
  players "Player 1", "Player 2"
},
%Q{
# TESTING PURPOSES ONLY
reset_script_state
# test__no_start_auto_next

format csound

player "Player 1"
  instrument 1
player "Player 2"
  instrument 2

ensemble "In C Orchestra"
  players "Player 1", "Player 2"  
  
  phrase "Phrase 1"
    note "1"
      start       1.0 
      duration    0.5
      amplitude   1000
      pitch       7.01
      func_table  1
      
    note "2"
      duration    1.0
      amplitude   1100
      pitch       7.02
      func_table  1

play
  players "Player 1", "Player 2" 
  
write "composer_test_results.txt"
  players "Player 1", "Player 2"
}
]

################################################

# Single text block, used to convert arbitrary example text block
def make_block_textile(lines)
  lines.each do |line|
    puts(make_textile(line))
  end
end

# List of text blocks, used to convert composer_test script blocks
def make_list_of_blocks_textile(list_of_lines)
  list_of_lines.each do |block_lines|
    block_lines.each do |line|
      line = make_composer_test_textile line 
      puts line if line.length
    end
  end
end

################################################

# NOTE: Run one of these at a time, comment out the other

# make_block_textile lines
make_list_of_blocks_textile list_of_lines 
