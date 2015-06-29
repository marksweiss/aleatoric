$LOAD_PATH << psub("../lib")

if include_win? or include_mac?
require 'dl/import'
require 'midilib/sequence'
require 'midilib/event'
require 'midilib/consts'
end


# require 'ruby-debug' ; Debugger.start

class AleatoricIllegalMidiOperationException < Exception; end
class AleatoricFailedMidiLoadException < Exception; end


# Some Usage Notes - from the midilib documentation
#  - MIDI file IO only understands MIDI file format 1 
#    (where a sequence is made up of multiple tracks. It doesn't yet understand format 0 
#    (a single track containing all events) or format 2 (a collection of format 0 files in one file))
#  - The first track in a sequence is special; it holds meta-events like tempo and sequence name. 
#    Don't put any notes in this track.

class MidiManager

  if include_win? or include_mac?
  include MIDI
  end
  include Aleatoric
  require 'note'

  attr_reader :name, :bpm
  attr_accessor :import_volume
  
  DEFAULT_BPM = 120
  MIDI_TICKS_PER_QRTR_NOTE = 960.0
  START_TIME_APPEND_NOTE = 0
  
  def initialize(name=nil, bpm=nil)
    if include_win? or include_mac?
    # custom init steps
    @name = name || 'Track'
    @bpm = bpm || DEFAULT_BPM
    @channel_tracks = {}
    @channel_instruments = {}
    @last_start_time = 0.0
    # midilib init steps
    @seq = MIDI::Sequence.new()  
    # TODO ******** Linux MIDI support! ******** 
    else
    raise "ONLY WINDOWS AND MAC ARE SUPPORTED FOR MIDI RENDERING AT THIS TIME"    
    end
  end
  
  # NOTE: MIDI doesn't require this, but this interface assumes each track will be
  #  assigned to one and only one channel.  The interface hides tracks entirely
  #  (since they are  MIDI concept with no analog in Composer) and to the user
  #  their Composer script assigns Notes (Composer Notes) to Channels (MIDI channels)
  #  but even that isn't actually exposed in Composer (other than the abstract
  #  concept of multiple Channels available if you set format == :midi
  def channel(channel)
    if include_win? or include_mac?
    if channel_nil?(channel)
      # Construct a track (the midilib construct for a series of notes on a channel)
      track = Track.new(@seq)
      # Set the track's tempo and name      
      track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(@bpm))
      track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, "#{@name} #{@seq.tracks.length + 1}")
      @seq.tracks << track
      @channel_tracks[channel] = track
    end
    @channel_tracks[channel]
    end
  end

  def channel_nil?(channel)
    if include_win? or include_mac?
    @channel_tracks[channel].nil?
    end
  end
  
  def channels_list
    @channel_tracks.keys.sort
  end
  
  def instrument(channel, instrument, delta_time=0)
    # Don't do anything if we got a nil arg for channel
    # Client can set channel and instrument in any order, so may get a call
    #  here where instrument has been set but channel hasn't yet been set.
    # See #channel() and #instrument() in composer.rb
    return if channel.nil?

    if include_win? or include_mac?
    self.channel(channel) if channel_nil?(channel)        
    @channel_tracks[channel].events << ProgramChange.new(channel, instrument, delta_time)
    @channel_instruments[channel] = instrument
    
    # VERBOSE
    puts "Mapped channel #{channel} to instrument #{instrument}"
    # /VERBOSE
    
    end
  end

  def channel_instrument(channel)
    if include_win? or include_mac?    
    @channel_instruments[channel]
    end
  end
  
  # Args named with MIDI semantics. Converting to Composer semantics:
  #  channel == channel, note == pitch, velocity == amplitude == volume, delta_time == duration, start_time == start  
  # Note that if start_time is supplied and value is > 0 then this behaves by positioning note at absolute start time
  #  but start_time is not supplied or value == 0 then this behaves by appending note in track for sequence for channel
  def add_note(channel, note, velocity, delta_time, start_time=nil)
    if include_win? or include_mac?
    
    self.channel(channel) if channel_nil?(channel)
    note_length = @seq.length_to_delta(seconds_to_beats(delta_time))
    # NOTE: Attempts to write notes from multiple players to same channel at absolute start times
    #  that didn't just append forward in time all failed
    # Tried using the Track#recalc_times() but that didn't set absolute times. Tried to write
    #  notes in with actual start times (not 0 for NoteOnEvent#new arg4) and that gave null pointer
    #  errors in midilib code. Only reliable way was to pass 0 and let it append notes
    # So to get polyphony must have each Player write into separate Track on separate Channel    
    @channel_tracks[channel].events << NoteOnEvent.new(channel, note, velocity, START_TIME_APPEND_NOTE)
    @channel_tracks[channel].events << NoteOffEvent.new(channel, note, velocity, note_length)
        
    end
  end
  
  # NOTE: Breaks encapsulation and really only intended for unit testing add_note()
  def channel_notes(channel)
    if include_win? or include_mac?
    notes = []
    if not channel_nil? channel
      @channel_tracks[channel].each {|note| notes << note if note.note?}
    end
    notes
    end
  end
  
  # TODO MidiMgr unit test for this method
  def tempo(bpm)
    @bpm = bpm
  end
    
  def load(file_name)
    ret_notes = []
        
    # Create a new, empty sequence.
    seq = MIDI::Sequence.new    
    # Read the contents of a MIDI file into the sequence.
    File.open(file_name, 'rb') do |file|
      seq.read(file)
    end
    
    # VERBOSE
    channels_found = {}
    notes_loaded_count = 0
    # /VERBOSE
        
    note_num = 0
    # Get the tracks from the loaded file
    tracks = seq.collect
    # Get the measures from the loaded file
    seq_measures = seq.get_measures
    # Flags to track whether we have set the instrument for each channel encountered
    channels_assigned_instruments = []
    tracks.each do |track|      
      # Get all events from the track
      events = track.collect
      # Init state of properties collected from each event
      channel = nil; instrument = nil; start = nil; duration = nil; volume = nil; pitch = nil
      measure = nil
      # Iterate events and only extract props from MIDI events that have what we need
      events.each do |event|        
        next if not (event.program_change? or event.note?)
  
        if event.program_change?       
          instrument = event.program
        end      
        if event.note_off?
          channel = event.channel          
          # VERBOSE          
          if not channels_found.include? channel
            channels_found[channel] = ''
            puts "Channels Found on MidiManager#load() #{channels_found.keys.sort.join(' ')}"
          end
          # /VERBOSE
          
          # From the midilib docs: "... delta times that represent note lengths. 
          #  MIDI::Sequence#length_to_delta takes a note length (a multiple of a quarter note) 
          #  and returns the delta time given the sequence's current ppqn (pulses per quarter note) 
          #  setting. 1 is a quarter note, 1.0/32.0 is a 32nd note (use floating-point numbers 
          #  to avoid integer rounding), 1.5 is a dotted quarter, etc."
          start = midi_ticks_to_seconds(event.time_from_start, seq)
          duration = midi_ticks_to_seconds(event.delta_time, seq)  # Assigned above in test for 0.0 dur         
          volume = event.velocity
          pitch = event.note           
          # Validate note properties and continue if invalid.  Someday understand MIDI and midilib better
          next if duration == 0.0 || volume == 0      
          
          if (measure = seq_measures.measure_for_event(event))
            measure = measure.measure_number
          end
          
          if channel.nil? or start.nil? or duration.nil? or volume.nil? or pitch.nil? # or instrument.nil? 
            raise AleatoricFailedMidiLoadException, "Load of file #{file_name} failed on note # #{note_num}. start #{start} duration #{duration} volume #{volume} note(pitch) #{pitch} channel #{channel}"
          else
            # VERBOSE
            puts "Note #{notes_loaded_count} loaded for channel #{channel} for track #{track}"
            notes_loaded_count += 1
            # /VERBOSE
                        
            # Construct new note from base properties
            note = Note.new("#{note_num}", {:instrument=>instrument, :channel=>channel, :start=>start, :duration=>duration, :amplitude=>volume, :pitch=>pitch})
            # Add measure value -- this is a note built-in attr that is used by kw 'import' but isn't part of note output to score        
            note.measure = measure
            ret_notes << note            
            
            instrument = nil; 
            channel = nil; start = nil; duration = nil; volume = nil; pitch = nil; measure = nil          
            note_num += 1
          end          
        end
      end      
    end
    
    return ret_notes        
  end
  alias load_notes_from_file load
    
  def save(file_name)    
    if include_win? or include_mac?
    File.open(file_name, 'wb') {|file| @seq.write file}  
    end
  end
  alias render save
  
  private
  
  def seconds_to_beats(secs)
    if include_win? or include_mac?
    secs / (60.0 / @bpm)
    end
  end
  
  # Conversion formula from here: 
  #  http://groups.google.com/group/ruby-midi/browse_thread/thread/8e596632f0d239e7?pli=1
  def midi_ticks_to_seconds(ticks, sequence) 
    ticks / sequence.ppqn.to_f / @bpm.to_f * 60.0
  end   
    
  # For testing only, exposed with temporary make private methods public in one midi_test.rb test
  def seq
    if include_win? or include_mac?    
    @seq
    end
  end  
end
