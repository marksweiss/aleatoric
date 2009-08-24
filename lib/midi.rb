require 'dl/import'
require 'rubygems'
require 'midilib'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

module Enumerable
  def rest
    return [] if empty?
    self[1..-1]
  end
end

class ChannelManager
  def initialize(total)
    @total = total
    reset
  end

  def reset
    @channels = (0...@total).to_a
  end

  def allocate(channel=nil)
    raise "No channels left to allocate" if @channels.empty?
    return @channels.shift if channel.nil?
    raise "Channel unavailable" unless @channels.include?(channel)
    @channels.delete(channel)
    return channel
  end

  def release(channel)
    @channels.push(channel)
    @channels.sort!
  end
end

class FileMIDI
  attr_reader :interval
  DFLT_BPM = 100
  NUM_CHANNELS = 16

  def initialize(bpm=nil)  
    @bpm = bpm || DFLT_BPM      
    @interval = 60.0 / @bpm
    @channel_manager = ChannelManager.new(NUM_CHANNELS)

    @base = Time.now.to_f
    @seq = MIDI::Sequence.new

    header_track = MIDI::Track.new(@seq)
    @seq.tracks << header_track
    header_track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(@bpm))
    
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
  alias add_note_event play

  def save(output_filename)
    File.open(output_filename, 'wb') do |file|
      @seq.write(file)
    end
  end
  
  private
  def seconds_to_delta(secs)
    bps = 60.0 / @bpm
    beats = secs / bps
    return @seq.length_to_delta(beats)
  end  
end
