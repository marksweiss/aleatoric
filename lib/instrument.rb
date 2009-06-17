module Aleatoric

# class Sequence or Instrument
# a function that takes a hash of args

# Basically a functor
# Bind an object to an impl and set of args, then can keep passing args
#  and as long as the @player can handle them you're good
# play() returns a note

class Instrument
  attr_accessor :func, :args
  protected :func, :args

  def initialize(lambda_exp, args)
    # TODO validate lambda_exp.class == Proc
    @func = lambda_exp
    @args = args
  end

  def play(args={})
    args = @args if args.length == 0
    note = @func.call args
    note
  end
  
  def play_to_s(args={})
    self.play(args).to_s
  end
end

class LoopInstrument < Instrument
  def loop_play(num_loops, args={})
    ret_notes = []
    num_loops.times do
      ret_notes << self.play(args)
    end
    ret_notes
  end

  def loop_play_to_s(num_loops, args={})
    ret = ""
    ret_notes = loop_play(num_loops, args)
    ret_notes.length.times do |j|
      ret << ret_notes[j].to_s
    end
    ret
  end  
end

class InjectInstrument < Instrument
  # User provides a function that transforms the arguments on each iteration of the loop
  #  in which the args are used to pass to play.  So we can have an object generating
  #  notes and maintaining and updating state of each note parameter on each loop iteration
  def initialize(lambda_exp, args, arg_transformer_lambda_exp)
    super(lambda_exp, args)
    @arg_transformer = arg_transformer_lambda_exp
  end
  
  def inject_play(num_loops, args={})
    ret_notes = []
    # This instrument transforms @args on each loop iteration, and maintains that state
    #  so the usage is that if you pass in args on a call to inject_play, that that call
    #  will make those args the new baseline for the object
    @args = args if args.length > 0
    num_loops.times do |j|
      ret_notes << self.play(@args)
      @args = @arg_transformer.call @args
    end
    ret_notes
  end

  def inject_play_to_s(num_loops, args={})
    ret = ""
    ret_notes = inject_play(num_loops, args)
    ret_notes.length.times do |j|
      ret << ret_notes[j].to_s
    end
    ret
  end
end


# TODO - figure out how to integrate into scripts and composer.rb processing and actually use it
# instrument_def
instrument_glissando = Aleatoric::InjectInstrument.new(
  lambda_exp = lambda {Note.new(_dummy_name, self.args)}, 
  args = { "instrument"=>1, 
    "start"=>0.0, 
    "duration"=>1.0, 
    "amplitude"=>1000, 
    "pitch"=>7.01, 
    "func_table"=>1}, 
  # TODO - Do something interesting with this transformation
  # TODO Have some 'instrument' keyword so this whole block is just ignored - it's really
  #  embedded Ruby and not Composer
  arg_transformer_lambda_exp = lambda {|trans_args| 
    trans_args["instrument"] = trans_args["instrument"]
    trans_args["start"] = trans_args["start"]
    trans_args["duration"] = trans_args["duration"]
    trans_args["amplitude"] = trans_args["amplitude"]
    trans_args["pitch"] = trans_args["pitch"]
    trans_args["func_table"] = trans_args["func_table"]
    trans_args}
)
# end_instrument_def


# Same as above but generate() returns a list of notes


end