$LOAD_PATH << "..\\lib"
require 'midi'
require 'test/unit'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

# Super-elegant solution for temporarily getting access to private methods to test stolen from here:
#  http://blog.jayfields.com/2007/11/ruby-testing-private-methods.html
class Class
  def publicize_methods
    saved_private_instance_methods = self.private_instance_methods
    self.class_eval {public(*saved_private_instance_methods)}
    yield
    self.class_eval {private(*saved_private_instance_methods)}
  end
end

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
    
    midi.instrument(channel=0, instrument=100)
    assert(midi.channel_instrument(0) == 100)
    midi.instrument(channel=1, instrument=101)
    assert(midi.channel_instrument(1) == 101)

    puts "test__instrument COMPLETED"
  end  
  
  def test__add_note
    puts "test__add_note ENTERED"

    bpm = 60
    midi = MidiManager.new('Test Manager', bpm)
    assert(midi != nil)
    
    # note here == pitch in MIDI lingo, 64 == C4
    note_length = 4.0
    midi.add_note(channel=0, note=64, velocity=100, delta_time=note_length)
    midi_notes = midi.channel_notes(0)
    # length == 2 because this sets NoteOn and NoteOff
    assert(midi_notes.length == 2)
    # returns true if event is either NoteOn or NoteOff
    assert(midi_notes[0].note? && midi_notes[1].note?)
    
    # note.delta_time == 1920
    # 60.0 / (4.0 / 60)
    # MIDI::Sequence.length_to_delta(seconds_per_min / (note_length_in_seconds / beats_per_min))
    # MIDI Sequence has 480 ticks per quarter note when bpm = 60, so whole == 1920
    secs_per_min = 60.0    
    MidiManager.publicize_methods do
      assert(midi_notes[1].delta_time == midi.seq.length_to_delta(midi.seconds_to_beats(note_length)))
    end
      
    puts "test__add_note COMPLETED"
  end
  
  def test__midi_save
    puts "test__midi_save ENTERED"

    midi = MidiManager.new
    assert(midi != nil)
    
    # note here == pitch in MIDI lingo, 64 == C4
    midi.instrument(channel=0, instrument=1)
    midi.add_note(channel=0, note=64, velocity=100, delta_time=4.0)
    midi.instrument(channel=1, instrument=20)
    midi.add_note(channel=1, note=65, velocity=100, delta_time=4.0)
    # midi_notes = midi.channel_notes(0)
    # midi_notes = midi.channel_notes(1)
    midi.save('midi_test.mid')

    assert(File.size('midi_test.mid') > 0)

    puts "test__midi_save COMPLETED"  
  end
  
end