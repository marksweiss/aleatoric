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
      if RUBY_PLATFORM.include?('mswin')
      system("consound -m0 -d -g -s -W -o#{out_file_name} #{$csound_orc_file_name} #{score_file_name}")
      else
      system("csound -m7 -d -g -s -A -o#{out_file_name} #{$csound_orc_file_name} #{score_file_name}")        
      end
    when :midi
      # no-op
      # TODO Make this play interactively?
    end
  end

end

end