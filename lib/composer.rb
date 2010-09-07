require 'global'
require 'util'
require 'score'
require 'meter'
require 'player'
require 'ensemble'
require 'instruction'
require 'renderer'
require 'midi'

# This module implements the basic parser/processor for the Composer language.
# At the core of the language is a simple class hierarchy that models both the main entities
#  (i.e. the "semantics") of the language and the main data structure for holding the
#  state of what the script has declared at any point in time.  These are the notes and groupings
#  of notes the script is working with, some or all of which end up in some form in the final
#  output script.

# The hierarchy looks like this:
# Score (attrs: output format (csound | midi), grouping options, sorting options, etc.)
#   - Section/Movement (attrs: ?)
#     - Phrase/Measure (attrs: transposed?, transpose_action [i.e. - a block], etc.)
#        - Note (attrs: instrument, start, end, amplitude, pitch, function_table, etc.)

# Notes are the leaf of this tree, i.e. - Notes cannot contain Notes or any other objects 
#  but can only have attributes which are either ints, reals or strings.
# Phrases (or Measures, an alias), just as in standard musical notation, are collections of Notes.
#  They may define attributes that transform the Notes they are holding.  Maybe other attrs
#  as needed too.
# Sections are intended to group Phrases into longer, well, sections of a composition.
#  Movement is an alias.

# However, this hierarchy can also be bypassed, partially.  Phrases and Sections are simply 
#  conveniences -- for example, it can be really handy to create a a few bars of notes, give that a name
#  and reuse that as needed.  It can also make a piece more understandable and is a common
#  musical convention to have sections that group a series of measures/phrases 
#  - "intro," "bridge," "coda" etc.  But you don't need to do this.  To produce an output that
#  gets rendered into an audio file you need only create Notes, and then include the 'write'
#  statement.

# The one exception to this is that you do need at least one Phrase or Section wrapping the Notes
#  in a piece that you want to include in the output.

# Scores are structured in "blocks."  Sections contain Phrases, and Phrases containt Notes.
# Then, when all Notes have been defined, a 'write' and then a 'render' statement follow, 
#  specifying the format of output desired.  These are separate because it can be useful to
#  write a script file without rendering a sound file, as the latter can sometimes take 
#  some time and you may be trying to fix unexpected output and not want to wait on rendering.

module Aleatoric

# NOTE: these need to be module scope across all files in the module, which is
#  true @@ 'module scope' rather than @ 'module scope'.  The latter is visible
#  across translation units in the module, but is not guaranteed to be 
#  initialized when called from another translation unit.  @@ is true module scope
#  and is guaranteed to be initialized when referenced by any methods in the module
#  in any translation unit.
# These guys are referred to by the set_*instruction() methods, which live here but are called
#  from the 'user_instructions.rb' translation unit, where the programmer/composer
#  puts 'instruction' keyword definitions and maps them to their name with the set_*_instruction() call
@@player_preplay_instructions = {}
@@player_postplay_instructions = {}
# Supports syntax of passing an improv name (play by key) or not passing a name
#  and then just playing the last 'improvisation' kw improv hook defined, i.e. @ordered_improvisations.last 
@@improvisations = {}
# Supports a repeat_until loop exit condition with a name that can be manipulated by instruction 
#  code in another translation unit. Initializes to 'true' so the loop runs until the outside call to
#  set_repeat_until_exit(name) is called
@@repeat_until_is_looping = {}
#
def set_player_preplay_instruction(instruction_name, &instr_blk)
  @@player_preplay_instructions[instruction_name] = instr_blk
end
def set_player_postplay_instruction(instruction_name, &instr_blk)  
  @@player_postplay_instructions[instruction_name] = instr_blk
end
def set_improvisation(instruction_name, &instr_blk)
  @@improvisations[instruction_name] = instr_blk
end

@@ensemble_preplay_instructions = {}
@@ensemble_postplay_instructions = {}
def set_ensemble_preplay_instruction(instruction_name, &instr_blk)
  @@ensemble_preplay_instructions[instruction_name] = instr_blk
end
def set_ensemble_postplay_instruction(instruction_name, &instr_blk)
  @@ensemble_postplay_instructions[instruction_name] = instr_blk
end

# Allows access to references to Ensembles and Players created, 
#  in case Instruction implementations want to, for example,
#  create a class that manages their specific Player state to implement
#  the rules of some composition.  This "shadow" object needs to know
#  which Player it is manipulating
@@ensembles = {}
@@players = {}
# Flag indicating play() callbacks have been called
@@play_init_handlers = []
def set_play_init_handler(name, &instr_blk)
  @@play_init_handlers << instr_blk
end
@play_init_called = false
def play_init_called?
  @play_init_called
end
def set_play_init_called
  @play_init_called = true
end
def call_play_init_handlers
  @@play_init_handlers.each do |handler|
    handler.call(@notes, @scores, @measures, @phrases, @sections, @players, @ensembles)
  end
end

# This registers a handler that the user must implement to set the stop condition
#  for a repeat_until loop.  So this is a named handler in user_instruction.rb
#  that must call set_repeat_until_exit() for the repeat_until loop to stop
# Each iteration of repeat_until() will call all registered handlers for the
#  named repeat_until() loop, in the order they were registered
@@repeat_until_stop_preplay_tests = {}
@@repeat_until_stop_postplay_tests = {}
def set_repeat_until_stop_preplay_test(name, &test)
  if not @@repeat_until_stop_preplay_tests.has_key? name
    @@repeat_until_stop_preplay_tests[name] = [test] 
  else
    @@repeat_until_stop_preplay_tests[name] << test
  end  
end
def set_repeat_until_stop_postplay_test(name, &test)  
  if not @@repeat_until_stop_postplay_tests.has_key? name
    @@repeat_until_stop_postplay_tests[name] = [test] 
  else
    @@repeat_until_stop_postplay_tests[name] << test
  end
end
# This runs the stop test handlers in order for the name of a repeat_until loop passed in
# This runs the stop tests set in set_repeat_until_stop_test()
def call_repeat_until_stop_preplay_tests(name)
  if @@repeat_until_stop_preplay_tests.has_key? name
    @@repeat_until_stop_preplay_tests[name].each {|test| test.call}
  end
end
def call_repeat_until_stop_postplay_tests(name)
  if @@repeat_until_stop_postplay_tests.has_key? name
    @@repeat_until_stop_postplay_tests[name].each {|test| test.call}
  end
end
# This is just called once in composer.rb::repeat_until() to regiser the
#  loop handler and initialize it to continue looping
def init_repeat_until(name)
  @@repeat_until_is_looping[name] = true if not @@repeat_until_is_looping.has_key? name
end
#
# *** These three methods are the public API for this functionality
# They are to be used in user_instruction repeat_until() handlers
#
# This can be called by set_repeat_until_stop_test() handler to force the loop to exit, 
#  or undo that and allow it to continue.
#  # e.g. - repeat_until "All players finished"
#  # in set_repeat_until_stop_test() registered handler
#  set_repeat_until_stop("All players finished") if all_players_finished?
#  # ... But then something happens to make you change your mind
#  set_repeat_until_continue("All players finished") if sky_is_falling?
#  # ... This time we mean it ...
#  set_repeat_until_stop("All players finished")
#  # function returns here
def set_repeat_until_continue(name)
  @@repeat_until_is_looping[name] = true
end
def set_repeat_until_stop(name)
  @@repeat_until_is_looping[name] = false  
end
# Convenience predicates complete the interface to this functionality 
def repeat_until_is_looping?(name)
  @@repeat_until_is_looping[name]
end


@cur_note = nil
@notes = []
@notes_by_name = {}
@processing_note = false

@cur_phrases = []
@phrases = []
@phrases_by_name = {}
@processing_phrase = false

@cur_sections = []
@cur_section = nil
@sections = []
@sections_by_name = {}
@processing_section = false

@meter = Meter.new(quantizing=false)

@cur_start = 0.0
MIDI_IMPORT_NO_START = 0.0
@cur_measure = nil
@measures = []
@measures_by_name = {}
@processing_measure = false

@processing_instruction = false
@cur_instruction = nil
@instructions_by_name = {}
@processing_improvise = false  
@cur_improvisation = nil  
@improvisations_by_name = {}
@ordered_improvisations = []

@processing_play = false
@processing_improvisation = false
@processing_player = false
@processing_ensemble = false
@cur_ensemble = nil
@ensembles = []
@ensembles_by_name = {}
@cur_player = nil
@cur_players = []
@players = []
@players_by_name = {}

@write_called = false
DEFAULT_EXT = '.ext'
CSOUND_SCORE_EXT = '.sco'
@score_out = ScoreWriter.instance
@processing_score = false
@score_notes = []

@renderer = Renderer.instance
@processing_renderer = false

@import_notes = []
@capture_measures = false

Note.output_format $FORMAT
@midi_mgr = ::MidiManager.new


# Handles keyword "note," assigns attrs in block to a new Note
# Automatically sets note.start(@cur_start) if the note doesn't define its own
#  start attr.  This allows chaining of notes to start one after another (super nice)
def note(name=nil, &args_blk)    
  # Set flag for method_missing() so it traps methods and adds to this Note
  @processing_note = true
  # Declare the new Note  
  @cur_note = Note.new(name)  
  
  # Now run the block. This call all the method_missing attribute functions, thus
  #  passing their name and arg to Note.method_missing, and thus adding them as attrs of this Note
  yield
  
  # If running note block didn't add a start attribute, then set it here to @cur_start
  @cur_note.start(@cur_start) if @cur_note.start == nil
  
  # Notes must always be created in the context of a containing Phrase or Section
  # This is the queue of Notes being created in that containing block, which that object
  #  will then pick up and append to its collection of Notes.  So the containing block
  #  is responsible for clearing this at the start and end of its block, before its yield.
  @notes << @cur_note    
  # Notes are also stored by name, if they are named, for convenient random access by key
  #  at any point later in the script. This is an internal data structure and these are not
  #  put into the output Score
  @notes_by_name[name] = @cur_note unless name == nil
  # We're done with this Note, unset method_missing() flag
  @processing_note = false
  
  # Each note can adjust @cur_start
  # Sort of lame we have to list-ify it, but the same method takes a list for 'copy_measure'
  adjust_cur_start([@cur_note])  
  # Return the note, useful for testing purposes only. Allows independent testing of function
  #  and no additional exposure of module state, e.g. @notes
  @cur_note
end

def import(name, &args_blk)
  @processing_import = true  
  @import_notes = @midi_mgr.load_notes_from_file name
  return if @import_notes.length == 0
  
  # import can be used in two ways, if its child of phrase then its just assigning notes to that phrase
  if @processing_phrase
    # Call MidiMgr to get the notes in sequence from the named MIDI file
    # Import notes could have start or not and it still doesn't make sense to have them
    #  occur out of sequence with what already has been recorded in this score
    #  so just offset them from current cur_start  
    init_import_start = import_notes[0].start
    init_cur_start = @cur_start
    # So it is just as if script encountered a whole series of 'note' stmts
    # So make all adjustsments as above in note(), but for each note imported
    # But if note does have start, ignore it and make it start at cur_start
    @import_notes.each do |note|
      delta = note.start - init_import_start
      delta = 0.0 if delta < 0.0
      note.start(init_cur_start + delta) 
      @notes << note 
      @notes_by_name[name] = note unless note.name == nil      
      adjust_cur_start([note])      
    end
  # import can also be used as child of root, and then its loading channels, instruments, notes
  #  and measures (if capture measure is part of the import block) into players listed in 
  #  players statement in the import block
  else
    @capture_measures = false
    # We want to support this ...
    # import "myfile.mid" do
    #   capture measuers
    #   players "Player 1", "Player 2"                                                                                                                                                                                                                      mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
    # and this ...
    # We want to support this ...
    # import "myfile.mid" do
    #   players "Player 1", "Player 2"                                                                                                                                                                                                                      mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
    #   capture measuers
    # but players() handler needs to know about capture_measures
    # This flag is set if the keyword is encountered in the yield

    yield
    
    @capture_measures = false
  end
  
  @import_notes = []
  @processing_import = false
end

def capture_measures
  @capture_measures = true  
end

# TODO FIX THIS RIDICULOUS BUG THAT REQUIRES channel and instrument ON SAME LINE
# THIS IS ANOTHER EXAMPLE OF NEEDING LOOKAHEAD OR STATE IN A BLOCK
# BLOCK EXECUTION MODEL IS BREAKING DOWN
def channel(channel, instrument=nil)
  # Allocate a MIDI channel for the channel number if there isn't one already
  @midi_mgr.channel channel if $FORMAT == :midi 
  
  # Need to check note first and elsif exclusion because can process note nested with player
  #  so when this is being handled both @processing_note and @processing_player can be true
  if @processing_note
    @cur_note.channel channel
    @midi_mgr.instrument(@cur_note.channel, @cur_note.instrument) if $FORMAT == :midi and not @cur_note.instrument.nil?
  elsif @processing_player  
    @cur_player.channel channel
    @cur_player.instrument instrument if not instrument.nil?
    @midi_mgr.instrument(channel, instrument) if $FORMAT == :midi and not instrument.nil?    
  end
end

# TODO FIX THIS RIDICULOUS BUG THAT REQUIRES channel and instrument ON SAME LINE
# THIS IS ANOTHER EXAMPLE OF NEEDING LOOKAHEAD OR STATE IN A BLOCK
# BLOCK EXECUTION MODEL IS BREAKING DOWN
def instrument(instrument, channel=nil)
  # Need to check note first and elsif exclusion because can process note nested with player
  #  so when this is being handled both @processing_note and @processing_player can be true
  if @processing_note
    @cur_note.instrument instrument
    @midi_mgr.instrument(@cur_note.channel, @cur_note.instrument) if $FORMAT == :midi and not @cur_note.channel.nil?
  elsif @processing_player   
    @cur_player.instrument instrument    
    @cur_player.channel channel if not channel.nil?
    @midi_mgr.instrument(channel, instrument) if $FORMAT == :midi and not channel.nil?
  end
end

def program_change(arg)
  # We respect the wishes of the script and assume that a midi-only property
  # means the script wants all Notes to be in MIDI format
  # Note.set_output_format_midi
  # TODO raise exception if $FORMAT not midi
  @cur_note.instrument arg
end

def start(arg, is_duration_set_using_const=false)
  arg *= $DUR_FACTOR if is_duration_set_using_const and $FORMAT != :midi
  @cur_note.start arg
end
def time(arg, is_duration_set_using_const=false)
  # We respect the wishes of the script and assume that a midi-only property
  # means the script wants all Notes to be in MIDI format
  # Note.set_output_format_midi
  # TODO raise exception if $FORMAT not midi
  arg *= $DUR_FACTOR if is_duration_set_using_const and $FORMAT != :midi
  @cur_note.start arg 
end

# $DUR_FACTOR is 1.0 by default, in global.rb
# So if set here it changes tempo, which is applied to all notes
#  set using duration constants, e.g. WHL, HLF, also in global.rb
def duration(arg, is_duration_set_using_const=false)
  arg *= $DUR_FACTOR if is_duration_set_using_const and $FORMAT != :midi
  @cur_note.duration arg
end

# $DUR_FACTOR is 1.0 by default, in global.rb
# So if set here it changes tempo, which is applied to all notes
#  set using duration constants, e.g. WHL, HLF, also in global.rb
def tempo(new_tempo_bpm)
  # If notes explicitly declared in score, adjust each one by tempo duration factor
  if $FORMAT != :midi
    $DUR_FACTOR = $DEFAULT_TEMPO / new_tempo_bpm.to_f
  # If format is midi then adjust MidMgr tempo which will set tempo for each midi track
  else
    @midi_mgr.tempo new_tempo_bpm
  end
end

def amplitude(arg)
  if @processing_note
    @cur_note.amplitude arg
  end
  if @processing_player
    @cur_player.default_volume arg
  end
end
def velocity(arg)
  amplitude arg
end
def volume(arg)
  amplitude arg
end

def pitch(arg)
  @cur_note.pitch arg
end

# Handles keyword "phrase"
def phrase(name, &args_blk)
  @processing_phrase = true
  # Init (clear) the queue of notes created -- this holds state contained by this block scope
  @notes.clear
  cur_phrase = Phrase.new(name)  

  # Construct and put into @notes queue all Notes in the block for this Phrase block
  yield

  # Now add them to the Notes in this Phrase object  
  cur_phrase << @notes
  # State that persists for the life of the score
  @phrases << cur_phrase
  # State that is built/torn down within current containing section block, if any, or just ignored
  @cur_phrases << cur_phrase
  # NOTE: nil name breaks because then Phrase can't be retrieved by key in write() block  
  @phrases_by_name[name] = cur_phrase    
  # Phrase just copied the Notes, so clear the queue again (redundant, but a bug waiting to happen)
  @notes.clear
  @processing_phrase = false
end

def meter(beat_per_measure, beat_length, &args_blk)  
  @meter.beat_per_measure beat_per_measure
  @meter.beat_length beat_length
  # This will end up firing quantize() immediately below, won't go to method_missing
  #  because there is a local match
  yield
end

def on; 'on'; end
def off; 'off'; end
def quantize(flag_str)
  @meter.quantizing?(true) if flag_str == on
  @meter.quantizing?(false) if flag_str == off
end

def measure(name, &args_blk)  
  @processing_measure = true
  @notes.clear
  # A measure is a Phrase but it's also passed a position, which is the ordinal position of the
  #  measure among all measures, and a start offset
  # This lets sequences of measures not need to figure out their offset from the beginning
  # So you have this:
  #   note
  #     start QRTR
  # instead of this:
  #   note
  #     start running_total_since_start + QRTR  
  @cur_measure = Measure.new(name, @cur_start)
  # NOTE: Need to wrap yield call (which processes notes) to put Note in scope as the 
  #  method_missing() handler or else the 'start' attribute from the script is trapped
  #  by Measure, which has a 'start' property, and doesn't reach the note, and changes
  #  the value for Measure.start inadvertantly. i.e. - but that took 90 minutes to find
  @processing_measure = false
  @processing_note = true
  yield args_blk
  @processing_note = false
  @processing_measure = true
  @notes = @meter.quantize(@notes) if @meter.quantizing?
  @cur_measure << @notes  
  @measures << @cur_measure
  @measures_by_name[name] = @cur_measure
  @notes.clear
  @processing_measure = false  
end

# TODO Why not also have copy_section, copy_phrase and copy_note?
# Only reason is they's stack up on the same start time ...
def copy_measure(src_name, target_name)
  @cur_measure = @measures_by_name[src_name].dup
  @cur_measure.name = target_name 
  @cur_measure.reset_notes @cur_start
  @cur_measure.notes.each do |note|
    @notes << note
  end  
  @measures << @cur_measure
  @measures_by_name[target_name] = @cur_measure
  adjust_cur_start @cur_measure.notes
end

def adjust_cur_start(notes)
  new_start = (notes.collect {|note| note.start + note.duration}).max
  @cur_start = new_start if new_start > @cur_start
end

# Handles keyword "section"
def section(name, &args_blk)
  @processing_section = true
  @cur_phrases.clear
  @cur_section = Section.new(name)
  @sections << @cur_section
  @cur_sections << @cur_section
  @sections_by_name[name] = @cur_section
  yield args_blk
  @cur_section << @cur_phrases  
  @cur_phrases.clear
  @processing_section = false
end

def player(name, &args_blk)
  @processing_player = true
  if not @players_by_name.include? name
    @cur_player = Player.new(name)
    @players_by_name[name] = @cur_player
    @players << @cur_player
  else
    @cur_player = @players_by_name[name]
  end
  @@players[name] = @cur_player
  @cur_player.ensemble = @cur_ensemble
  
  @cur_sections.clear
  @cur_phrases.clear
  @measures.clear
  
  yield
  
  @cur_sections.each do |section|
    section.phrases.each do |phrase|
      @cur_player.add_score(phrase.name, phrase)
    end
  end
    
  @cur_phrases.each do |phrase|
    @cur_player.add_score(phrase.name, phrase)
  end

  @measures.each do |measure|
    @cur_player.add_score(measure.name, measure)
  end

  @cur_sections.clear
  @cur_phrases.clear 
  @measures.clear
  @processing_player = false  
end

# NOTE: CANNOT mix section and phrase in an ensemble block
# CAN have 1 or more sections or 0 sections and instead 1 or more phrases
# So supports either but still hierarchical structure with ensemble a parent 
#  of sections or phrases but not both
def ensemble(name, &args_blk)
  @processing_ensemble = true
  @cur_players.clear
  @cur_sections.clear
  @cur_phrases.clear
  # TODO Make consisten with phrases, @cur_measures
  @measures.clear
  
  @cur_ensemble = Ensemble.new(name)
  @ensembles << @cur_ensemble
  @ensembles_by_name[name] = @cur_ensemble
  @@ensembles[name] = @cur_ensemble

  yield

  @cur_players.each do |player| 
    player.ensemble = @cur_ensemble
    @cur_ensemble.add_player(player.name, player)
    
    if @cur_sections.length > 0
      @cur_sections.each do |section|
        section.phrases.each do |phrase|
          player.add_score(phrase.name, phrase)
        end
      end
    end
    
    if @cur_phrases.length > 0
      @cur_phrases.each do |phrase|
        player.add_score(phrase.name, phrase)
      end
    end
    
    if @measures.length > 0
      @measures.each do |measure|
        player.add_score(measure.name, measure)
      end
    end    
  end
      
  @cur_players.clear
  @cur_sections.clear
  @cur_phrases.clear
  @measures.clear  
  @processing_ensemble = false  
end

def play
  call_play_init_handlers unless play_init_called?
  set_play_init_called  
  @processing_play = true
  yield
  @processing_play = false
end

def improvise(name=nil)
  @processing_improvise = true
  call_play_init_handlers unless play_init_called?

  # If no name passed, set current improv to the most recent one declared, else
  #  set it to the one matching the name passed in  
  if name == nil  
    @cur_improvisation = @ordered_improvisations.last
  else
    @cur_improvisation = @improvisations_by_name[name]
  end
  yield
  set_play_init_called
  @processing_improvise = false
end

def players(*names)
  if @processing_ensemble
    names.each do |name| 
      name = name.strip
      if not @players_by_name.include? name
        @players_by_name[name] = Player.new(name)
        @players << @players_by_name[name]
      end
      @cur_players << @players_by_name[name]      
    end
  end
  
  if @processing_instruction
    names.each do |name|
      name = name.strip
      player = @players_by_name[name]
      instr_name = @cur_instruction.name
      # Note the pass by '&' to pass as a lambda which the recieving method in Player stores as a Proc and then calls 'call()' to run it
      player.add_preplay_hook(instr_name, &@@player_preplay_instructions[instr_name]) if @@player_preplay_instructions.include? instr_name
      player.add_postplay_hook(instr_name, &@@player_postplay_instructions[instr_name]) if @@player_postplay_instructions.include? instr_name
    end    
  end

  if @processing_improvisation
    names.each do |name| 
      player = @players_by_name[name]
      improv_name = @cur_improvisation.name      
      player.add_improvisation_hook(improv_name, &@@improvisations[improv_name]) if @@improvisations.include? improv_name
    end    
  end
  
  if @processing_play
    names.each do |name|
      name = name.strip    
        if @players_by_name.include? name
          player = @players_by_name[name] 
          player.play
          @cur_start = player.current_start if player.current_start > @cur_start 
        end
    end 
  end
  
  if @processing_improvise
    names.each do |name|
      name = name.strip
       if @players_by_name.include? name
         player = @players_by_name[name]
         player.improvise(@cur_improvisation.name)
         @cur_start = player.current_start if player.current_start > @cur_start 
       end
    end 
  end  
  
  if @processing_score  
    names.each do |name|     
      name = name.strip
      player = @players_by_name[name]
      if player != nil
        player.output.each do |note|    
          @score_notes << note
        end
        player.clear_output
      end
    end
  end
  
  if @processing_import        
    # Simple case is that we are processing import block with players list and
    #  not turning measures into separate phrases.  In that case, sequence of notes for each channel
    #  is appended as a single phrase to the phrases for each player that is assigned that channel
    if @capture_measures      
      # Iterate notes and group into lists of notes for each measure
      # list of lists, one list for each measure's notes, in sequenc
      all_measures_notes = []
      # temp to hold current measures notes, copied into all_measure_notes for each measure
      cur_measure_notes = []
      # Init to same lookahead first note measure value to avoid check on being first pass in loop
      cur_measure = notes[0].measure if notes.length > 0
      last_measure = notes[0].measure if notes.length > 0
      @import_notes.each do |note|
        cur_measure = note.measure
        if cur_measure == last_measure
          cur_measure_notes.push note
        else # if cur_measure != last_measure
          all_measures_notes.push cur_measure_notes            
          cur_measure_notes = []            
        end
        last_measure = cur_measure
      end
      # Catch single/last measure case
      all_measures_notes.push cur_measure_notes if cur_measure_notes.length > 0
      
      # Iterate the players in the list of kw 'players' for this import block, assign them the notes
      names.each do |name|
        # Add the notes for each measure as a separate phrase
        all_measures_notes.each do |measure_notes|
          score = Score.new
          score << measure_notes              
          @players_by_name[name.strip].add_score(score.name, score)
        end       
      end
    else # if ! @capture_measures
      names.each do |name|
        score = Score.new
        score << @import_notes            
        @players_by_name[name.strip].add_score(score.name, score)
      end      
    end
  end
  
end

def instruction(name)
  @processing_instruction = true  
  @cur_instruction = Instruction.new(name)  
  @instructions_by_name[name] = @cur_instruction  
  yield
  @processing_instruction = false  
end

def improvisation(name)
  @processing_improvisation = true  
  @cur_improvisation = Improvisation.new(name)   
  @improvisations_by_name[name] = @cur_improvisation
  @ordered_improvisations << @cur_improvisation
  yield
  @processing_improvisation = false  
end

def description(desc)
  @cur_instruction.description = desc if @processing_instruction
  @cur_improvisation.description = desc if @processing_improvisation
end

# Handles keyword "phrases", called inside write() block
def phrases(*names)
  # Because Score is a singleton, this can just write its notes to Score's output notes
  # This is bad because it goes in the opposite direction of the nesting logic for Notes, Phrases, etc.
  # So, lurking bugs.  Also it breaks if we want to have more than on Score.  Fine for "now."
    
  names.each do |name| 
    name = name.strip    
    phrase = @phrases_by_name[name]        
    phrase.notes.each do |note|    
      @score_notes << note.dup      
    end
  end
end

def measures(*names)
  # This keyword can also appear as an argument to kw 'capture' which is a child of 'import'
  #  and in that case we want this handler not to fire
  # import 'my_file.mid'
  #   capture measures
  #   players "Player 1", "Player 2"
  if not @processing_import
    if names != nil and names.length > 0
      names.each do |name| 
        name = name.strip
        measure = @measures_by_name[name]    
        measure.notes.each do |note|
          @score_notes << note.dup
        end
      end
    else

      @measures.length.times do |j|
        @measures[j].notes.each do |note|
          @score_notes << note.dup
        end
      end
    end
  end
end

# Handles keyword "sections", called inside write() block
def sections(*names)
  names.each do |name|
    name = name.strip
    section = @sections_by_name[name]
    section.phrases.each do |phrase|
      phrase.notes.each do |note|
        @score_notes << note.dup        
      end
    end
  end
end

# Handles keyword "ensembles", called inside write() block
def ensembles(*names)
  if @processing_instruction
    names.each do |name| 
      ensemble = @ensembles_by_name[name.strip]
      instr_name = @cur_instruction.name      
      # Note the pass by '&' to pass as a lambda which the recieving method in Player stores as a Proc and then calls 'call()' to run it
      ensemble.add_preplay_hook(instr_name, &@@ensemble_preplay_instructions[instr_name]) if @@ensemble_preplay_instructions.include? instr_name
      ensemble.add_postplay_hook(instr_name, &@@ensemble_postplay_instructions[instr_name]) if @@ensemble_postplay_instructions.include? instr_name
    end    
  end
  
  if @processing_play
    names.each do |name| 
      name = name.strip
      ensemble = @ensembles_by_name[name]
      # Will run ensemble.play_all, which plays ensemble preplay hooks,
      #  calls play on each player in ensemble (running their preplay hooks, 
      #  then generating their output, then running their postplay hooks),
      #  then calls ensemble postplay hooks
      if ensemble != nil
        ensemble.play_all
        max_ensemble_cur_start = (ensemble.players.collect {|player| player.current_start}).max 
        @cur_start = max_ensemble_cur_start if max_ensemble_cur_start > @cur_start
      end
    end 
  end
  
  if @processing_score
    names.each do |name| 
      name = name.strip
      ensemble = @ensembles_by_name[name]
      ensemble.players.each do |player|
        player.output.each do |note|          
          @score_notes << note
        end
        player.clear_output
      end
    end    
  end  
end

def repeat(limit, &blk)
  # NOTE: 1-based loops.  Shoot me now!  But 1-based loops make more sense in this domain,
  #  particularly since the typical use case is to use the index as a factor of multiplication in
  #  a loop.  In that case, identity is 1 (the base case, that has no effect) and 0 is a special
  #  case returning no value.  The user should have to choose the 0 case,
  #  not have it thrust on them silently.
  index = 1
  # Somewhat hacky way to handle variables as args to repeat
  # TODO: worse is that we don't check that limit evaluated to a Fixnum (int)
  limit = eval(limit.to_s)  
  limit.times do
    # Pass the index to the block
    yield index
    index += 1
  end
end

def repeat_until(name, &blk)  
  # init_repeat_until registers the named repeat_until just on the first call
  # After that continue? and stop? predicates controlled by API calls
  #  from Instruction handlers or the repeat_until() handler -- i.e. by user code
  # TODO Verbose logging
  j = 0
  init_repeat_until name
  while repeat_until_is_looping? name
    call_repeat_until_stop_preplay_tests name
    yield
    call_repeat_until_stop_postplay_tests name
  end
end

# Handles constant arg to method_missing "format" function in "write" block
# NOTE: This didn't work returning a symbol, but did work returning a string, why?
def csound; "csound"; end
def midi; "midi"; end
# handles keyword "write"
# NOTE: MUST implement "format" keyword, because can't method_missing() it because there is a
#  default private format() method on class Object. Nice.
def format(fmt)
  $FORMAT = fmt.to_sym  
  @format = $FORMAT
  @score_out.set_output_format $FORMAT
  
  if $FORMAT == :midi
    set_midi_consts
  elsif $FORMAT == :csound
    set_csound_consts
  end
end

def write(file_name, &args_blk)  
  @processing_score = true
  @score_out.file_name = file_name  
    
  # Sets write properties, and writes all notes of all Phrases and Sections into a queue  
  yield

  @score_out << @score_notes  
  
  # TEMP DEBUG
  starts = @score_notes.collect {|note| note.start}
  last_start = 0.0
  starts.sort.each do |start| 
    puts "#{start} - #{last_start} = #{start - last_start}" if start - last_start > 2.0
    last_start = start
  end
  
  case @score_out.format.to_sym
  when :csound    
    File.open(file_name, 'w') do |f|
      f << @score_out.to_s
    end
  # TO SUPPORT UNIT TESTS ONLY
  when :midi
    File.open(file_name, 'w') do |f|
      f << @score_out.to_s
    end
  end
  @processing_score = false
  @is_write_called = true
end

# TODO Midi unit tests now broken if they rely on write() to create .mid file output
#  That is now in render()
# Handles "render" keyword, renders for csound now
# score_file_name, orc_file_name=nil
def render(out_file_name, &args_blk)
  @processing_renderer = true

  yield  

  if @score_out.format.to_sym == :midi
    # Allows a file name to be passed that isn't .mid and have .mid added.  So testing works 
    # In the docs we tell users to always use ".mid"
    out_file_name += '.mid' if out_file_name[out_file_name.length - 4..out_file_name.length - 1] != '.mid'        
    # NOTE: pass empty block to write() because called render block yield here already
    # But we want write() and render() to each have a yield since each can take blocks
    # TO SUPPORT UNIT TESTS ONLY 
    write(out_file_name + DEFAULT_EXT){} if not @is_write_called       
    # /TO SUPPORT UNIT TESTS ONLY    
    @score_out.notes.each do |note|      
      # NOTE: named args caused error on this call, no reason why, all args had values. Nice.
      # MIDI arg names: channel, note, velocity, delta_time
      @midi_mgr.add_note(note.channel, note.pitch, note.velocity, note.duration, note.start)
    end
    @midi_mgr.save out_file_name
  elsif @score_out.format.to_sym == :csound
    @renderer.render(render_format=@score_out.format, out_file=out_file_name, score_file=@score_out.file_name)
  end
  
  @processing_renderer = false
end

# FOR UNIT TESTING
def dump_notes
  # File.open("..\\test\\composer_test_results.txt", "w") do |f|
  File.open("../test/composer_test_results.txt", "w") do |f|
    @notes.each do |note|
      f << (note.to_s + "\n")
    end
  end
end

def dump_last_note
  # File.open("..\\test\\composer_test_results.txt", "w") do |f|
  File.open("../test/composer_test_results.txt", "w") do |f|
    f << @notes.last.to_s
  end
end

def dump_last_phrase
  # File.open("..\\test\\composer_test_results.txt", "w") do |f|
  File.open("../test/composer_test_results.txt", "w") do |f|
    @phrases.last.notes.each do |note|
      f << (note.to_s + "\n")
    end
  end
end

def dump_last_section
  # File.open("..\\test\\composer_test_results.txt", "w") do |f|
  File.open("../test/composer_test_results.txt", "w") do |f|
    @sections.last.phrases.each do |phrase|
      phrase.notes.each do |note|
        f << (note.to_s + "\n")
      end
    end
  end
end

def dump_last_ensemble
  # File.open("..\\test\\composer_test_results.txt", "w") do |f|    
  File.open("../test/composer_test_results.txt", "w") do |f|    
    ensemble = @ensembles.last
    players = ensemble.players
    f << ensemble.name + "\n"
    f << players.length.to_s + "\n"
    players.each do |player|        
      f << player.name + "\n"
    end
  end
end

def dump_last_player
  # File.open("..\\test\\composer_test_results.txt", "w") do |f|
  File.open("../test/composer_test_results.txt", "w") do |f|
    f << @players.last.name
  end
end
# /FOR UNIT TESTING

def reset_script_state
  # *** KEEP THIS HERE ALWAYS ***
  @score_out.clear
  # *** KEEP THIS HERE ALWAYS ***

  @cur_note = nil
  @notes = []
  @notes_by_name = {}
  @processing_note = false

  # TODO remove this - aliasing bug
  # @cur_phrase = nil
  @cur_phrases = []
  @phrases = []
  @phrases_by_name = {}
  @processing_phrase = false

  @cur_sections = []
  @cur_section = nil
  @sections = []
  @sections_by_name = {}
  @processing_section = false
  
  @meter = Meter.new(quantizing=false)
  
  @cur_measure = nil
  @measures = []
  @processing_measure = false
  @measures_by_name = {}
  @cur_start = 0.0
  @channel_import_start = 0.0
  
  @processing_instruction = false
  @cur_instruction = nil
  @instructions_by_name = {}
  @processing_improvise = false  
  @cur_improvisation = nil  
  @improvisations_by_name = {}
  @@ordered_improv_instructions = []
  # *** KEEP THIS HERE ALWAYS ***
  # Don't reset, because these are set at beginning of run
  #  and live for lifetime of run of a process
  #  because they are set by a require at top of overall
  #  test.altc file, which includes all of the separate test scripts
  # @@player_preplay_instructions = {}
  # @@player_postplay_instructions = {}
  # @@improvisations = {}
  # *** KEEP THIS HERE ALWAYS ***
  
  @processing_play = false
  @processing_improvisation = false
  @processing_player = false
  @processing_ensemble = false
  @cur_ensemble = nil
  @ensembles = []
  @ensembles_by_name = {}
  @cur_player = nil
  @cur_players = []
  @players = []
  @players_by_name = {}
  
  @is_write_called = false
  @processing_score = false
  @score_notes = []
  
  @processing_renderer = false
  
  @import_notes = []
  @capture_measures = false
  
  @midi_mgr = ::MidiManager.new
  
  $DUR_FACTOR = 1.0

end
# /FOR UNIT TESTING

def method_missing(name, arg)
  # Conditionals enforce the hierarchy from leaf to root:
  #  Note -> Phrase -> Section -> Score
  # This is in reverse order of the nested order of the blocks, so it's an implicit
  #  stack of precedence -- Notes are deepest and so always evaluated first, Phrases
  #  can contain Notes so a Note in scope should come first, but otherwise the Phrase
  #  should be considered before a Section, and so on.  
  @cur_note.method_missing(name, arg) if @processing_note
  @cur_phrase.method_missing(name, arg) if @processing_phrase
  @cur_section.method_missing(name, arg) if @processing_section
  @cur_measure.method_missing(name, arg) if @processing_measure
  @cur_player.method_missing(name, arg) if @processing_player
  @score_out.method_missing(name, arg) if @processing_score
  @renderer.method_missing(name, arg) if @processing_renderer
end

end