module Aleatoric

# class Sequence or Instrument
# a function that takes a hash of args

# Basically a functor
# Bind an object to an impl and set of args, then can keep passing args
#  and as long as the @player can handle them you're good
# play() returns a note

class Instrument
  attr_accessor :player, :default_args

  def initialize(default_args={}, lambda_exp=nil)
    # TODO validate lambda_exp.class == Proc
    @player = lambda_exp
    @default_args = default_args
  end

  def play(args={})
    args = @default_args if args.length == 0
    note = @player.call args
    note
  end
  
  def play_args
    @default_args.keys
  end
end

# Same as above but generate() returns a list of notes
class GeneratorInstrument < Instrument
  @@index_arg_key = 'index'

  attr_accessor :notes

  def generate(loop_len, args={})
    notes = []
    args[@@index_arg_key, 0]
    
    loop_len.times do |j|
      args[@@index_arg_key] = j
      notes << play(args)
    end
    
    notes
  end

end

end