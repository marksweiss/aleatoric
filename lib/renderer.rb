# require 'conf_csound'
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
  
    # Set the path to CSound. Installer for Mac sets path correctly but Windows does not and you have to add 
    #  it to PATH yourself (of course).  Rather than add this reasonably arcane and technical step to install 
    #  instructions we just assume default CSound install path (which hopefully doesn't ever change) and set a global here    
    if include_win?
      csound_path = %q{C:\Program Files\Csound\bin\csound}
    elsif include_mac?
      csound_path = 'csound'
    else
      raise "ONLY WINDOWS AND MAC ARE SUPPORTED FOR CSOUND RENDERING AT THIS TIME"    
    end
  
    case render_format.to_sym
    when :csound
      # TODO From config, base path, should be a setting used all over project
      if include_win? # RUBY_PLATFORM.include?('mswin')
        system("#{csound_path} -m0 -d -g -s -W -o#{out_file_name} #{self.orchestra} #{score_file_name}")
      else
        system("#{csound_path} -m7 -d -g -s -A -o#{out_file_name} #{self.orchestra} #{score_file_name}")        
      end
    when :midi
      # no-op
      # TODO Make this play interactively?
    end
  end

end

end