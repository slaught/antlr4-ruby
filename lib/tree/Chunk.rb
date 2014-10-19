class Chunk
end

class TagChunk < Chunk

    attr_accessor :tag, :label
    def initialize(tag, label=nil)
        self.tag = tag
        self.label = label
    end

    def to_s
        if self.label.nil?
            self.tag
        else
            "#{self.label}:#{self.tag}"
        end
    end
end
class TextChunk < Chunk

     attr_accessor :text
    def initialize(text) 
        self.text = text
    end

    def to_s
        "'#{ self.text }'"
    end

end
