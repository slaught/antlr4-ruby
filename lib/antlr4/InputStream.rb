#  Vacuum all input from a string and then treat it like a buffer. 

class InputStream 
    
    attr_accessor :index, :strdata, :name, :size, :data
    def initialize(data)
        @name = "<empty>"
        @strdata = data
        @index = 0
        @data = @strdata.bytes 
        @size = @data.length
    end

    # Reset the stream so that it's in the same state it was
    #  when the object was created *except* the data array is not
    #  touched.
    #
    def reset()
        @index = 0
    end

    def consume()
        if self.index >= self.size then
            # assert self.LA(1) == Token::EOF
            raise Exception.new("cannot consume EOF")
        end
        self.index = self.index + 1
    end
    def LA(offset)
        if offset==0 then
            return 0 # undefined
        end
        if offset<0 then
            offset = offset + 1 # e.g., translate LA(-1) to use offset=0
        end
        pos = @index + offset - 1
        if pos < 0 or pos >= @size then # invalid
            return Token::EOF
        end
        return self.data[pos]
    end

    def LT(offset)
        return self.LA(offset)
    end

    # mark/release do nothing; we have entire buffer
    def mark()
        return -1
    end

    def release(marker)
    end

    # consume() ahead until p==_index; can't just set p=_index as we must
    # update line and column. If we seek backwards, just set p
    #
    def seek(_index)
        if _index<=self.index then
            self.index = _index # just jump; don't update stream state (line, ...)
            return
        end
        # seek forward
        self.index = [_index, self.size].min
    end

    def getText(start, stop)
        if stop >= self.size then
            stop = self.size - 1
        end
        if start >= self.size then
            return ""
        else
            return self.strdata[start..stop] # start = inital, stop == offset?
        end
    end
    
    def to_s
        return self.strdata
    end
end

