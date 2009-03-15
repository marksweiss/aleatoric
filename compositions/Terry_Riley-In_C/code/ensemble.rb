require 'globals'
require 'score'
require 'yaml'
# TODO Factor into two files, but there is a circular dependency
# require 'player'

# Custom extension of Array used by Ensemble#perform
class Array
  # def all_items_uniq?
  #  length == 0 || length == uniq.length
  # end
  def all_items_equal?
    length == 0 || uniq.length == 1
  end
end

#TODO Normalize all Players amp to a max set by config or property to total across each iteration
# normalizes to sum to <= this max
module In_C

# These are like "requirements" ...
#
# Performing Directions (All of these comments, and all comments marked "REQS," are
#  from the actual score for "In C," by Terry Riley
# ---------------------
#
# - "...53 melodic patterns played in sequence."
# - "Any number of any kind of instruments can play. A group of about 35 is desired ..."
# - "...each performer having the freedom to determine how many times he or she
# ... will repeat each pattern"
# - "performances normally average between 45 minutes and an hour and
# a half, it can be assumed that one would repeat each pattern from somewhere
# between 45 seconds and a minute and a half"
# - "As an ensemble, it is very desirable to play very softly as well as very
# loudly and to try to diminuendo and crescendo together."
# - "Each pattern can be played in unison or canonically in any alignment with itself or
# with its neighboring patterns."
# - "... performers should stay within 2 or 3 patterns of each other."
# - "The ensemble can be aided by the means of an eighth note pulse played on the high
# c’s of the piano or on a mallet instrument."
# - "All performers must play strictly in rhythm ..."
# - "... it is essential that everyone play each pattern carefully."
# - "The tempo is left to the discretion of the performers, obviously not too slow ..."
# - "The group should aim to merge into a unison at least once or twice during the performance."
# - " ...if the players seem to be consistently too much in the same alignment
# of a pattern, they should try shifting their alignment by an eighth note
# or quarter note
# - "It is OK to transpose patterns by an octave, especially to transpose up."
# - "Transposing down by octaves works best on the patterns containing notes of long durations."
# - "Augmentation of rhythmic values can also be effective."
# - "Instruments can be amplified if desired."
# - "Electronic keyboards are welcome"
# - "IN C is ended in this way$ when each performer arrives at figure No.53, he or she
# stays on it until the entire ensemble has arrived there. The group then makes a large
# crescendo and diminuendo a few times and each player drops out as he or she
# wishes."
#
# ----------------------
# /Performing Directions

# TODO REQS
# - "Augmentation of rhythmic values can also be effective."
# /REQS
=begin RDoc
This class models a musical performer, a player, in an ensemble of musical performers.  The concept
can (hopefully) be generalized, which is a goal of this project.  But right now, some of the 
properties and methods are general, and some encode specific rules (as predicates which test 
tunable param values against a random number) that define the behavior of the Player in ways
particular to the score for "In C."  Documentation for the tunable params controlling the
behavior of the class is in player.yml.
=end
class Player
  include In_C
  
  @@id_counter = 0

  # Allow override of test_rnd, otherwise can't get deterministic results
  #  and so can't really unit test a lot of the class
  # Two calls, one to force test_rnd to always return 0, other to force it to always return 1
  # Of course you could argue that these also allow users to override random behavior of an object
  #  and force it meet conditions, which is true
  # TODO document how to use these methods
  # TODO figure out whether proper mocking in unit tests means I don't need this
  @override_tst_rnd_min = false
  def toggle_override_tst_rnd_min
    @override_tst_rnd_min = ! @override_tst_rnd_min
  end
  @override_tst_rnd_max = false
  def toggle_override_tst_rnd_max
    @override_tst_rnd_max = ! @override_tst_rnd_max
  end
  
  # Helper used by the predicate functions to test probability in nice, readable "100%" form
  RND_RNG = 100
  def test_rnd
    if @override_tst_rnd_min
	  0
	elsif @override_tst_rnd_max
	  RND_RNG
	else
      rand(RND_RNG)
	end
  end
  
  attr_accessor :phrases_idx, :phrases_length,
                :rest_prob_factor, :stay_at_rest_prob_factor,
                :amp_crescendo_adj_factor, :amp_diminuendo_adj_factor,
                :amp_adj_crescendo_ratio_threshold, :amp_adj_diminuendo_ratio_threshold,
                :phrase_adv_prob_factor,
                :diminuendo_prob_factor,
                :adj_phase_prob_factor, :phase_adj_dur,
                :transpose_prob_factor, :transpose_shift,
                :transpose_down_dur_threshold, :transpose_down_prob_factor,
                :unison_prob_factor,
                :swing_range_min, :swing_range_max, :cur_start
  attr_reader   :pid 

=begin RDoc
ctor
=end
  def initialize(phrases, score)
    # Array of Notes played by this Player
    @phrases = phrases
	# Offset into @phrases that this player is currently playing
	@phrases_idx = 0
    # Indicator that the Player is at rest
    @at_rest = false
    # For Ensemble to test this sliced across all its Players
    @max_amp = 0
    # Ref to the Score into which the Notes are being added, the Score being composed
    @score = score

    # Time offset from T0 for next Note
    @offset = 0.0
	# Updated as player plays each phrase so that start times move ahead in time
	@cur_start = 0.0
    
    # Assign the Player a unique_id, this is obviously cheesy and not thread safe, but fine for now
	@pid = @@id_counter + 1
	@@id_counter = @pid
    
    # TEMP DEBUG
    # puts "Plyaer @@id_counter = #{@@id_counter}"

    # Load all tunable parameters governing Player compositional behavior from conf
    load_config
  end
  
  private
=begin RDoc
See player.yml for tunable parameters which are loaded here as object variables.
=end
  def load_config
    # Load config and set instance variables from each Player entry
    conf = YAML.load_file("player.yml")
    conf["player"].each {|k,v| instance_variable_set("@#{k}", v)}    
    # Set values for derived instance variables
    @swing_rng = @swing_range_max - @swing_range_min    
  end
  public

=begin RDoc
Player self registers with Ensemble.  Ensemble and Player have circular depdendencies, checking
on each other's state during the performance.  Players react to the state of all the Players playing,
and the Ensemble keeps track of all that state and also reacts to some of it.
=end
  def join_ensemble(ensemble)
    @ensemble = ensemble
  end

=begin RDoc
The output Score the Player is writing Notes to
=end
  def score
    @score
  end
  
=begin RDoc
The length in number of distinct phrases of the list of phrases being played by the Player
=end
  def phrases_length
    @phrases.length
  end
  
=begin RDoc
A reference to the current phrase being played by the Player
=end
  def cur_phrase
    @phrases[@phrases_idx]
  end

=begin RDoc
This is the main driver for each Player playing its note on each iteration of the 
Ensemble#perform method.  Holds all the "business rule" logic governing player behavior
which helps enforce various of the score rules. e.g. "if last_phrase? ..."  So this
method tests the current state of the Player and the Ensebmle against rules of the composition
and decides things like, "should I stop playing for one iteration?", "should I transpose
up an octave what I'm playing?" etc.
=end
  def play_phrase    
	# TEMP DEBUG
	# @@phrase_loop_count = @@phrase_loop_count + 1
	# puts "phrase_loop_count #{@@phrase_loop_count}"
  
    # REQS
    # - "IN C is ended in this way, when each performer arrives at figure No.53, he or she
    # stays on it until the entire ensemble has arrived there. The group then makes a large
    # crescendo and diminuendo a few times and each player drops out as he or she
    # wishes."
    # /REQS
    
    # Get a copy of the current phrase -- possibly manipulated before writing
    phrase = @phrases[@phrases_idx].dup
	phrase.each do |note|
	  # Reset start times to current start time for this player
      note.start(note.start + @cur_start)
      # Put Player into Note so we can partition Notes in output Score by Player
      note.player_id(@pid)
    end
	
    # Early return on last phrase
    if last_phrase?
      # Early return
      play_phrase_set_post_conditions phrase
      @score.append_score(set_phrase_player(phrase))
	  return
    end
	
    # REQS
    # - "...each performer having the freedom to determine how many times he or she
    # ... will repeat each pattern"
    # - "performances normally average between 45 minutes and an hour and
    # a half, it can be assumed that one would repeat each pattern from somewhere
    # between 45 seconds and a minute and a half"
    # - "... performers should stay within 2 or 3 patterns of each other."
    # /REQS
    must_play = false
    if phrases_idx_too_far_behind?
      @phrases_idx += 1
      must_play = true
    elsif seeking_unison?
      @phrases_idx += @ensemble.unison_phrase_idx_adj(self)
      must_play = true
    elsif advance_phrases_idx?
      @phrases_idx += 1
      must_play = true
    end

    # REQS
    # - "... performers should stay within 2 or 3 patterns of each other."
    # /REQS
    if not must_play and rest?
      rest = phrase.rest      
      # Early return
      play_phrase_set_post_conditions rest
	  @score.append_score rest
      return
    end

    # REQS
    # - "Each pattern can be played in unison or canonically in any alignment with itself or
    # with its neighboring patterns."
    # - " ...if the players seem to be consistently too much in the same alignment
    # of a pattern, they should try shifting their alignment by an eighth note
    # or quarter note
    # /REQS
    if adj_phase?	  # if not must_play and adj_phase?
	  note = phrase.notes[0].dup
	  note.start(note.start - @phase_adj_dur)
      # Put Player into Note so we can partition Notes in output Score by Player
      note.player_id(@pid)
      phrase.insert_note(0, CSnd::Note.rest(note, @phase_adj_dur, @pid))
	  
	  # Push up start times of all notes following
	  for j in 1..phrase.notes.length - 1
	    note = phrase.notes[j]
	    note.start(note.start + @phase_adj_dur)
	  end
    end

    # - "As an ensemble, it is very desirable to play very softly as well as very
    # loudly and to try to diminuendo and crescendo together."
    adj = amp_adj phrase	
    phrase.each do |note|      
	  note.amp((note.amp * adj).to_i)
	end

    # If something is true, transpose the phrase
    shift = transpose_shift phrase
    phrase.transpose!(shift)
	  
    # Apply phrasing, dynamics, pitch dot etc. added as optional attributes to
    #   any Notes in the phrase, from the Note data array in the "*_notes.rb" file
    # This approach allows arbitrary phrasing, e.g. legato, to be applied per
    #  note in the composition's Note data.
    # See "in_c_notes.rb" which shows how this score implements legato:
    #  - lambdas defined that show Note modifying itself
    #  - Notes that want legato chain add_custom_attr(:legato, legato_lambda)
    #    onto the Note definition in the array of Phrases
    # So this approach allows any user to extend Note with inline lambdas
    #  and know they Player will call them on each iteration for each Note in its phrase
    phrase.each do |note| 	  
	  note.apply_custom_attrs 
	end
	
    # Apply "swing" variance in start time and duration to each note in phrase
    # NOTE: Please make this a useful small range around 1.0, e.g. defaults of 0.98..1.02,
    #  so effect is multiplying existing value by factor that slightly shades it higher
    #  or lower and often has no (or no discernible) effect
    if @swing_rng > 0 then
      phrase.transform! do |note|	
        prev_start = note.start; prev_dur = note.dur
	    # Mod into range of small float, and randomly set sign +/-
	    start_swing = (rand(0.1) % @swing_rng) * (rand(2) % 2 == 0 ? -1 : 1)
	    dur_swing = (rand(0.1) % @swing_rng) * (rand(2) % 2 == 0 ? -1 : 1)
	    # Now modify the note by it's old value +/- it's old value multiplied by the swing value

        # TEMP DEBUG
        #puts "prev_start #{prev_start}"         
        #puts "start_swing #{start_swing}"         
        #puts "(prev_start * start_swing) #{(prev_start * start_swing)}"         
        #puts "prev_start + (prev_start * start_swing) #{prev_start + (prev_start * start_swing)}"         
	  
        note.start(prev_start + (prev_start * start_swing)).dur(prev_dur + (prev_dur * dur_swing))
	  end
    end

    # After all note manipulations done, set Player state that depends on them
    play_phrase_set_post_conditions phrase
    	
    # Write It!
    @score.append_score(set_phrase_player(phrase))
  end
  
  private
  def play_phrase_set_post_conditions(phrase)
    # Reset class var min_amp, max_amp after all phrase manipulation, 
    @min_amp, @max_amp = min_max_phrase_amp(phrase)    
	# Adjust @cur_start for this player, it's the moment right after end of last note in this phrase
	@cur_start += phrase.dur
  end
  public

  #
  # Helpers for Ensemble to call to check Player state for it's global Ensemble state
  
=begin RDoc
This is pared down play_phrase just for the Conclusion crescendo/descrescendo that is
specified in the score to "In C."  First, no logic that could lead to rests, 
not playing, etc.  Second, takes an amp_adj value to adjust the value as part of 
crescendo/decrescendo
=end
  def play_conclusion_phrase(amp_adj)  
    phrase = @phrases[@phrases_idx].dup
	phrase.each do |note|     
	  # Reset start times to current start time for this player
      # Adjust each notes amplitude by the crescendo amount
      note.
        start(note.start + @cur_start).
        amp(note.amp + amp_adj)
    end

	@cur_start += phrase.dur
    
    @score.append_score(set_phrase_player(phrase))
  end

=begin RDoc
Helper for Ensemble to test the max amp value of any note in the current phrase being played
by this Player
=end
  def max_amp
    @max_amp
  end

=begin RDoc
Helper for Ensemble to test the min amp value of any note in the current phrase being played
by this Player
=end
  def min_amp
    @min_amp
  end

  # REQS
  # - "IN C is ended in this way, when each performer arrives at figure No.53 ...
  # /REQS
=begin RDoc
Tests whether this Player is on the final phrase in the prhases all are playing.  Used by
Ensemble to trigger move to the Conclusion.
=end
  def last_phrase?
    # TEMP DEBUG
    #puts "pid #{@pid}"
    #puts "@phrases_idx  = #{@phrases_idx}"
    #puts "@phrases.length - 1  = #{@phrases.length - 1}"
    
    @phrases == nil or 
	@phrases_idx == @phrases.length - 1 or
	@phrases.length == 0
  end

  #
  # Player internal Helpers
  private
  
  def set_phrase_player(phrase)
    phrase.each {|note| note.player_id(@pid)}
    phrase
  end
  
  # REQ
  # - "... performers should stay within 2 or 3 patterns of each other."
  # /REQ
=begin RDoc
Predicate to implement composition rule. Probability and thus behavior modified by conf params  
=end
  def phrases_idx_too_far_behind?
    @ensemble.max_phrases_idx - @phrases_idx >= @ensemble.phrases_idx_range_threshold
  end

  # REQ
  # - "The group should aim to merge into a unison at least once or twice during the performance."
  # /REQ
=begin RDoc
Predicate to implement composition rule. Probability and thus behavior modified by conf params  
=end
  def seeking_unison?
    @ensemble.seeking_unison? and test_rnd < @unison_prob_factor
  end

  # REQS
  # - "... performers should stay within 2 or 3 patterns of each other."
  # /REQS
=begin RDoc
Predicate to implement composition rule. Probability and thus behavior modified by conf params  
=end
  def advance_phrases_idx?
    phrases_idx_too_far_behind? or test_rnd < @phrase_adv_prob_factor
  end

  # REQS
  # - "... performers should stay within 2 or 3 patterns of each other."
  # /REQS
=begin RDoc
Predicate to implement composition rule. Probability and thus behavior modified by conf params  
=end
  def rest?
    # More likely to stay at rest if already at rest -- "listening"
    rest_prob = (@rest_prob_factor * (@at_rest ? @stay_at_rest_prob_factor : 1)).to_i	
	@at_rest = (test_rnd < rest_prob)
    @at_rest
  end

  # REQS
  # - "Each pattern can be played in unison or canonically in any alignment with itself or
  # with its neighboring patterns."
  # - " ...if the players seem to be consistently too much in the same alignment
  # of a pattern, they should try shifting their alignment by an eighth note
  # or quarter note
  # /REQS
=begin RDoc
Predicate to implement composition rule. Probability and thus behavior modified by conf params  
=end
  def adj_phase?
    test_rnd < @adj_phase_prob_factor
  end

  # REQS
  # - "As an ensemble, it is very desirable to play very softly as well as very
  # loudly and to try to diminuendo and crescendo together."
  # REQS
=begin RDoc
Predicate to implement composition rule. Probability and thus behavior modified by conf params  
=end
  def amp_adj(phrase)
    min_phrase_amp, max_phrase_amp = min_max_phrase_amp phrase

    # Calculate a ratio for this phrase's max amp vs. all in the ensemble
    # If within range up or down we'll adjust amp up or down
	ensemble_max_amp = (@ensemble.max_player_amp == 0 ? 1 : @ensemble.max_player_amp)
    amp_ratio = max_phrase_amp / ensemble_max_amp

    # Do we adjust the volume?
    ret = 1.0
    if seeking_crescendo? and amp_ratio <= @amp_adj_crescendo_ratio_threshold
      ret = @amp_crescendo_adj_factor
    elsif seeking_diminuendo? and amp_ratio >= @amp_adj_diminuendo_ratio_threshold
      ret = @amp_diminuendo_adj_factor
    end
    
    # TEMP DEBUG
    # puts "amp_adj != 1.0, amp_ratio #{amp_ratio}"\
    #  if seeking_crescendo? and amp_ratio <= @amp_adj_crescendo_ratio_threshold
    
    ret
  end

=begin RDoc
Predicate to implement composition rule. Probability and thus behavior modified by conf params  
=end
  def seeking_crescendo?
    @ensemble.seeking_crescendo? and test_rnd < @crescendo_prob_factor
  end

=begin RDoc
Predicate to implement composition rule. Probability and thus behavior modified by conf params  
=end
  def seeking_diminuendo?
    @ensemble.seeking_diminuendo? and test_rnd < @diminuendo_prob_factor
  end
  
=begin RDoc
Helper for Ensemble, returns tuple of min and max amps for any of the notes in a phrase
TODO should be a Class method, since it's a generic helper on arg passed in
and not about this object's state
=end
  def min_max_phrase_amp(phrase)
    amps = phrase.attr_slice(:amplitude)
    return amps.min, amps.max
  end

  # REQS
  # - "It is OK to transpose patterns by an octave, especially to transpose up."
  # /REQS
  SHIFT_DOWN_ONE_OCTAVE = -1.0
  SHIFT_UP_ONE_OCTAVE = 1.0
  NO_SHIFT = 0.0
=begin RDoc
Implements response to a composition rule. Probability and thus behavior modified by conf params.
Response value of implementation also modified by conf params  
=end
  def transpose_shift(phrase)	
    shift = NO_SHIFT
	
	if test_rnd < @transpose_prob_factor
      # Get back slice of dur attrs across all Notes in phrase and pass to
      #  inject which coalesces the block over the list, passing return of
      #  each yield to the next call.  e.g. - [1,2,3].inject {|x,y| x+y} == 6
      durs = phrase.attr_slice(:dur)
      len = durs.length	  
	  mean_dur = durs.inject {|x,y| x+y} / len
	  
      # REQS
      # - "Transposing down by octaves works best on the patterns containing notes of long durations."
      # REQS
      shift = @transpose_shift *
        ((test_rnd < @transpose_down_prob_factor and 
		  mean_dur >= @transpose_down_dur_threshold) ? 
		 SHIFT_DOWN_ONE_OCTAVE : SHIFT_UP_ONE_OCTAVE)
    end

    shift
  end

  # TODO UNIT TEST
  # To support sort! of Players used by Ensemble
  def <=>(rhs)
    self.equal?(rhs) ? 0 : -1
  end

end

=begin RDoc
Class models an Ensemble of Players realizing an aleatoric composition.  Some of the properties
and methods are general, and some are specific to the score for "In C."
=end
class Ensemble
  include In_C
  
  # Allow override of test_rnd, otherwise can't get deterministic results
  #  and so can't really unit test a lot of the class
  # Two calls, one to force test_rnd to always return 0, other to force it to always return 1
  # Of course you could argue that these also allow users to override random behavior of an object
  #  and force it meet conditions, which is true as soon as it's better documented
  # TODO document how to use these methods
  # TODO figure out whether proper mocking in unit tests means I don't need this
  @override_tst_rnd_min = false
  def toggle_override_tst_rnd_min
    @override_tst_rnd_min = ! @override_tst_rnd_min
  end
  @override_tst_rnd_max = false
  def toggle_override_tst_rnd_max
    @override_tst_rnd_max = ! @override_tst_rnd_max
  end
  
  # Helper used by the predicate functions to test probability in nice, readable "100%" form
  RND_RNG = 100
  def test_rnd
    if @override_tst_rnd_min
	  0
	elsif @override_tst_rnd_max
	  RND_RNG
	else
      rand(RND_RNG)
	end
  end
  
  attr_accessor :phrases_idx_range_threshold,
                :unison_count, :unison_desired_count, :unison_prob_factor,
                :max_phrases_idx_range_for_seeking_unison,
                :max_amp_range_for_seeking_crescendo,
                :max_amp_range_for_seeking_diminuendo,
                :crescendo_prob_factor, :diminuendo_prob_factor

=begin RDoc
ctor
=end
  def initialize(players)
    @players = players
    # See globals.rb for explanation of this global (I apologize :-) )
    $NUM_PLAYERS = @players.length
    # Callback each Player to register this Ensemble with them
    @players.each {|player| player.join_ensemble self}
    # To hold dynamically added optional attributes
    @opt_attrs = Hash.new
    # Controls check for increasing prob of getting all players in unison
    @unison_count = 0
    @unison_desired_count = players.length
    
    @conclusion_bound = players[0].phrases_length - 1
    @reached_conclusion = false
    
    @perform_steps_count = 0
    
    load_config
  end
  
  private
=begin RDoc
See ensemble.yml for tunable parameters which are loaded here as object variables.
=end  
  def load_config
    # Load config and set instance variables from each Player entry
    conf = YAML.load_file("ensemble.yml")
    conf["ensemble"].each {|k,v| instance_variable_set("@#{k}", v)}  
  end
  public

=begin RDoc
Collect as a list the values of a Player property, from each Player, a slice of the Player data by "column"
=end
  def max_phrases_idx
    players_attr_slice(:phrases_idx).max
  end

=begin RDoc
Collect as a list the values of a Player property, from each Player, a slice of the Player data by "column"
=end
  def max_player_amp
    players_attr_slice(:max_amp).max
  end

=begin RDoc
Collect as a list the values of a Player property, from each Player, a slice of the Player data by "column"
=end
  def min_player_amp
    players_attr_slice(:max_amp).min
  end

=begin RDoc
Collect as a list the values of a Player property, from each Player, a slice of the Player data by "column"
=end
  def seeking_unison?
    not has_reached_unison_count? and
     (phrases_idx_range <= @max_phrases_idx_range_for_seeking_unison and
      test_rnd < @unison_prob_factor)
  end

=begin RDoc
Collect as a list the values of a Player property, from each Player, a slice of the Player data by "column"
=end
  def seeking_crescendo?
    amp_range < @max_amp_range_for_seeking_crescendo and test_rnd < @crescendo_prob_factor
      # (@reached_conclusion or test_rnd < @crescendo_prob_factor)
  end

=begin RDoc
Collect as a list the values of a Player property, from each Player, a slice of the Player data by "column"
=end
  def seeking_diminuendo?
    amp_range < @max_amp_range_for_seeking_diminuendo and test_rnd < @diminuendo_prob_factor
      # (@reached_conclusion or test_rnd < @diminuendo_prob_factor)
  end

=begin RDoc
Collect as a list the values of a Player property, from each Player, a slice of the Player data by "column"
Gate on adjusting a player's phrase index
=end
  def unison_phrase_idx_adj(player)
    ((player.phrases_idx >= max_phrases_idx) and not (player.phrases_idx == 0)) ? 0 : 1
  end

=begin RDoc
Lets Player or any client add new attributes at runtime. Add optional attribute
=end
  def add_opt_attr(attr, &attr_handler)
    @opt_attrs[attr.to_sym] = attr_handler
  end

=begin RDoc
Main drier of the application, this iterates again and agaon over all the Players in the
Ensemble, and asks each to consider playinga  phrase, i.e. for each Player on each loop
it calls player.play_phrase().  The latter has the logic to determine what that Player plays,
and that gets written to the output score.  This loop holds only the logic to check
for whether all players have reached the last phrase. At that point the program exits here
and calls perform_conclusion
=end
  def perform
    @reached_conclusion = false
    while not reached_conclusion?
      @players.each do |player|
        # If all Players are on same phrase index, increment unison count, used by seeking_unison?     
        players_attr_slice(:phrases_idx).all_items_equal? ? @unison_count += 1 : @unison_count = 0
        player.play_phrase
	  end      
      # Count the number of times the Ensemble iterates, for perform_conclusion()
      @perform_steps_count += 1

      # TEMP DEBUG
      puts "perform() step #{@perform_steps_count}" if @perform_steps_count % 20 == 0     
    end
    
    # TEMP DEBUG
    puts "performed #{@perform_steps_count} steps in perform()"    
    
    perform_conclusion    
  end

  private

  # REQS
  # - "IN C is ended in this way, when each performer arrives at figure No.53 ...
  # /REQS
=begin RDoc
Fulfills requirement to handle final coda crescendo/decrescendo, which has different logic
than the loops prior to conclusion  
=end
  def perform_conclusion

    # TEMP DEBUG
    puts "perform_conclusion()"
  
    # For each Player, have it output playing the final phrase for as long as it needs to 
    #  to catch up to the Player at max_start_time
    # Get current phrase of any player because all are on the last phrase
    last_phrase_length = @players[0].cur_phrase.duration
    # Get the start time past current latest start time so all crescendo notes start after that
    max_start = players_attr_slice(:cur_start).max
    
    # TEMP DEBUG
    puts "play conclusion phrases until all Players catch up"
    j = 1

    amp_adj = 0
    @players.each do |player|
      num_plays_last_phrase = ((max_start - player.cur_start) / last_phrase_length).floor    
      num_plays_last_phrase.times do 
        
        # TEMP DEBUG
        # puts "player pid #{player.pid}, player.cur_start #{player.cur_start} phrase loop # #{j}"
        j += 1
        
        player.play_conclusion_phrase amp_adj
      end
    end
    
    # TEMP DEBUG
    puts "played #{j} conclusion phrases"

    # Calculate the number of steps * a fraction of 1 to determine the length of the conclusion
    #  crescendo as a ratio of length of the whole performance
    num_crescendo_steps = (@perform_steps_count * @conclusion_steps_ratio).ceil    
    # Split the max allowed increase in amp for a crescendo evenly among the steps of the crescendo
    amp_adj = (@max_amp_range_for_seeking_crescendo / num_crescendo_steps).floor
        
    # TEMP DEBUG
    #adjusted_starts = []

    # TEMP DEBUG
    puts "reset Players' start time"

    max_start = players_attr_slice(:cur_start).max    
    @players.each do |p| 
      
      # TEMP DEBUG
      #puts "p.cur_start #{p.cur_start}"
      #puts "max_start #{max_start}"
      #puts "p.cur_start adjusted #{p.cur_start + ((max_start - p.cur_start) * @conclusion_cur_start_offset_factor)}"
      # adjusted_starts.push(p.cur_start + ((max_start - p.cur_start) * @conclusion_cur_start_offset_factor))
      
      # See ensemble.yml for explanation of @conclusion_cur_start_offset_factor.
      # Basically this gives each player a slightly offset start time for starting it's conclustion
      #  crescendo/descrescendo
      p.cur_start = p.cur_start + ((max_start - p.cur_start) * @conclusion_cur_start_offset_factor)
    end
    
    # TEMP DEBUG
    # puts "Number of crescendo steps #{num_crescendo_steps}"    
    # puts "Max adjusted crescendo start time #{adjusted_starts.max}"
    # puts "Min adjusted crescendo start time #{adjusted_starts.min}"
    # puts "adjusted crescendo start time variance #{adjusted_starts.max - adjusted_starts.min}"
    
    # TEMP DEBUG
    puts "crescendo"

    # Walk half the steps and crescendo
    cur_amp_adj = amp_adj
    j = 0
    num_crescendo_steps.times do     
      @players.each {|p| p.play_conclusion_phrase(cur_amp_adj)}
      cur_amp_adj += amp_adj
    end

    # TEMP DEBUG
    puts "decrescendo"

    # Walk the other half of the steps and descrescendo
    cur_amp_adj -= amp_adj
    # num_crescendo_steps.times do
    num_crescendo_steps.times do
      @players.each {|p| p.play_conclusion_phrase(cur_amp_adj)}
      cur_amp_adj -= amp_adj
    end  
  end
  
=begin RDoc
Predicate to implement composition rule. Probability and thus behavior modified by conf params  
=end
  def has_reached_unison_count?  
    (@unison_count / @unison_desired_count).to_f >= 1.0
  end

=begin RDoc
Colllect as a list the min and max phrase index for all Players
=end
  def phrases_idx_range
    phrases_idxs = players_attr_slice(:phrases_idx)
    phrases_idxs.max - phrases_idxs.min
  end

=begin RDoc
Predicate to implement composition rule. Probability and thus behavior modified by conf params.
This one triggers the Ensemble to play the Conclusion
=end
  def reached_conclusion?
    phrases_idxs = players_attr_slice(:phrases_idx)         
    @reached_conclusion = (phrases_idxs.min == @conclusion_bound and 
	                       phrases_idxs.max == @conclusion_bound)                           
    @reached_conclusion
  end

=begin RDoc
Delta between min amp of any note in any players phrase, and max
=end
  def amp_range
    max_player_amp - min_player_amp
  end

=begin RDoc
Slicer for collecting a list of all values for a Player attr, for all Players. Takes the property
to be colected as a symbol, which is then sent to all the Players
=end
  def players_attr_slice(attr)
    @players.collect {|player| player.send(attr.to_sym)}
  end

end

end
