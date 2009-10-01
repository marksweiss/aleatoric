$LOAD_PATH << "..\\lib"
require 'midi'
require 'test/unit'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

class MidiManager_Test < Test::Unit::TestCase
  # def setup
  # end
  # def teardown
  # end

  def test__initialize
    puts "test__initialize ENTERED"

    midi = MidiManager.new
    assert(midi != nil)
    
    midi_named = MidiManager.new('foo')
    assert(midi_named != nil && midi_named.name == 'foo')
    
    puts "test__initialize COMPLETED"
  end
  
  def test__channel_channel_nil
    puts "test__channel_channel_nil ENTERED"

    midi = MidiManager.new
    assert(midi != nil)
    
    midi.channel 1
    assert(! midi.channel_nil?(1))

    puts "test__channel_channel_nil COMPLETED"
  end  
  
  def test__instrument_channel_instrument
    puts "test__instrument ENTERED"

    midi = MidiManager.new
    assert(midi != nil)
    
    midi.instrument(channel=1, instrument=100, delta_time=1.0)
    assert(midi.channel_instrument(1) == 100)

    puts "test__instrument COMPLETED"
  end  
  
  def test__add_note
    puts "test__add_note ENTERED"

    midi = MidiManager.new
    assert(midi != nil)
    
    # note here == pitch in MIDI lingo, 64 == C4
    midi.add_note(channel=1, note=64, velocity=100, delta_time=4.0)
    midi_notes = midi.channel_notes(1)
    # length == 2 because this sets NoteOn and NoteOff
    assert(midi_notes.length == 2)
    # returns true if event is either NoteOn or NoteOff
    assert(midi_notes[0].note? && midi_notes[1].note?)

    puts "test__add_note COMPLETED"
  end  
  
end