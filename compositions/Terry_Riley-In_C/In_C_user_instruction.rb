#!/usr/bin/env ruby

# BOILERPLATE FOR ALL user_instruction.rb FILES
# for calling sign(), swing(), swing?() no_swing(), meets_condition?()
$LOAD_PATH << "../../lib"
require 'composer'
require 'util' 
include Aleatoric
# /BOILERPLATE FOR ALL user_instruction.rb FILES


# IMPLEMENTATION OF THIS user_instruction.rb

# *************************
# Player State Management
# These values govern the behavior of each Player
PLAYER_SETTINGS = {
  "num_phrases" => 53,
  # The most important factor governing advance of Players through phrases, this is simply
  #  the percentage prob that they advance on any given iteration  
  "phrase_advance_prob" => 0.28, 
  
  # Player Phrase Phase 
  # Tunable parms for shifting playing of current phrase out of its current
  #  phase, and also to shift it more in alignment.  Shift simple pre-pends
  #  a rest Note to current phrase before writing it to Score.  Supports
  #  score directive to adjust phase, and another to move in and out of phase
  #  during a performance
  # Percentage prob that a Player will adjust phase on any given iteration
  "adj_phase_prob_factor" => 0.07,
  # Supports Instruction that Player this is too often in alignment should favor
  #  trying to be out of phase a bit more. If Player hasn't adjusted phase
  #  this many times or more, then adj_phase_prob_increase_factor will be applied
  "adj_phase_count_threshold" => 1,
  "adj_phase_prob_increase_factor" => 2.0,
  # The length of the rest Note (in seconds) inserted if a Player is adjusting its phase  
  "phase_adj_dur" => 0.55,
  # Prob that a Player will seek unison on any given iteration.  The idea is that
  #  to seek unison the Ensemble and all the Players must seek unison  
  "unison_prob_factor" => 0.95,
  
  # Player Rest/Play
  # Tunable parms for probability that Player will rest rather than playing a note.
  # Supports score directive to listen as well as play and not always play
  # Prob that a Player will try to rest on a given iteration (not play)
  "rest_prob_factor" => 0.1,  
  # Factor multiplied by rest_prob_factor if the Player is already at rest  
  "stay_at_rest_prob_factor" => 1.5,
  
  # Player Volume Adjusment, De/Crescendo
  # Tunable parms for adjusting volume up and down, and prob of making
  #  an amp adjustment. Supports score directive to have crescendos and
  #  decrescendos in the performance  
  # Threshold for the ratio of this Players average amp for its current phrase
  #  to the max average amp among all the Players. Ratio above/below this means the Player
  #  will raise/lower its amp by amp_de/crescendo_adj_factor    
  "amp_adj_crescendo_ratio_threshold" => 0.8,
  "amp_crescendo_adj_factor" => 1.1,
  "amp_adj_diminuendo_ratio_threshold" => 1.2,
  "amp_diminuendo_adj_factor" => 0.9,
  # Prob that a Player is seeking de/crescendo  
  "crescendo_prob_factor" => 0.5,
  "diminuendo_prob_factor" => 0.5,
  
  # Player Transpose
  # Tunable parms for transposing the playing of a phrase.  Suppports score directive
  #  to transpose as desired.
  # Prob that a Player will seek to transpose its current phrase
  "transpose_prob_factor" => 0.2,
  # Number of octaves to transpose if the Player does do so
  # Amount that represents an octave in backend being used to render notes (1.0 in CSound, 12 in MIDI)
  "transpose_shift" => 1.0, 
  # Sadly, we need this also, because CSound is float type and MIDI is int type (0.0 or 0)
  "transpose_no_shift" => 0.0,
  # Factor for shift down, likewise (1.0 in CSound, 1 in MIDI)
  "transpose_shift_down_factor" => -1.0,
  # Factor for shift up, likewise (1.0 in CSound, 1 in MIDI)
  "transpose_shift_up_factor" => 1.0,  
  # From the Instructions: "Transposing down by octaves works best on the patterns containing notes of long durations."
  # Minimum average duration of notes in a phrase for that phrase to be more likely
  #  to transpose down rather than up
  "transpose_down_prob_factor" => 0.5,
  # Minimum average duration of notes in a phrase for that phrase to be more likely
  #  to transpose down rather than up  
  "transpose_down_dur_threshold" => 2.0,
  
  # Misc
  # Give notes a bit of variance in start time and duration. If not overdone 
  #  gives a more human feel.  A tiny bit goes a long, long way ...
  # Use standard Aleatoric implementation in lib/util.rb
  # swing(base_val, num_steps, swing_step)
  #  returns a factor to multiply note.duration and note.start by
  #  base_val - the smallest possible swing factor
  #  num_steps - the number of values incremented up from the base_val
  #  swing_step - the size of each step value increment
  # So, example: swing(0.98, 5, 0.01) -> swing range with the discrete values [0.98, 0.99, 1.0, 1.01, 1.02]
  "swing_base_val" => 0.999,
  "swing_num_steps" => 3,
  "swing_step_size" => 0.001,
  
  # Convenience for In_C_Players
  "num_phrases" => 53
}


# Ensemble State Management
# These values govern the behavior of the Ensemble
ENSEMBLE_SETTINGS = {
  "num_players" => 12,
  # Threshold number of phrases behind the furthest ahead any Player is allowed to slip.
  # If they are more than 3 behind the leader, they must advance.     
  "phrases_idx_range_threshold" => 3,
  # Prob that the Ensemble will seek to have all Players play the same phrase
  #  on any one iteration through the Players  
  "unison_prob_factor" => 0.2,
  # Threshold number of phrases apart within which all players 
  #  must be for Ensemble to seek unison
  "max_phrases_idx_range_for_seeking_unison" => 3,
  # Probability that the ensemble will de/crescendo in a unison (may be buggy)
  # TODO: bug is that code to build up crescendo over successive iterations isn't there
  #  and instead this just jumps the amplitude jarringly on one iteration
  "crescendo_prob_factor"=> 0.0,
  "diminuendo_prob_factor"=> 0.0,
  # Maximum de/increase in volume (in CSound scale) that notes can gain in crescendo 
  #  pursued during a unison or in the final Conclusion
  "max_amp_range_for_seeking_crescendo" => 1000,
  "max_amp_range_for_seeking_diminuendo" => 1200,
  # Parameters governing the Conclusion
  # This is the ratio of steps in the Conclusion to the total steps before the Conclusion  
  "conclusion_steps_ratio" => 0.1,
  # This extends the duration of the repetition of the last phrase
  #  curing the final coda.  At the start of the coda each player
  #  has its start time pushed ahead to be closer to the maximum
  #  so that they arrive at the end closer together.  This factor offsets the Player from
  #  repeating the last phrase until exactly reaching the Conclusion  
  "conclusion_cur_start_offset_factor" => 0.05,
  # Maximum number of crescendo and decrescendo steps in the conclusion, supporting the 
  #  Instruction indicating ensemble should de/crescendo "several times"
  "max_number_concluding_crescendos" => 4
}
# *************************

# *************************
# Manages the state associated with each Player
class In_C_Player
  include Aleatoric
  
  attr_reader :ensemble, :handle, 
              :num_phrases, :phrases_idx, :adj_phase_count, :at_rest, 
              :swing_range_max_factor, :swing_range_min_factor, :swing_factor_range

  def initialize(ensemble, num_phrases, handle)    
    @ensemble = ensemble
    @num_phrases = num_phrases
    @handle = handle
    # Offset into @phrases that this player is currently playing
    @phrases_idx = 0
    @cur_start = 0.0
    # Count of how many times Player has adjusted phase, to support testing against
    #  adj_phase_count_threshold to apply adj_phase_prob_increase_factor in adj_phase?
    @adj_phase_count = 0
    # Indicator that the Player is at rest
    @at_rest = false        
  end
    
  # Player Public API
  # This is what the Instruction handlers call to control each Player on each call to play() in the Composer score
  # Some methods public also so In_C_Ensemble can call them
  public

  def phrases_index
    @phrases_idx
  end

  # Used by Ensemble to test if all phrases have reached the last phrase
  def reached_last_phrase?
    # TODO This should be ==, >= is a relic of a bug and trying to defend against it
    @phrases_idx >= @num_phrases
  end
  
  # Instruction 3
  # NOTE: Instruction 5 and Instruction 6 grouped with this. They can also advance the player to next phrase
  #  but since there is an Instruction that players must play all phrases must not advance twice in one play() iteration
  def play_next_phrase?    
    @has_advanced = (self.reached_last_phrase? ? false : advance_phrases_idx?)    
    @phrases_idx += 1 if @has_advanced        
    @has_advanced
  end
  
  # Instruction 5, grouped with Instruction 3
  def play_next_phrase_too_far_behind?
    ret = false
    if not (@has_advanced or reached_last_phrase?)
      ret = phrases_idx_too_far_behind? 
      @has_advanced = ret
      @phrases_idx += 1 if ret
    end
    ret 
  end
  
  # Instruction 6, grouped with Instructions 5 and 6
  def play_next_phrase_seeking_unison?
    ret = false
    if not (@has_advanced or reached_last_phrase?)
      ret = seeking_unison? 
      @has_advanced = ret
      @phrases_idx += 1 if ret
    end    
    ret
  end

  # PREPLAY bool, return whether or not to have Player rest for this iteration
  def rest?
    # More likely to stay at rest if already at rest -- the Player is "listening"
    stay_at_rest_factor = @at_rest ? @stay_at_rest_prob_factor : NO_FACTOR
    meets_condition?(@rest_prob_factor * stay_at_rest_factor)
  end

  # PREPLAY note.start(note.start - @phase_adj_dur), phrase.insert_note(0, CSnd::Note.rest(note, @phase_adj_dur, @pid))  
  def phase_adj
    adj_phase? ? @phase_adj_dur : 0.0      
  end

  # REQS
  # - "As an ensemble, it is very desirable to play very softly as well as very
  # loudly and to try to diminuendo and crescendo together."
  # REQS
  # PREPLAY, arg = container.cur_phrase, 
  # PREPLAY, return = amount to multiply all note amps in container.cur_phrase, phrase.each {|note| note.amp((note.amp * adj).to_i)}  
  def amp_adj_factor(phrase)
    # Calculate a ratio for this phrase's max amp vs. all in the ensemble
    # If within range up or down we'll adjust amp up or down
    ensemble_max_amp = @ensemble.max_player_amp 
    ensemble_max_amp = 1 if ensemble_max_amp == 0
    amp_ratio = max_amp(phrase).to_f / ensemble_max_amp.to_f

    # Do we adjust the volume?
    if seeking_crescendo? and amp_ratio <= @amp_adj_crescendo_ratio_threshold
      @amp_crescendo_adj_factor
    elsif seeking_diminuendo? and amp_ratio >= @amp_adj_diminuendo_ratio_threshold
      @amp_diminuendo_adj_factor
    else
      NO_FACTOR
    end
  end
  
  # PREPLAY, arg = container.cur_phrase
  def min_amp(phrase)
    phrase.attr_slice(:amplitude).min
  end
  
  # PREPLAY, arg = container.cur_phrase
  def max_amp(phrase)
    phrase.attr_slice(:amplitude).max
  end  

  # PREPLAY, arg = container.cur_phrase, return = amount to shift all notes in current phrase by, by adding to pitch of each note
  def transpose_shift(phrase)	
    shift = @transpose_no_shift

    if meets_condition?(@transpose_prob_factor)
      # Figure out if we shift up or down, it depends on the length of notes in the phrase ...
      # ... so get mean length of all notes in current phrase ...
      durations = phrase.attr_slice(:duration)
      
      # NOTE: Extending module Array with #sum() only works for code within
      #  module Aleatoric, apparently, not code that includes it, such as here
      # Note also that module-level free methods from util.rb, where #sum() is
      #  can be called here.
      # mean_dur = durations.sum / durations.length
      dur_sum = durations.inject(0) {|sum, x| sum + x}
      mean_dur = dur_sum / durations.length
      
      # ... and test it against the threshold for favoring down transpose
      if meets_condition?(@transpose_down_prob_factor) and mean_dur >= @transpose_down_dur_threshold
        shift = @transpose_shift * @transpose_shift_down_factor
      else
        shift = @transpose_shift * @transpose_shift_up_factor
      end
    end

    shift
  end

  # PREPLAY, returns tuple of factor to multiply by note start time and factor to multiply by note duration
  # NOTE: Instruction handler can decide to call this for each note in container.cur_phrase individually, or apply one
  #  swing value to all notes in cur_phrase.  Former should be more "realistic" but hearing is believing
  def swing_adj
    if swing?(@swing_base_val, @swing_num_steps) then
      # swing(base_val, num_steps, swing_step)
      #  base_val - the smallest possible swing factor
      #  num_steps - the number of values incremented up from the base_val
      #  swing_step - the size of each step value increment
      # For example swing(0.98, 5, 0.01) returns one of five values [0.98, 0.99, 1.0, 1.01, 1.02]
      start_swing = swing(@swing_base_val, @swing_num_steps, @swing_step_size) * sign
      dur_swing =  swing(@swing_base_val, @swing_num_steps, @swing_step_size) * sign
      return start_swing, dur_swing
    else
      return no_swing, no_swing
    end
  end
  
  def align_last_phrase_start
    last_phrase_length = @phrases[@num_phrases-1].duration
    # Get the start time past current latest start time so all crescendo notes start after that
    max_start = players_attr_slice(:cur_start).max
    amp_adj = 0
    @players.each do |player|
      num_plays_last_phrase = ((max_start - player.cur_start) / last_phrase_length).floor    
      num_plays_last_phrase.times do 
        player.play_conclusion_phrase amp_adj
      end
    end  
  end
  
  # NOTE: Had to make this public and called after initialize() returned
  # When it was called by initialize() the methods were not dynamically added
  def def_accessors 
    PLAYER_SETTINGS.each do |k,v|     
      self.instance_eval "@#{k} = #{v}"
      self.class_eval("def #{k}\n@#{k}\nend")
    end
    # Derived from settings loaded in def_accessors()
    @swing_factor_range = @swing_range_max_factor - @swing_range_min_factors
  end
    
  # Helpers
  private

  def advance_phrases_idx?
    meets_condition? @phrase_advance_prob
  end

  def phrases_idx_too_far_behind?
    @ensemble.phrases_idx_too_far_behind?(@phrases_idx)
  end

  def seeking_unison?
    @ensemble.seeking_unison? and meets_condition?(@unison_prob_factor)
  end

  def seeking_crescendo?
    @ensemble.seeking_crescendo? and meets_condition?(@crescendo_prob_factor)
  end

  def seeking_diminuendo?
    @ensemble.seeking_diminuendo? and  meets_condition?(@diminuendo_prob_factor)
  end
  
  def adj_phase?    
    adj_phase_prob_factor = @adj_phase_prob_factor
    adj_phase_prob_factor *= @adj_phase_prob_increase_factor if @adj_phase_count <= @adj_phase_count_threshold
    adj_phase = meets_condition?(adj_phase_prob_factor)
    @adj_phase_count += 1 if adj_phase
    adj_phase
  end      
end
# *************************

# *************************
# Manages the state associated with the Ensemble
class In_C_Ensemble
  include Aleatoric
    
  attr_reader     :name, :num_players, :num_phrases, :unison_count, :players
  attr_writer     :reached_conclusion
  @@al_players = {}
  @@in_c_ensemble = nil

  def initialize(name, handle)
    @name = name
    # The unique Id of the Composer Ensemble that this class is "shadowing"
    #  that is, managing state to implement the Instructions and then
    #  use the Composer API in the Instruction handlers to affect the Composer Ensemble
    @handle = handle
    @players = []
    @num_players = 0
    @num_phrases = PLAYER_SETTINGS["num_phrases"]
    # Controls check for increasing prob of getting all players in unison
    @unison_count = 0
    @perform_steps_count = 0
    @reached_conclusion = false
  end

  # Ensemble Public API
  # This is what pre/post handlers call to get/set Ensemble state on each call to play() in Composer script
  # Also methods are public if In_C_Players need to call them
  public
  
  def players=(players)
    @players = players.values
    @num_players = players.length
    # Controls whether all Players have reached last phrase and conclusion should begin
  end
  
  ## Player Phrase Position Management Methods
  def max_phrases_idx    
    players_phrases_idxs.max
  end
  
  def min_phrases_idx
    players_phrases_idxs.min
  end  
  
  def phrases_idx_too_far_behind?(phrases_idx)
    max_phrases_idx - phrases_idx >= @phrases_idx_range_threshold    
  end
  # /Player Phrase Position Management Methods
  
  ## Unison methods  
  def seeking_unison?
    not reached_unison? and
    players_phrases_idx_range <= @max_phrases_idx_range_for_seeking_unison and
      meets_condition?(@unison_prob_factor)
  end  
  ## /Unison methods

  ## Player Amp methods
  # Public because In_C_Player needs to call it
  def max_player_amp    
    (@players.collect {|p| p.max_amp(@@al_players[p.handle].current_phrase)}).max
  end
  ## /Player Amp methods

  ## Player De/Crescendo methods
  # Both of these are called by In_C_Player
  def seeking_crescendo?
    amp_range < @max_amp_range_for_seeking_crescendo and 
     meets_condition?(@crescendo_prob_factor)
  end

  def seeking_diminuendo?
    amp_range < @max_amp_range_for_seeking_diminuendo and 
     meets_condition?(@diminuendo_prob_factor)
  end
  ## Player De/Crescendo methods

  ## Performance Conclusion methods
  ## Test whether all Players have reached last phrase
  def reached_concluding_unison?
    # So client code doesn't have to check every Player over hundreds of iterations once Ensemble reaches conlcusion phase
    # Once in conclusion phase can't exit it, so just set and test this once
    if not @reached_concluding_unison
      @players.each do |player|
        if not player.reached_last_phrase?
          @reached_concluding_unison = false
          return @reached_concluding_unison
        end        
      end
    end
    @reached_concluding_unison = true
    @reached_concluding_unison                           
  end
  
  # Set by Instruction 14 Postplay Handler when it enters the block to have the players
  #  play the final crescendos after they have all reached unison.
  # repeat_until() handler checks its handler, which checks this flag, on every iteration
  def reached_conclusion?
    @reached_conclusion
  end
  
  # NOTE: Had to make this public and called after initialize() returned
  # When it was called by initialize() the methods were not dynamically added
  def def_accessors     
    ENSEMBLE_SETTINGS.each do |k,v|
      self.instance_eval "@#{k} = #{v}"
      self.class_eval("def #{k}\n@#{k}\nend")      
    end
  end  
    
  # Helpers
  private

  def reached_unison?
    @unison_count >= @num_players
  end
    
  def min_player_amp
    (@players.collect {|p| p.max_amp(@@al_players[p.handle].current_phrase)}).max
  end

  def amp_range
    max_player_amp - min_player_amp
  end  
    
  # Helper to get Player indexes, since it's called multiple times
  def players_phrases_idxs
    players_attr_slice(:phrases_index) 
  end  

  def players_phrases_idx_range
    idxs = players_phrases_idxs
    idxs.max - idxs.min
  end

  # Helper to collect a list of all values for a Player attr, for all Players. 
  def players_attr_slice(attr)  
    @players.collect {|player| player.send(attr.to_sym)}
  end
end
# *************************


# *************************
# Register a callback that will be run the first time play() is called
# This is exposed by the API and it passes arrays of all the main entities
#  in Composer to the callback, namely Notes, Scores, Measures, Phrases, Sections, Players, Ensembles
in_c_players = {}
in_c_init_play_handler = lambda do |notes, scores, measures, phrases, sections, players, ensembles|
  # Instantiate In_C_Ensemble and In_C_Players, these are used by the Instruction handlers
  #  to implement the Instructions
  players.each {|player| In_C_Ensemble.al_players[player.handle] = player}
  ensemble_handle = ensembles.first.handle
  player_handles = players.collect {|p| p.handle}
  # Construct with reference to Composer Ensemble object
  In_C_Ensemble.in_c_ensemble = In_C_Ensemble.new("In C Orchestra", ensemble_handle)
  # Call to create accessors from settings  
  In_C_Ensemble.in_c_ensemble.def_accessors
  num_phrases = PLAYER_SETTINGS["num_phrases"]
  ENSEMBLE_SETTINGS["num_players"].times do |j|
    player = In_C_Player.new(In_C_Ensemble.in_c_ensemble, num_phrases, player_handles[j])
    player.def_accessors
    # Reverse key mapping of Composer Player handle to this shadowing In_C_Player
    in_c_players[player_handles[j]] = player  
  end
  In_C_Ensemble.in_c_ensemble.players = in_c_players  
end
set_play_init_handler("in_c_init_play_handler", &in_c_init_play_handler)
# *************************


# *************************
# Composer Instruction and 'repeat until' Implementation
# This uses the above classes to manage state of the In_C_Players and In_C_Ensemble, to encapsulate all the
#  predicates and computations that determine what actions each Player takes on each iteration of play().
#  Here we apply the changes based on using these classes to the actual Composer Players and Ensemble, in the
#  pre- and post-play handlers, access the Composer Players and Ensemble through the handler 'container' argument,
#  and then using the nice Composer Player() and Ensemble() public methods as our API to change what each Player plays
# We could do all the state management and logic by using the set_state()/get_state Composer API, but that works better
#  for simpler rules and fewer of them.  It's nice to have an OO setup visible here to implement a composition as
#  complex as this.  Of course this means extra work to plug into Composer API calls here, but we get the rest
#  of Composer by doing this (executable and human-readable musical score, generating/rendering output)

# No Op Instructions
# No operation instructions.  These are either implicitly satisfied by the
#  overall solution, instructions to a live orchestra of humans, or general
#  directions that don't actually describe any constraints to be satisfied.

# "All performers play from the same page of 53 melodic patterns played in sequence."
instruction_1 = lambda do |container, score|
  # no_op
  score
end
set_player_preplay_instruction("Instruction 1", &instruction_1)

# "Any number of any kind of instruments can play.  A group of about 35 is desired if possible but smaller or larger groups will work.  If vocalist(s) join in they can use any vowel and consonant sounds they like."
instruction_2 = lambda do |container, score|
  # no_op
  score
end
set_player_preplay_instruction("Instruction 2", &instruction_2)

# Well, these performers can play at any tempo, so ignore this restriction. It might be interesting to hear this 
#  performed at a glacially slow pace
# "The tempo is left to the discretion of the performers, obviously not too slow, but not faster than performers can comfortably play."
instruction_8 = lambda do |container, score|
  # no_op
  score
end
set_player_preplay_instruction("Instruction 8", &instruction_8)

# "If for some reason a pattern can’t be played, the performer should omit it and go on."
instruction_12 = lambda do |container, score|
  # no_op
  score
end
set_player_preplay_instruction("Instruction 12", &instruction_12)

# "Instruments can be amplified if desired.  Electronic keyboards are welcome also."
instruction_13 = lambda do |container, score|
  # no_op
  score
end
set_player_preplay_instruction("Instruction 13", &instruction_13)


# *************************
# Instructions

# "Patterns are to be played consecutively with each performer having the freedom to determine how many 
#  times he or she will repeat each pattern before moving on to the next.  There is no fixed rule 
#  as to the number of repetitions a pattern may have, however, since performances normally average 
#  between 45 minutes and an hour and a half, it can be assumed that one would repeat each pattern 
#  from somewhere between 45 seconds and a minute and a half or longer."
instruction_3_player_pre = lambda do |container, score|  
  # In_C_Players stowed in a Hash keyed to the handle() (a unique id) of the Aleatoric Player 
  in_c_player = in_c_players[container.handle]  
  # In_C_Player stores all the state about a player.  Ask if this player is on the last phrase  
  container.increment_scores_index if in_c_player.play_next_phrase?
  score
end
set_player_preplay_instruction("Instruction 3", &instruction_3_player_pre)

# "It is very important that performers listen very carefully to one another and this means occasionally to drop out and listen. ...
#  As an ensemble, it is very desirable to play very softly as well as very loudly and to try to diminuendo and crescendo together."
instruction_4_player_pre = lambda do |container, score|
  in_c_player = in_c_players[container.handle]
  resting = false
  if in_c_player.rest?
    resting = true
    # The player is dropping out to listen, so set all notes in the score to have 0 amp and return the altered score
    score.notes.each {|note| note.volume 0}
  end
  
  # If the player isn't resting, then is playing, so participate with other players to see if all are de/crescendoing together
  if not resting
    volume_adj_factor = in_c_player.amp_adj_factor score
    score.notes.each {|note| note.volume((note.volume * volume_adj_factor).to_i)}
  end
  
  score
end
set_player_preplay_instruction("Instruction 4", &instruction_4_player_pre)

# "Each pattern can be played in unison or canonically in any alignment with itself or with its neighboring patterns.  ..."
instruction_5_player_pre = lambda do |container, score|
  in_c_player = in_c_players[container.handle]
  # In_C_Player manages whether this player is changing its phase, that is its starting position 
  #  in its current phrase to not start at the same time as the last time it played.  
  # This in effect changes its "alignment" in playing relative to the other players
  # Construct the rest Note
  rest_note_dur = in_c_player.phase_adj
  rest_note = Note.new
  rest_note.duration rest_note_dur
  rest_note.volume 0
  rest_note.pitch 5.01 # TODO Why isn't const working? # :C1
  rest_note.func_table 1
  # Shift the start times of all notes following the prepended note, and prepend it
  rest_note.start score.notes.first.start 
  score.notes.each {|note| note.start(note.start + rest_note_dur)}
  score.prepend_note rest_note
  
  score
end
set_player_preplay_instruction("Instruction 5", &instruction_5_player_pre)

#  "... As the performance progresses, performers should stay within 2 or 3 patterns of each other. ..."
instruction_6_player_pre = lambda do |container, score|
  in_c_player = in_c_players[container.handle]
  container.increment_scores_index if in_c_player.play_next_phrase_too_far_behind?
  score
end
set_player_preplay_instruction("Instruction 6", &instruction_6_player_pre)

# "The ensemble can be aided by the means of an eighth note pulse played on the high c’s of the piano or on a mallet instrument.  
# It is also possible to use improvised percussion in strict rhythm (drum set, cymbals, bells, etc.), 
#  if it is carefully done and doesn’t overpower the ensemble.  
# All performers must play strictly in rhythm and it is essential that everyone play each pattern carefully
instruction_7_player_pre = lambda do |container, score|
  # TODO IMPLENENT THIS
  score
end
set_player_preplay_instruction("Instruction 7", &instruction_7_player_pre)

# TODO This *really* could be implemented, but it would be tricky and sophisticated
# It is important to think of patterns periodically so that when you are resting you are conscious of the larger 
#  periodic composite accents that are sounding, and when you re-enter you are aware of what effect your entrance 
#  will have on the music’s flow."
instruction_9_player_pre = lambda do |container, score|
  # no_op
  score
end
set_player_preplay_instruction("Instruction 9", &instruction_9_player_pre)

# "The group should aim to merge into a unison at least once or twice during the performance.  
# At the same time, if the players seem to be consistently too much in the same alignment of a pattern, 
# they should try shifting their alignment by an eighth note or quarter note with what’s going on in the rest of the ensemble."
instruction_10_player_pre = lambda do |container, score|
  in_c_player = in_c_players[container.handle]
  container.increment_scores_index if in_c_player.play_next_phrase_seeking_unison?
  score
end
set_player_preplay_instruction("Instruction 10", &instruction_10_player_pre)

# "It is OK to transpose patterns by an octave, especially to transpose up.  Transposing down by octaves 
# works best on the patterns containing notes of long durations. 
# TODO HOW TO IMPLEMENT THIS PART OF THIS INSTRUCTION Augmentation of rhythmic values can also be effective."
instruction_11_player_pre = lambda do |container, score|
  in_c_player = in_c_players[container.handle]
  shift = in_c_player.transpose_shift(score)
  score.notes.each {|note| note.pitch(note.pitch + shift)}
  score
end
set_player_preplay_instruction("Instruction 11", &instruction_11_player_pre)

# "In C is ended in this way:  when each performer arrives at figure #53, he or she stays on it until the entire ensemble has arrived there.  
# The group then makes a large crescendo and diminuendo a few times and each player drops out as he or she wishes."

# Unfortunately, this relies on state in the Aleatoric objects, specifically the wall time start time of each Player, which
#  is stateful because it built up over every Play call, in the real Player, and it's only there that it knows whether Notes
#  were really added to output and so advanced the actual start time.  So we have implementation here

# ... Now end the piece in this repeat_until Postplay Instruction, the first time the ensemble has reached conclusion
# Just performed all of the conclusion in the Preplay Ensemble handler for this same Instruction
# NOTE REPEAT UNTIL NAME PASSED TO set_repeat_until_stop() *** MUST MATCH ***
#  NAME PASSED TO set_repeat_until_stop_postplay_test()
#j = 0
instruction_14_repeat_until_test_post = lambda do    
  # Violates encapsulation -- needs to know about module scope variable defined above
  # NOTE REPEAT UNTIL NAME PASSED TO set_repeat_until_stop() *** MUST MATCH ***
  #  NAME PASSED TO set_repeat_until_stop_postplay_test()  
  if @@in_c_ensemble.reached_conclusion?
    set_repeat_until_stop "... each player drops out as he or she wishes."
  end
end
# NOTE REPEAT UNTIL NAME PASSED TO set_repeat_until_stop() *** MUST MATCH ***
#  NAME PASSED TO set_repeat_until_stop_postplay_test()
set_repeat_until_stop_postplay_test("... each player drops out as he or she wishes.", &instruction_14_repeat_until_test_post)

# Handle all crescendo management in this Preplay Instruction, which fires the first time the Ensemble reaches the conclusion ... 
instruction_14_ensemble_pre = lambda do |container|  
  aleatoric_ensemble = container
  
  # Every call to play(), i.e. every iteration of the repeat until loop, fires every instruction, so
  #  increment a counter here that is used in the concluding unison code below
  play_count = aleatoric_ensemble.get_state("play_count")
  if play_count == nil
    aleatoric_ensemble.set_state("play_count", 1)  
  else
    aleatoric_ensemble.set_state("play_count", play_count + 1)
  end
  
  if In_C_Ensemble.in_c_ensemble.reached_concluding_unison?
    
    # In practice, variations in duration from swing, added notes for phase align changes can lead to significant delta
    #  in when players arrive at the same phrase, so we need this
    # Use flags to just all this block once, which which catches each player up to the one farthest ahead
    # Get current phrase of any player because all are on the last phrase
    aleatoric_players = aleatoric_ensemble.get_players
    durations = aleatoric_players[0].current_phrase.notes.collect {|note| note.duration}
    last_phrase_dur = durations.inject(0) {|sum, x| sum + x}
    # Get the start time past current latest start time so all crescendo notes start after that
    max_start = aleatoric_ensemble.players_attr_slice(:current_start).max
    # Loop through all players in the Aleatoric Ensemble
    aleatoric_players.each do |al_player|
      # Figure out how many times it needs to repeat the last phrase
      num_plays_last_phrase = ((max_start - al_player.current_start) / last_phrase_dur).floor    
      # Append the notes of the last phrase to the output for this Player, after adjusting volume
      num_plays_last_phrase.times do 
        in_c_player = in_c_players[al_player.handle]
        phrase = al_player.current_phrase
        volume_adj_factor = in_c_player.amp_adj_factor phrase
        phrase.notes.each {|note| note.volume((note.volume * volume_adj_factor).to_i)}
        al_player.append_phrase_to_output phrase
      end
    end
    
    #  "... The group then makes a large crescendo and diminuendo a few times ..."
    # Crescendo a random number of times below a settings limit
    num_crescendos = rand(ENSEMBLE_SETTINGS["max_number_concluding_crescendos"]) + 1
    # Calculate the number of steps in each crescendo -- total calls to play * a fraction of 1 to determine 
    #  the length of the conclusion crescendo as a ratio of length of the whole performance, divide by
    #  number of crescendos to spread total crescendoing length over multiple crescendos
    num_crescendo_steps = (play_count * (ENSEMBLE_SETTINGS["conclusion_steps_ratio"] / num_crescendos)).ceil    
    # Split the max allowed increase in amp for a crescendo evenly among the steps of the crescendo
    volume_adj = (ENSEMBLE_SETTINGS["max_amp_range_for_seeking_crescendo"] / num_crescendo_steps).floor
    
    num_crescendos.times do
      # Walk half the steps and crescendo
      cur_volume_adj = volume_adj
      j = 0
      num_crescendo_steps.times do     
        aleatoric_players.each do |al_player|           
          al_player.current_score.notes.each {|note| note.volume((note.volume * cur_volume_adj).to_i)}
        end
        cur_volume_adj += volume_adj
      end

      # Walk the other half of the steps and descrescendo
      cur_volume_adj -= volume_adj
      num_crescendo_steps.times do     
        aleatoric_players.each do |al_player| 
          al_player.current_score.notes.each {|note| note.volume((note.volume * cur_volume_adj).to_i)}
        end
        cur_volume_adj -= volume_adj
      end  
    end
    
    # ****
    # Set flag for repeat_until() handler to detect and end the performance
    @@in_c_ensemble.reached_conclusion = true
  end  
end
set_ensemble_postplay_instruction("Instruction 14", &instruction_14_ensemble_pre)


# BOILERPLATE FOR ALL user_instruction.rb FILES
# end
# /BOILERPLATE FOR ALL user_instruction.rb FILES

