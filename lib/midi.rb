# Start looking for MIDI module classes in the directory above this one.
# This forces us to use the local copy, even if there is a previously
# installed version out there somewhere.
$LOAD_PATH[0, 0] = File.join(File.dirname(__FILE__), '..', 'lib')

require 'midilib/sequence'
require 'midilib/consts'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

class AleatoricIllegalMidiOperationException < Exception; end

class MidiManager

  include MIDI

  attr_reader :name
  
  def initialize(name=nil)
    # custom init steps
    @name = name || 'Sequence Name'
    @channel_tracks = {}    

    # midilib init steps
    @seq = Sequence.new()
    # Create a first track for the sequence. This holds tempo events and stuff like that.
    track = Track.new(@seq)
    @seq.tracks << track
    track.events << Tempo.new(Tempo.bpm_to_mpq(120))
    track.events << MetaEvent.new(META_SEQ_NAME, @name)    
  end
  
  def channel(channel)
    @channel_tracks[channel] ||= Track.new(@seq)
  end

  def instrument(channel, instrument, delta_time=0)
    self.channel(channel) if channel_nil?(channel)
    @channel_tracks[channel].events << ProgramChange.new(channel, instrument, delta_time)
  end

  # Args named with MIDI semantics. Converting to Composer semantics:
  #  note == pitch, velocity == amplitude == volume, delta_time == duration  
  def add_note(channel, note, velocity, delta_time) 
    note_length = @seq.note_to_delta(delta_to_note_str(delta_time))
    @channel_tracks[channel].events << NoteOnEvent.new(channel, note, velocity, 0)
    @channel_tracks[channel].events << NoteOffEvent.new(channel, note, velocity, note_length)
  end
  
  def save(file_name)
    File.open(file_name, 'wb') {|file| @seq.write file}  
  end
  alias render save
  
  private
  
  def channel_nil?(channel)
    @channel_tracks[channel].nil?
  end

  NOTE_STR_TO_DUR	=	{'whole' => WHL, 
                     'half' => HLF, 
                     'quarter' => QRTR, 
                     'eighth' => EITH, 
                     '8th' => EITH, 
                     'sixteenth' => SXTNTH, 
                     '16th' => SXTNTH, 
                     'thirty second' => THRTYSCND, 
                     'thirtysecond' => THRTYSCND, 
                     '32nd' => THRTYSCND, 
                     'sixty fourth' => SXTYFRTH, 
                     'sixtyfourth' => SXTYFRTH, 
                     '64th' => SXTYFRTH}

  DUR_TO_NOTE_STR	=	{WHL => 'whole', 
                     HLF => 'half', 
                     QRTR => 'quarter', 
                     EITH => 'eighth', 
                     EITH => '8th', 
                     SXTNTH => 'sixteenth', 
                     SXTNTH => '16th', 
                     THRTYSCND => 'thirty second', 
                     THRTYSCND => 'thirtysecond', 
                     THRTYSCND => '32nd', 
                     SXTYFRTH => 'sixty fourth', 
                     SXTYFRTH => 'sixtyfourth', 
                     SXTYFRTH => '64th'}                   
                     
  note_str_to_delta(note_str)
    NOTE_STR_TO_DUR[note_str]
  end
  alias note_str_to_dur note_str_to_delta
  alias note_to_dur note_str_to_delta
  alias note_to_delta note_str_to_delta

  delta_to_note_str(duration)
    DUR_TO_NOTE_STR[duration]
  end
  alias dur_to_note_str delta_to_note_str
  alias dur_to_note delta_to_note_str
  alias delta_to_note delta_to_note_str
  
end
