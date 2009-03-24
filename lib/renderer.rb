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

  def render(renderer, out_file, score_file=nil)  
    if renderer.to_sym == :csound    
      system("consound -m0 -d -g -s -W -o#{out_file} #{self.orchestra} #{score_file}")
    elsif renderer.to_sym == :midi
      # TODO render midi
    end
  end

end

end