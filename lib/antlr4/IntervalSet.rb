class IntervalSet
    extend Forwardable

    attr_accessor :intervals , :readonly 
    attr_accessor :_internal 
    def initialize 
        self.intervals = Array.new
        self.readonly = false
        @_internal = Set.new
    end
    def_delegators :@intervals, :each, :map 
    include Enumerable
    
    def self.of(a,b)
       s = IntervalSet.new
       s.addRange(a..b)
       s
    end

    def getMinElement
        intervals.first
    end
    def addOne(v)
        self.addRange(v..v)
    end

    def addRange(v)
        type_check(v, Range)
        if self.intervals.empty? then 
            self.intervals.push(v)
        else
            # find insert pos
            k = 0
            for i in self.intervals do
                # distinct range -> insert
                if v.stop<i.start then
                    self.intervals.insert(k, v)
                    return
                # contiguous range -> adjust
                elsif v.stop==i.start 
                    self.intervals[k] = v.start..i.stop
                    return
                # overlapping range -> adjust and reduce
                elsif v.start<=i.stop
                    self.intervals[k] = [i.start,v.start].min() ..  ([i.stop,v.stop].max())
                    self.reduce(k)
                    return
                end
                k = k + 1
            end
            # greater than any existing
            self.intervals.push(v)
        end
    end

    def addSet(other) # IntervalSet):
        if other.class == self.class 
          if other.intervals then
            other.intervals.each {|i| self.addRange(i) }
          end
        end
        return self
    end

    def reduce(k)
        # only need to reduce if k is not the last
        if k<self.intervals.length()-1 then
            l = self.intervals[k]
            r = self.intervals[k+1]
            # if r contained in l
            if l.stop >= r.stop
                self.intervals.pop(k+1)
                self.reduce(k)
            elsif l.stop >= r.start
                self.intervals[k] = l.start..r.stop
                self.intervals.pop(k+1)
            end
        end
    end
    def member?(item)
        return false if self.intervals.empty?
        self.intervals.each  do |i|
            if i.member? item  then
               return true
            end
        end
        false
    end

    def length
        xlen = 0
        self.intervals.each do |i|
          xlen = xlen + i.length 
        end
        return xlen
    end
  
    def remove(v)
        if not self.intervals.empty? then
            k = 0
            for i in self.intervals do
                # intervals is ordered
                if v<i.start then
                    return
                # check for single value range
#                elsif v==i.start and v==i.stop-1
                elsif v==i.start and v==i.stop
                    self.intervals.pop(k)
                    return
                # check for lower boundary
                elsif v==i.start
#                    self.intervals[k] = i.start+1..i.stop-1
                    self.intervals[k] = i.start+1..i.stop
                    return
                # check for upper boundary
                elsif v==i.stop-1
#                    self.intervals[k] = i.start..i.stop-1-1
                    self.intervals[k] = i.start..i.stop
                    return
                # split existing range
                elsif v<i.stop-1
                    x = i.start..(v-1)
                    i.start = v + 1
                    self.intervals.insert(k, x)
                    return
                end
                k = k + 1
            end
        end                  
    end

    def toString(tokenNames)
        if self.intervals.nil? or self.intervals.empty? then
            return "{}"
        end
#        "{#{intervals.to_s}}"
       StringIO.open  do |buf|
            if length > 1 then
                buf.write("{")
            end
            x = intervals.map { |i|
                i.map { |j| 
                    self.elementName(tokenNames, j).to_s
                }.join(', ')
            }.join(", ")
            buf.write(x) 
            if length > 1 then 
                buf.write("}")
            end
            return buf.string() 
       end
    end
    def elementName(tokenNames, a)
        if a==Token::EOF then
            return "<EOF>"
        elsif a==Token.EPSILON
            return "<EPSILON>"
        else
            return tokenNames[a]
        end
    end
end
