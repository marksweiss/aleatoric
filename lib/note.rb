module Aleatoric

class Note    
  def initialize(attrs=nil)
    # TODO enforce contract of required args in hash? But we allow properties to be set later
    @note_attrs = {}
    @ordered_keys = [:instrument, :start, :duration, :amplitude, :pitch]       
    attrs ||= {}
    attrs.each {|name, val| self.method_missing(name, val)}
  end
  
  # TODO Change to use adapters for specific output formats. Some kind of NoteWriter ...
  # Which is presumably a singleton that is dependency injected into each note without
  #  the client code needing to do more than set it once globally.  Every note passes itself
  #  to the writer to write
  def to_s
    s = ""
    @ordered_keys.each {|k| s << "#{k.to_s} = #{@note_attrs[k]}\n"}
    s << "\n"
    s
  end

  private

  def method_missing(name, val)  
    @note_attrs[name] = val
    @ordered_keys << name unless @ordered_keys.include? name
    def_accessor name
  end
  
  def def_accessor(name)
    self.class.class_eval %Q{
      def #{name}(val=nil)
        if val == nil then
          @note_attrs[:#{name}]
        else
          @note_attrs[:#{name}] = val
          self
        end
      end
    }
  end  
end

end
