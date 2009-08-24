require 'conf_csound'
require 'util'
require 'singleton'

module Aleatoric

class Renderer
  include Singleton
    
  def method_missing(name, val)
    def_accessor(name, val)    
    self.send(name.to_sym, val)
  end
  
  private
  def def_accessor(name, val)
    self.class.class_eval %Q{
      def #{name}(val=nil)
        if val == nil then
          @#{name}
        else
          @#{name} = val
          self
        end
      end
    }
  end
  public

  def render(render_format, out_file_name, score_file_name=nil)
    case render_format.to_sym
    when :csound
      # TODO From config, base path, should be a setting used all over project
      system("consound -m0 -d -g -s -W -o#{out_file_name} #{$csound_orc_file_name} #{score_file_name}")
    when :midi
      # no-op
      # TODO Make this play interactively?
    end
  end

end

class FileMIDI
  attr_reader :interval

  def initialize(bpm)
    @bpm = bpm
    @interval = 60.0 / bpm
    @channel_manager = ChannelManager.new(16)

    @base = Time.now.to_f
    @seq = MIDI::Sequence.new

    header_track = MIDI::Track.new(@seq)
    @seq.tracks << header_track
    header_track.events << MIDI::Tempo.new(MIDILIB::Tempo.bpm_to_mpq(@bpm))
    
    @tracks = []
    @last = []
  end

  def new_track(channel)
    track = MIDI::Track.new(@seq)
    @tracks[channel] = track
    @seq.tracks << track
    return track
  end

  def program_change(channel, preset)
    track = new_track(channel)
    # Bind the preset to channel 0, since each channel has it's own track
    track.events << MIDI::ProgramChange.new(0, preset, 0)
  end

  def channel_track(channel)
    @tracks[channel] || new_track(channel)
  end

  def instrument(preset, channel=nil)
    channel = @channel_manager.allocate(channel)
    program_change(channel, preset)
    return Instrument.new(self, channel)
  end

  def reset
    @channel_manager.reset
  end

  def play(channel, note, duration=1, velocity=100, time=nil)
    time ||= Time.now.to_f
    on_delta = time - (@last[channel] || time)
    off_delta = duration * @interval
    @last[channel] = time
    track = channel_track(channel)
    track.events << MIDI::NoteOnEvent.new(0, note, velocity, seconds_to_delta(on_delta))
    track.events << MIDI::NoteOffEvent.new(0, note, velocity, seconds_to_delta(off_delta))
  end

  def seconds_to_delta(secs)
    bps = 60.0 / @bpm
    beats = secs / bps
    return @seq.length_to_delta(beats)
  end

  def save(output_filename)
    File.open(output_filename, 'wb') do |file|
      @seq.write(file)
    end
  end
end

end