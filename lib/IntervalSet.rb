#from io import StringIO
# from antlr4.Token import Token

require 'stringio'
require 'Token'


class IntervalSet

    attr_accessor :intervals , :readOnly 
    attr_accessor :_internal 
    def initialize 
        self.intervals = nil
        self.readOnly = false
        @_internal = Set.new
        
    end

    include Enumerable

    def each(&block)
       #_internal.each(block)
      self.intervals.each(block)
    end
#        if self.intervals is not None:
#            for i in self.intervals:
#                for c in i:
#                    yield c
#
#    end
    def []=(item)
      @_internal[item]
    end
    def addOne(v)
        self.addRange(v..v)
    end

    def addRange(v)
        if self.intervals.nil? then
            self.intervals = Array.new
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
                    self.intervals[k] = v.start..i.stop-1
                    return
                # overlapping range -> adjust and reduce
                elsif v.start<=i.stop
                    self.intervals[k] = [i.start,v.start].min .. ([i.stop,v.stop].max -1)
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
                self.intervals[k] = l.start..r.stop-1
                self.intervals.pop(k+1)
            end
        end
    end
    def member?(item)
        return false if self.intervals.nil? 
        for i in self.intervals do
            if i.member? item 
               return true
            end
        end
        return false
    end

    def length
        xlen = 0
        for i in self.intervals do
            xlen = xlen + i.length 
        end
        return xlen
    end
  
    def remove(v)
        if not self.intervals.nil? then
            k = 0
            for i in self.intervals do
                # intervals is ordered
                if v<i.start then
                    return
                # check for single value range
                elsif v==i.start and v==i.stop-1
                    self.intervals.pop(k)
                    return
                # check for lower boundary
                elsif v==i.start
                    self.intervals[k] = i.start+1..i.stop-1
                    return
                # check for upper boundary
                elsif v==i.stop-1
                    self.intervals[k] = i.start..i.stop-1-1
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
        if self.intervals.nil? then
            return "{}"
        end
        "{#{intervals.to_s}}"
    end
#        StringIO.new() do |buf|
#            if length > 1 then
#                buf.write("{")
#            first = true
#            for i in self.intervals do
#                for j in i do
#                    if not first:
#                        buf.write(u", ")
#                    buf.write(self.elementName(tokenNames, j))
#                    first = false
#            if len(self)>1:
#                buf.write(u"}")
#            return buf.getvalue()
#       end
    def elementName(tokenNames, a)
        if a==Token.EOF then
            return "<EOF>"
        elsif a==Token.EPSILON
            return "<EPSILON>"
        else
            return tokenNames[a]
        end
    end
end
#class TestIntervalSet(unittest.TestCase):
#
#    def testEmpty(self):
#        s = IntervalSet()
#        self.assertIsNone(s.intervals)
#        self.assertFalse(30 in s)
#
#    def testOne(self):
#        s = IntervalSet()
#        s.addOne(30)
#        self.assertTrue(30 in s)
#        self.assertFalse(29 in s)
#        self.assertFalse(31 in s)
#
#    def testTwo(self):
#        s = IntervalSet()
##        s.addOne(30)
#        s.addOne(40)
#        self.assertTrue(30 in s)
#        self.assertTrue(40 in s)
#        self.assertFalse(35 in s)
#
#    def testRange(self):
#        s = IntervalSet()
#        s.addRange(range(30,41))
#        self.assertTrue(30 in s)
#        self.assertTrue(40 in s)
#        self.assertTrue(35 in s)
#
##    def testDistinct1(self):
#        s = IntervalSet()
#        s.addRange(range(30,32))
#        s.addRange(range(40,42))
#        self.assertEquals(2,len(s.intervals))
#        self.assertTrue(30 in s)
#        self.assertTrue(40 in s)
#        self.assertFalse(35 in s)
#
#    def testDistinct2(self):
#        s = IntervalSet()
#        s.addRange(range(40,42))
#        s.addRange(range(30,32))
##        self.assertEquals(2,len(s.intervals))
#        self.assertTrue(30 in s)
#        self.assertTrue(40 in s)
#        self.assertFalse(35 in s)
#
#    def testContiguous1(self):
#        s = IntervalSet()
#        s.addRange(range(30,36))
#        s.addRange(range(36,41))
#        self.assertEquals(1,len(s.intervals))
#        self.assertTrue(30 in s)
#        self.assertTrue(40 in s)
#        self.assertTrue(35 in s)
#
#    def testContiguous2(self):
#        s = IntervalSet()
#        s.addRange(range(36,41))
#        s.addRange(range(30,36))
#        self.assertEquals(1,len(s.intervals))
#        self.assertTrue(30 in s)
#        self.assertTrue(40 in s)
#
#    def testOverlapping1(self):
#        s = IntervalSet()
#        s.addRange(range(30,40))
#        s.addRange(range(35,45))
#        self.assertEquals(1,len(s.intervals))
##        self.assertTrue(30 in s)
#        self.assertTrue(44 in s)
#
#    def testOverlapping2(self):
##        s = IntervalSet()
#        s.addRange(range(35,45))
#        s.addRange(range(30,40))
#        self.assertEquals(1,len(s.intervals))
#        self.assertTrue(30 in s)
#        self.assertTrue(44 in s)
#
#    def testOverlapping3(self):
#        s = IntervalSet()
#        s.addRange(range(30,32))
#        s.addRange(range(40,42))
#        s.addRange(range(50,52))
#        s.addRange(range(20,61))
#        self.assertEquals(1,len(s.intervals))
#        self.assertTrue(20 in s)
#        self.assertTrue(60 in s)
