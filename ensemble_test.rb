require 'test/unit'
require 'globals'
require 'ensemble'

module In_C


#
# These are the phrases that make up the Score
#

# TODO This looks wrong here and in in_c_notes.rb. Phrases should just be an array of Notes.
#  Why is each one being packaged into a Score in the array? Then each Player gets an array of Scores
#  each with just one phrase.  Is that right?


# Override to always return 100 for unit tests
#def tst_player.test_rnd 
#  In_C::RND_RNG 
#end

class Player_Test < Test::Unit::TestCase
  include In_C
  
  def setup
  end
  # def teardown
  # end
  puts "TESTING Class Player"
  
  def test__score
    puts "test__score ENTERED"
    
    tst_note = CSnd::Note.new.instr(1).start(0.0).dur(0.0).amp(0).pitch(0.0).add_attr(:func).func(1); tst_phrases = []
    tst_phrase1 = [tst_note.dup.start(0.0).dur($EITH).amp(1000).pitch($C4), tst_note.dup.start(0.0 + $EITH).dur($QRTR).amp(2000).pitch($E4)]
    tst_phrases.push CSnd::Score.new(tst_phrase1)
    tst_phrase2 = [tst_note.dup.start(0.0).dur($EITH).amp(1000).pitch($C4)]
    tst_phrases.push CSnd::Score.new(tst_phrase2)
    tst_score = CSnd::Score.new nil; tst_player = In_C::Player.new tst_phrases, tst_score
	
	assert(tst_player.score == tst_score)
	
    puts "test__score COMPLETED"	
  end
  
  def test__min_max_phrase_amp
    puts "test__min_max_phrase_amp ENTERED"
	
    tst_note = CSnd::Note.new.instr(1).start(0.0).dur(0.0).amp(0).pitch(0.0).add_attr(:func).func(1); tst_phrases = []
    tst_phrase1 = CSnd::Score.new([tst_note.dup.start(0.0).dur($EITH).amp(1000).pitch($C4), tst_note.dup.start(0.0 + $EITH).dur($QRTR).amp(2000).pitch($E4)])
    tst_phrases.push tst_phrase1
    tst_phrase2 = CSnd::Score.new([tst_note.dup.start(0.0).dur($EITH).amp(1000).pitch($C4)])
    tst_phrases.push tst_phrase2
    tst_score = CSnd::Score.new nil; tst_player = In_C::Player.new tst_phrases, tst_score
	
	min_amp, max_amp = tst_player.send(:min_max_phrase_amp, tst_phrase1)
	assert(min_amp == 1000)
	assert(max_amp == 2000)
	
    puts "test__min_max_phrase_amp COMPLETED"
  end

  def test__last_phrase?
    puts "test__last_phrase? ENTERED"
	
    tst_note = CSnd::Note.new.instr(1).start(0.0).dur(0.0).amp(0).pitch(0.0).add_attr(:func).func(1); tst_phrases = []
    tst_phrase1 = CSnd::Score.new([tst_note.dup.start(0.0).dur($EITH).amp(1000).pitch($C4)])
    tst_phrases.push tst_phrase1
    tst_score = CSnd::Score.new nil; tst_player = In_C::Player.new tst_phrases, tst_score	
	# Passed in one-note Score as phrases for this Player, so it's on last_phrase
	assert(tst_player.last_phrase?)

    tst_phrase2 = CSnd::Score.new([tst_note.dup.start(0.0).dur($EITH).amp(1000).pitch($C4)])
    tst_phrases.push tst_phrase2
    tst_score = CSnd::Score.new nil; tst_player = In_C::Player.new tst_phrases, tst_score
	# Passed in two-note Score as phrases for this Player, so it's not on last_phrase
	assert(! tst_player.last_phrase?)
	
	# Passed in empty list of notes for phrases
	tst_player = In_C::Player.new [], tst_score
	assert(tst_player.last_phrase?)

	# Passed in nil list of notes for phrases
	tst_player = In_C::Player.new [], tst_score
	assert(tst_player.last_phrase?)
	
    puts "test__last_phrase? COMPLETED"
  end
  
  def test__rest?
    puts "test__rest? ENTERED"
	
    tst_note = CSnd::Note.new.instr(1).start(0.0).dur(0.0).amp(0).pitch(0.0).add_attr(:func).func(1); tst_phrases = []
    tst_phrase1 = CSnd::Score.new([tst_note.dup.start(0.0).dur($EITH).amp(1000).pitch($C4), tst_note.dup.start(0.0 + $EITH).dur($QRTR).amp(2000).pitch($E4)])
    tst_phrases.push tst_phrase1
    tst_phrase2 = CSnd::Score.new([tst_note.dup.start(0.0).dur($EITH).amp(1000).pitch($C4)])
    tst_phrases.push tst_phrase2
    tst_score = CSnd::Score.new nil; tst_player = In_C::Player.new tst_phrases, tst_score
	
	# Set test_rnd on test Player object to return 0, so condition setting Player @at_rest == true
	#  is always met.  So test should always pass
	tst_player.toggle_override_tst_rnd_min
	assert(tst_player.send(:rest?))
	
	# Now set test_rnd so it will always be RND_RANGE, the maximum value. This causes the condition
	#  tested against return of test_rnd to always be false
	# Toggle _min back off so this condition not met in test_rnd
	tst_player.toggle_override_tst_rnd_min
	# Now toggle on max, so this condition is met, and RND_RNG is always returned from test_rnd
	tst_player.toggle_override_tst_rnd_max
	assert(! tst_player.send(:rest?))
	
	# Now toggle them both off and run it 10 times and print results, without assertions
	# Should have a distribution of values since there is an initial chance of 20% of resting
	tst_player.toggle_override_tst_rnd_max
	puts "Calling rest? with random value compared to threshold"	
	puts "This should have 2 true and 8 false in 10 calls, on average"
	puts tst_player.send(:rest?)
	puts tst_player.send(:rest?)
	puts tst_player.send(:rest?)
	puts tst_player.send(:rest?)
	puts tst_player.send(:rest?)
	puts tst_player.send(:rest?)
	puts tst_player.send(:rest?)
	puts tst_player.send(:rest?)
	puts tst_player.send(:rest?)
	puts tst_player.send(:rest?)
	puts "/Calling rest? with random value compared to threshold"	
		
    puts "test__rest? COMPLETED"
  end

  def test__transpose_shift
    puts "test__transpose_shift ENTERED"
	
    tst_note = CSnd::Note.new.instr(1).start(0.0).dur(0.0).amp(0).pitch(0.0).add_attr(:func).func(1); tst_phrases = []
    tst_phrase1 = CSnd::Score.new([tst_note.dup.start(0.0).dur($EITH).amp(1000).pitch($C4), tst_note.dup.start(0.0 + $EITH).dur($EITH).amp(2000).pitch($E4)])
    tst_phrases.push tst_phrase1
    tst_score = CSnd::Score.new nil; tst_player = In_C::Player.new tst_phrases, tst_score
	
	# Force both conditions in transpose_shift() to always be met
	tst_player.toggle_override_tst_rnd_min
	# @transpose_down_dur_threshold is $HLF, so avg. duration needs to be >= that to shift down
	# It's $EITH on first call, so expect positive shift of @transpose_shift (1)
	shift = tst_player.send(:transpose_shift, tst_phrase1)	
	assert(shift == 1)

    tst_phrase2 = CSnd::Score.new([tst_note.dup.start(0.0).dur($WHL).amp(1000).pitch($C4), tst_note.dup.start(0.0 + $EITH).dur($WHL).amp(2000).pitch($E4)])
	# It's $WHL on second call, so expect positive shift of @transpose_shift (-1)
	shift = tst_player.send(:transpose_shift, tst_phrase2)	
	assert(shift == -1)

    puts "test__transpose_shift COMPLETED"
  end
  
end


class Ensemble_Test < Test::Unit::TestCase
  # def setup
  # end
  # def teardown
  # end
  puts "TESTING Class Ensemble"
  
  def test__temp
    assert(true)
  end
  
end

end