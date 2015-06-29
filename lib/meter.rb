require_relative 'global'

module Aleatoric

# Models musical meter by setting beats per measure, beat length and measure duration. 
# Also supports quantizing notes in a Score to align with closest beats in the measure -- 
# that is to force the notes to land on the closest beats.
class Meter
  
  def initialize(quantizing=true, beats_per_measure=4, beat_length=QRTR)
    @quantizing = quantizing
    @beats_per_measure = beats_per_measure
    @beat_length = beat_length
    @measure_dur = @beats_per_measure * @beat_length
  end
  
  # Accessor to test or set whether this Meter is quantizing
  def quantizing?(val=nil)
    @quantizing = val if val != nil
    @quantizing
  end

  # Accessor to test or set the value for beats per measure
  def beats_per_measure(val=nil)
    @beats_per_measure = val if val != nil
    @beats_per_measure
  end
  
  # Accessor to test or set the value for beat length
  def beat_length(val=nil)
    @beat_length = val if val != nil
    @beat_length
  end
      
  # Algorithm
  #  Count up duration of notes
  #  If adds up to @measure_dur Then exit
  #  Else
  #   ActualDur = Sum(ActualNotes_Duration)
  #   NoteDurFactor = @measure_dur/ActualDur
  #   For Each ActualNote
  #     ActualNote_NewDuration *= NoteDurFactor
  #     ActualNote_NewStart = ActualNote_Start + (ActualNote_NewDuration - ActualNote_Duration)
  #   AdjustNotes
  #
  # Assumes notes are a measure of notes to be quantized to @beat_length, @beats_per_measure
  # @param [Array<Aleatoric::Note>] an Array of Notes to be quantized
  def quantize(notes)
    new_notes = notes
    if @quantizing
      # Count up duration of notes
      note_durs = notes.collect {|note| note.duration}
      tot_dur = note_durs.inject(0) {|sum, dur| sum + dur}    
      # If adds up to @measure_dur Then exit (i.e., here, just don't change the input)
      if tot_dur != @measure_dur
        note_adj_factor = @measure_dur.to_f / tot_dur.to_f
        # For Each ActualNote
        #   ActualNote_NewDuration *= NoteDurFactor
        #   ActualNote_NewStart = ActualNote_Start + (ActualNote_NewDuration - ActualNote_Duration)       
        new_notes = notes.collect do |note| 
          new_duration = note.duration * note_adj_factor
          note.start(note.start + (new_duration - note.duration)) if note.start > 0.0
          note.duration(new_duration)        
          note
        end
      end
    end
    new_notes
  end
  
end

end
