$LOAD_PATH << psub("../lib")

require 'rubygems'

if include_win? or include_mac?
require 'dl/import'
require 'rubygems'
require 'midilib/sequence'
require 'midilib/consts'
end


require 'ruby-debug' ; Debugger.start

class AleatoricIllegalMidiOperationException < Exception; end
class AleatoricFailedMidiLoadException < Exception; end


# TODO - need a Composer keyword to set bpm, child of format midi, make that a block
class MidiManager

  if include_win? or include_mac?
  include MIDI
  end
  include Aleatoric
  require 'note'

  attr_reader :name, :bpm
  
  DEFAULT_BPM = 120
  
  def initialize(name=nil, bpm=nil)
    if include_win? or include_mac?
    # custom init steps
    @name = name || 'Sequence Name'
    @bpm = bpm || DEFAULT_BPM
    @channel_tracks = {}
    @channel_instruments = {}

    # midilib init steps
    @seq = MIDI::Sequence.new()
    # Create a first track for the sequence. This holds tempo events and stuff like that.
    track = MIDI::Track.new(@seq)
    @seq.tracks << track
    # TODO support Tempo in Composer
    track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(@bpm))
    track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, @name)
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
      track = Track.new(@seq)
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
    end
  end

  def channel_instrument(channel)
    if include_win? or include_mac?    
    @channel_instruments[channel]
    end
  end
  
  # Args named with MIDI semantics. Converting to Composer semantics:
  #  note == pitch, velocity == amplitude == volume, delta_time == duration  
  def add_note(channel, note, velocity, delta_time)       
    if include_win? or include_mac?
    self.channel(channel) if channel_nil?(channel)
    note_length = @seq.length_to_delta(seconds_to_beats(delta_time))        
    @channel_tracks[channel].events << NoteOnEvent.new(channel, note, velocity, 0)
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
  
  def load(file_name)
    ret_notes = []
        
    # Create a new, empty sequence.
    seq = MIDI::Sequence.new    
    # Read the contents of a MIDI file into the sequence.
    File.open(file_name, 'rb') do |file|
      seq.read(file)
    end
        
    note_num = 0
    # Get the tracks from the loaded file
    tracks = seq.collect
    # Get the measures from the loaded file
    seq_measures = seq.get_measures
    # Get the (note) events from each track
    tracks.each do |track|      
      # Get all events from the track
      events = track.collect
      # Init state of properties collected from each event
      channel = nil; instrument = nil; start = nil; duration = nil; volume = nil; pitch = nil
      measure = nil
      # Iterate events and only extract props from MIDI events that have what we need
      events.each do |event|        
        next if not (event.program_change? or event.note?)
      
        # TODO THIS CRAP GOES AWAY
        # Get the measure information, have to parse it out of string from the midilib API
        # Set it for this series of note events if we haven't set it yet
        # event_measure = seq_measures.measure_for_event(event).to_s.strip
        # If the MIDI::Measure object returned is nil, then to_s() is '', check for length
        # if event_measure.length > 0
          # Format of measure_for_event(e):   'measure 1  0-1919  4/4   1.0 qs metronome' 
          # So match first number and retrieve from regex global var capturing first match                    
        #  event_measure =~ /\d+/          
        #  measure = $&.to_i
        # end
        
        # TEMP DEBUG
        # breakpoint if event.program_change? and not event.program
        
        if event.program_change?       
          # TEMP DEBUG
          # breakpoint
          
          instrument = event.program

          # TEMP DEBUG
          # puts("instr #{instrument}")
        end
        
        if event.note?  

          # TEMP DEBUG
          # puts "note " + event.channel.to_s
        
          channel = event.channel
          start = midi_ticks_to_seconds(event.time_from_start)
          duration = midi_ticks_to_seconds(event.delta_time)
          volume = event.velocity
          pitch = event.note
          
          if (measure = seq_measures.measure_for_event(event))
            measure = measure.measure_number
          end
          
          if channel.nil? or start.nil? or duration.nil? or volume.nil? or pitch.nil? # or instrument.nil? 
            # TEMP DEBUG
            # debug_log "Load of file #{file_name} failed on note # #{note_num}. channel #{channel}  instrument #{instrument}  start #{start}  duration #{duration}  volume #{volume}  pitch #{pitch}"            
            raise AleatoricFailedMidiLoadException, "Load of file #{file_name} failed on note # #{note_num}"
          else
          
            # TEMP DEBUG
            # puts "note 2 " + instrument.to_s

            # Construct new note from base properties
            note = Note.new("#{note_num}", {:instrument=>instrument, :channel=>channel, :start=>start, :duration=>duration, :amplitude=>volume, :pitch=>pitch})
            # Add measure value -- this is a note built-in attr that is used by kw 'import' but isn't part of note output to score        
            note.measure = measure
            ret_notes << note
            # instrument = nil; 
            channel = nil; start = nil; duration = nil; volume = nil; pitch = nil; measure = nil          
            note_num += 1
          end          
        end
      end      
    end
    
    return ret_notes        
  end
    
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
  
  def midi_ticks_to_seconds(ticks)
    if include_win? or include_mac?
    ticks / 960.0
    end
  end  
  
  # For testing only, exposed with temporary make private methods public in one midi_test.rb test
  def seq
    if include_win? or include_mac?    
    @seq
    end
  end  
end
