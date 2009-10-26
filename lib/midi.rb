require 'global'

require 'rubygems'

require 'dl/import'
require 'midilib/sequence'
require 'midilib/consts'

require 'ruby-debug' ; Debugger.start

class AleatoricIllegalMidiOperationException < Exception; end

# TODO - need a Composer keyword to set bpm, child of format midi, make that a block
class MidiManager

  include MIDI
  include Aleatoric

  attr_reader :name, :bpm
  
  DEFAULT_BPM = 120
  
  def initialize(name=nil, bpm=nil)
    # custom init steps
    @name = name || 'Sequence Name'
    @bpm = bpm || DEFAULT_BPM
    @channel_tracks = {}
    @channel_instruments = {}

    # midilib init steps
    @seq = Sequence.new()
    # Create a first track for the sequence. This holds tempo events and stuff like that.
    track = Track.new(@seq)
    @seq.tracks << track
    # TODO support Tempo in Composer
    track.events << Tempo.new(Tempo.bpm_to_mpq(@bpm))
    track.events << MetaEvent.new(META_SEQ_NAME, @name)    
  end
  
  # NOTE: MIDI doesn't require this, but this interface assumes each track will be
  #  assigned to one and only one channel.  The interface hides tracks entirely
  #  (since they are  MIDI concept with no analog in Composer) and to the user
  #  their Composer script assigns Notes (Composer Notes) to Channels (MIDI channels)
  #  but even that isn't actually exposed in Composer (other than the abstract
  #  concept of multiple Channels available if you set format == :midi
  def channel(channel)
    if channel_nil?(channel)
      track = Track.new(@seq)
      @seq.tracks << track
      @channel_tracks[channel] = track
    end
    @channel_tracks[channel]
  end

  def channel_nil?(channel)
    @channel_tracks[channel].nil?
  end
  
  def instrument(channel, instrument, delta_time=0)
    self.channel(channel) if channel_nil?(channel)    
    @channel_tracks[channel].events << ProgramChange.new(channel, instrument, delta_time)
    @channel_instruments[channel] = instrument
  end

  def channel_instrument(channel)
    @channel_instruments[channel]
  end
  
  # Args named with MIDI semantics. Converting to Composer semantics:
  #  note == pitch, velocity == amplitude == volume, delta_time == duration  
  def add_note(channel, note, velocity, delta_time)   
    channel(channel) if channel_nil?(channel)
    note_length = @seq.length_to_delta(seconds_to_beats(delta_time))    
    @channel_tracks[channel].events << NoteOnEvent.new(channel, note, velocity, 0)
    @channel_tracks[channel].events << NoteOffEvent.new(channel, note, velocity, note_length)
  end
  
  # NOTE: Breaks encapsulation and really only intended for unit testing add_note()
  def channel_notes(channel)
    notes = []
    if not channel_nil? channel
      @channel_tracks[channel].each {|note| notes << note if note.note?}
    end
    notes
  end
    
  def save(file_name)  
    File.open(file_name, 'wb') {|file| @seq.write file}  
  end
  alias render save
  
  private
  
  def seconds_to_beats(secs)
    secs / (60.0 / @bpm)
  end
  
  # For testing only, exposed with temporary make private methods public in one midi_test.rb test
  def seq
    @seq
  end
  
  # def delta_to_note_str(duration)
  #  DUR_TO_NOTE_STR[duration]
  #end
  #alias dur_to_note_str delta_to_note_str
  #alias dur_to_note delta_to_note_str
  #alias delta_to_note delta_to_note_str
  
  #DUR_TO_NOTE_STR	=	{WHL => 'whole', 
  #                   HLF => 'half', 
  #                   QRTR => 'quarter', 
  #                   EITH => 'eighth', 
  #                   EITH => '8th', 
  #                   SXTNTH => 'sixteenth', 
  #                   SXTNTH => '16th', 
  #                   THRTYSCND => 'thirty second', 
  #                   THRTYSCND => 'thirtysecond', 
  #                   THRTYSCND => '32nd', 
  #                   SXTYFRTH => 'sixty fourth', 
  #                   SXTYFRTH => 'sixtyfourth', 
  #                   SXTYFRTH => '64th'}                   
  
  # We don't need this right now, but it will be annoying to do it over if we ever do  
  #note_str_to_delta(note_str)
  #  NOTE_STR_TO_DUR[note_str]
  #end
  #alias note_str_to_dur note_str_to_delta
  #alias note_to_dur note_str_to_delta
  #alias note_to_delta note_str_to_delta

  # We don't need this right now, but it will be annoying to do it over if we ever do
  # NOTE_STR_TO_DUR	=	{'whole' => WHL, 
  #                   'half' => HLF, 
  #                   'quarter' => QRTR, 
  #                   'eighth' => EITH, 
  #                   '8th' => EITH, 
  #                   'sixteenth' => SXTNTH, 
  #                   '16th' => SXTNTH, 
  #                   'thirty second' => THRTYSCND, 
  #                   'thirtysecond' => THRTYSCND, 
  #                   '32nd' => THRTYSCND, 
  #                   'sixty fourth' => SXTYFRTH, 
  #                   'sixtyfourth' => SXTYFRTH, 
  #                   '64th' => SXTYFRTH}
  
end
