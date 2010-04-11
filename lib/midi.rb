include Aleatoric 

require 'rubygems'

if include_win? or include_mac?
require 'dl/import'
require 'rubygems'
require 'midilib/sequence'
require 'midilib/consts'
end

# require 'ruby-debug' ; Debugger.start

class AleatoricIllegalMidiOperationException < Exception; end

# TODO - need a Composer keyword to set bpm, child of format midi, make that a block
class MidiManager

  if include_win? or include_mac?
  include MIDI
  end
  include Aleatoric

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
    channel(channel) if channel_nil?(channel)
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
  
  # For testing only, exposed with temporary make private methods public in one midi_test.rb test
  def seq
    if include_win? or include_mac?    
    @seq
    end
  end  
end
