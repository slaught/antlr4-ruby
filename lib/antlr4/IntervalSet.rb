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

    def self.copy(other)
        s = IntervalSet.new
        s.intervals = other.intervals.clone
        s.readonly = other.readonly
        s._internal = other._internal.clone
        s
    end

    def self.of(a,b=nil)
       s = IntervalSet.new
       if b.nil? then
          b = a
       end
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
        if other.kind_of?(IntervalSet) then
          if other.intervals and not other.isNil then
            other.intervals.each {|i| self.addRange(i) }
          end
        else
            raise Exception.new("can't add a non-IntervalSet #{other.class}")
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
#    public int size() {
#		int n = 0;
#		int numIntervals = intervals.size();
#		if ( numIntervals==1 ) {
#			Interval firstInterval = this.intervals.get(0);
#			return firstInterval.b-firstInterval.a+1;
#		}
#		for (int i = 0; i < numIntervals; i++) {
#			Interval I = intervals.get(i);
#			n += (I.b-I.a+1);
#		}
#		return n;
#    }


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

    def toString(tokenNames=nil)
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
                    if tokenNames then
                        self.elementName(tokenNames, j).to_s
                    else
                        j.to_s
                    end
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
#IntervalSet implements IntSet {
#  COMPLETE_CHAR_SET = IntervalSet.of(Lexer.MIN_CHAR_VALUE, Lexer.MAX_CHAR_VALUE);
#	static { COMPLETE_CHAR_SET.setReadonly(true); }
#	EMPTY_SET = new IntervalSet(); static { EMPTY_SET.setReadonly(true); }
#
#	public IntervalSet addAll(IntSet set) {
#		if ( set==null ) { return this; }
#		if (set instanceof IntervalSet) {
#			IntervalSet other = (IntervalSet)set;
#			int n = other.intervals.size();
#			for (int i = 0; i < n; i++) {
#				Interval I = other.intervals.get(i);
#				this.add(I.a,I.b);
#			}
#		return this;
#}
    def isNil()
       self.intervals.empty?
    end
#
#   this.complement(IntervalSet.of(minElement,maxElement));
#
    def complement(vocabulary)
      if vocabulary.nil? || vocabulary.isNil() then
        return nil
      end
      vocabularyIS = vocabulary
      vocabularyIS.subtract(self);
    end

    def subtract(a) 
  		if (a.nil? || a.isNil()) then
			  s = IntervalSet.new 
        s.addSet(self) 
        return s 
		  end

			return IntervalSet.subtract(self, a);
    end
    

	 # Compute the set difference between two interval sets. The specific
	 # operation is {@code left - right}. If either of the input sets is
	 # {@code null}, it is treated as though it was an empty set.
  def self.subtract(left,right)
    if left.nil? or left.isNil() then
        return IntervalSet.new()
    end

    result = IntervalSet.copy(left)
		if right.nil? or right.isNil() then
			# right set has no elements; just return the copy of the current set
			return result
		end

		resultI = 0
		rightI = 0
		while (resultI < result.intervals.size() && rightI < right.intervals.size()) do
			resultInterval = result.intervals[resultI]
			rightInterval = right.intervals[rightI]

			# operation: (resultInterval - rightInterval) and update indexes
			if (rightInterval.b < resultInterval.a) then
				rightI += 1
				next
			end
			if (rightInterval.a > resultInterval.b) then
				resultI += 1
				next
			end	

			beforeCurrent = nil
			afterCurrent = nil
			if (rightInterval.a > resultInterval.a) then
				beforeCurrent = (resultInterval.a .. rightInterval.a - 1)
			end

			if (rightInterval.b < resultInterval.b) then
				afterCurrent =  (rightInterval.b + 1  .. resultInterval.b)
			end

			if not beforeCurrent.nil? then
				if not afterCurrent.nil? then
					# split the current interval into two
					result.intervals[resultI] =  beforeCurrent
					result.intervals[resultI + 1] =  afterCurrent
					resultI += 1
					rightI += 1
				else
					# replace the current interval
					result.intervals[resultI]= beforeCurrent
					resultI += 1
				end
			  next
			else
				if not afterCurrent.nil?  then
					# replace the current interval
					result.intervals[resultI] =  afterCurrent
					rightI += 1
				else
					# remove the current interval (thus no need to increment resultI)
					result.intervals.delete_at(resultI)
				end
			  next
			end
		end

		# If rightI reached right.intervals.size(), no more intervals to subtract from result.
		# If resultI reached result.intervals.size(), we would be subtracting from an empty set.
		# Either way, we are done.
		result
	end

end
# Returns the maximum value contained in the set.
# If the set is empty, this method returns {@link Token#INVALID_TYPE}.
#	def getMaxElement()
#		if ( isNil() ) { return Token.INVALID_TYPE; }
#		Interval last = intervals.get(intervals.size()-1);
#		return last.b;
#	end
#
## Returns the minimum value contained in the set.
#	def getMinElement()
#		if ( isNil() ) { return Token.INVALID_TYPE; }
#		return intervals.get(0).a;
# end


#	/** Get the ith element of ordered set.  Used only by RandomPhrase so
#	 *  don't bother to implement if you're not doing that for a new
#	 *  ANTLR code gen target.
#	public int get(int i) {
#		int n = intervals.size();
#		int index = 0;
#		for (int j = 0; j < n; j++) {
#			Interval I = intervals.get(j);
#			int a = I.a;
#			int b = I.b;
#			for (int v=a; v<=b; v++) {
#				if ( index==i ) {
#					return v;
#				}
#				index++;
#			}
#		}
#		return -1;
#	}

