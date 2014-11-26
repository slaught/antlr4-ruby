
require 'test/unit'

# $: << 'lib'
require 'antlr4'
# require 'IntervalSet' 

class IntervalSetTest < Test::Unit::TestCase

  def setup()
  end
  def teardown 
  end

  def test_create
    n = IntervalSet.new
    assert_not_nil n
    assert_not_nil     n.intervals  
    assert n.intervals.class == Array , "intervals is not an array "
    assert n.intervals.empty? == true, "intervals is not empty #{n.intervals.inspect}"
    assert         n.readonly == false
    assert_not_nil n._internal
    assert n._internal.class == Set
  end

  def test_range_new
    r = Range.new(100,200)
    assert_not_nil r
    assert  r.first == r.start, "Range.start fail"
    assert  r.last  == r.stop , "Range.stop fail"
    assert  r.size == r.length, "Ranage.length fail"
  end
   def test_intervals
    # def_delegators :@intervals, :each, :map 
     assert true 
   end
#    def []=(item)
#      @_internal[item]
#    end
   def test_add
      n = IntervalSet.new
      assert n.addOne(2) ,"addOne Fail"
      assert n.length == 1 , "addOne Fail length"

      assert_nil n.addRange(Range.new(1,1)) , "addRange fail"
      assert_equal 2, n.length, 'addRange fail length'
      assert_nil n.addRange(Range.new(1,5)) , "addRange fail"
      assert_equal (5-1+1), n.length, 'addRange fail length'
    end
    def test_addset
      n1 = IntervalSet.new
      assert_not_nil n1
      assert n1.addOne(10)
      n2 = IntervalSet.new
      assert n2.addOne(20)
      assert n1.length == n2.length, "inital lengths failed"
      assert n2.addSet(n1)
      assert n2.length == 2, "addSet failed to increase length" 
    end
    def test_reduce
      n = IntervalSet.new
      assert_nil n.reduce(1), "reduce fail on empty"
      n.addOne(1)
      n.addOne(2)
      assert_nil n.reduce(2), "reduce fail on non-empt"
    end
    def test_member
      n = IntervalSet.new
      assert n.member?(1) == false, "member? fast check fails does not exist" 
      n.addOne(1)
      assert n.member?(1) , "member? does not exist" 
      assert_equal false, n.member?(2), "member? does exist"
    end
    def test_length
      n = IntervalSet.new
      assert n.length == 0, "not empty"
      n.addOne(1)
      assert n.length == 1, "not exactly 1"
      n.addRange(Range.new(2,3))
      assert n.length == 3, "not exactly 1"
    end
    def test_remove
      n = IntervalSet.new
      assert_equal nil, n.remove(1),  "empty remove fail" 
      n.addOne(1)
      assert_nil n.remove(1), "1 remove fail"
    end
    def test_toString
      n = IntervalSet.new
      assert_equal "{}", n.toString([]) , "empty toString fail"
      token_names = ['zero','one','two']
      n.addOne(1)
      n.addOne(2)
      assert_equal '{one, two}', n.toString(token_names)
    
    end
    def test_elementname
      n = IntervalSet.new
      assert n.elementName([],Token.EOF) == "<EOF>"
      assert n.elementName([],Token.EPSILON) == "<EPSILON>"
      a = Array.new
      a[100] = "XXX"
      assert n.elementName(a, 100) == "XXX"
    end
    def test_empty
      n = IntervalSet.new
      assert_equal false, n.member?(30)
      assert n.intervals.empty?
    end
    def test_one 
      s = IntervalSet.new()
      s.addOne(30)
      assert s.member? 30 
      assert_equal false,s.member?(29)
      assert_equal false,s.member?(31)
    end    
    def test_two
        s = IntervalSet.new
        s.addOne(30)
        s.addOne(40)
        assert s.member? 30
        assert s.member? 40
        assert_equal false, s.member?(35)
    end
    def test_three 
        s = IntervalSet.new
        s.addRange(Range.new(30,41))
        assert s.member? 30
        assert s.member? 40
        assert s.member? 35
        assert_equal false, s.member?(29)
        assert_equal false, s.member?(42)
    end

    def test_distinct1
      s = IntervalSet.new
      r1 = Range.new(30,32)
      r2 = Range.new(40,42)
      s.addRange(r1)
      s.addRange(r2)
      assert_equal 2, s.intervals.length
      assert_equal 6, s.length
      r1.each{|val| assert s.member?(val), "r1,#{val}"}
      r2.each{|val| assert s.member?(val), "r2,#{val}"}
      [r1,r2].each do |r|
          assert_equal false, s.member?(r.start-1)
          assert_equal false, s.member?(r.stop+1)
      end
    end
  def test_distinct2
     s = IntervalSet.new
      r1 = Range.new(30,32)
      r2 = Range.new(40,42)
      s.addRange(r2)
      s.addRange(r1)
     assert_equal 2, s.intervals.length
     assert_equal 6, s.length
     assert s.member? 30 
     assert s.member? 40
     assert_equal false, s.member?(35)
      r1.each{|val| assert s.member?(val) }
      r2.each{|val| assert s.member?(val) }
      [r1,r2].each do |r|
          assert_equal false, s.member?(r.start-1)
          assert_equal false, s.member?(r.stop+1)
      end
  end
  def test_contiguous1
    s = IntervalSet.new
    r1 = Range.new(30,36)
    r2 = Range.new(36,41)
    s.addRange(r1)
    s.addRange(r2)
    assert_equal 1, s.intervals.length
    assert_equal 12, s.length
    r1.each{|val| assert s.member?(val), "test_contiguous:r1:#{val}" }
    r2.each{|val| assert s.member?(val), "test_contiguous:r2:#{val}" }
    assert_equal false, s.member?(r1.start-1)
    assert_equal false, s.member?(r2.stop+1)
  end
  def test_contiguous2
    s = IntervalSet.new
    r1 = Range.new(30,36)
    r2 = Range.new(36,41)
    s.addRange(r2)
    s.addRange(r1)
    assert_equal 1, s.intervals.length, "not only 1 interval"
    r1.each{|val| assert s.member?(val), "test_contiguous:r1:#{val}" }
    r2.each{|val| assert s.member?(val), "test_contiguous:r2:#{val}" }
    assert_equal false, s.member?(r1.start-1)
    assert_equal false, s.member?(r2.stop+1)
  end
  def test_overlapping1
    s = IntervalSet.new
    r1 = Range.new(30,40)
    r2 = Range.new(35,45)
    s.addRange(r1)
    s.addRange(r2)
    assert_equal 1, s.intervals.length
    assert s.member? 30 
    assert s.member? 44
    r1.each{|val| assert s.member?(val), "test_overlapping:r1:#{val}" }
    r2.each{|val| assert s.member?(val), "test_overlapping:r2:#{val}" }
    assert_equal false, s.member?([r1.start,r2.start].min-1)
    assert_equal false, s.member?([r1.stop,r2.stop].max+1)
  end

  def test_overlapping2
    s = IntervalSet.new
    r1 = Range.new(30,40)
    r2 = Range.new(35,45)
    s.addRange(r2)
    s.addRange(r1)
    assert_equal 1, s.intervals.length
    assert s.member? 30 
    assert s.member? 44
    r1.each{|val| assert s.member?(val), "test_overlapping:r1:#{val}" }
    r2.each{|val| assert s.member?(val), "test_overlapping:r2:#{val}" }
    assert_equal false, s.member?([r1.start,r2.start].min-1)
    assert_equal false, s.member?([r1.stop,r2.stop].max+1)
  end

  def test_overlapping3
    s = IntervalSet.new
    r1 = Range.new(30,32)
    r2 = Range.new(40,42)
    r3 = Range.new(50,52)
    r4 = Range.new(20,61)

    s.addRange(r1)
    s.addRange(r2)
    s.addRange(r3)
    s.addRange(r4)
    assert_equal 1, s.intervals.length
    assert s.member? 20 
    assert s.member? 60
    allranges = [r1,r2,r3,r4]
    allranges.zip([:r1,:r2,:r3,:r4]).each do |r,label|
       r.each{|val| assert s.member?(val), "test_overlapping:#{label}:#{val}" }
    end
    
    lower= allranges.map{|r| r.start }.min 
    upper= allranges.map{|r| r.stop  }.max
    assert_equal false, s.member?(lower-1)
    assert_equal false, s.member?(upper+1)

  end
  def test_complement
    s =  IntervalSet.new 
    assert_not_nil s
    t = IntervalSet.new
    assert_not_nil t
    t.addRange(0..15)
    assert s.complement(t), "complement failed"
  end

	def test_SingleElement
		s = IntervalSet.of(99)
		expecting = "99";
		assert_equal s.toString, expecting 
	end

#	def test_min 
#		assertEquals(0, IntervalSet.COMPLETE_CHAR_SET.getMinElement());
#		assertEquals(Token.EPSILON, IntervalSet.COMPLETE_CHAR_SET.or(IntervalSet.of(Token.EPSILON)).getMinElement());
#		assertEquals(Token.EOF, IntervalSet.COMPLETE_CHAR_SET.or(IntervalSet.of(Token.EOF)).getMinElement());
#  end

	def test_IsolatedElements
		s = IntervalSet.new 
		s.addOne(1)
		s.addOne('z')
		s.addOne('\uFFF0')
		expecting = "{1, 122, 65520}"
    assert_equals s.toString, expecting
  end    

end # End of TestCase
__END__
    @Test public void testMixedRangesAndElements() throws Exception {
        IntervalSet s = new IntervalSet();
        s.add(1);
        s.add('a','z');
        s.add('0','9');
        String expecting = "{1, 48..57, 97..122}";
        assertEquals(s.toString(), expecting);
    end

    @Test public void testSimpleAnd() throws Exception {
        IntervalSet s = IntervalSet.of(10,20);
        IntervalSet s2 = IntervalSet.of(13,15);
        String expecting = "{13..15}";
        String result = (s.and(s2)).toString();
        assertEquals(expecting, result);
    }

    @Test public void testRangeAndIsolatedElement() throws Exception {
        IntervalSet s = IntervalSet.of('a','z');
        IntervalSet s2 = IntervalSet.of('d');
        String expecting = "100";
        String result = (s.and(s2)).toString();
        assertEquals(expecting, result);
    }

	@Test public void testEmptyIntersection() throws Exception {
		IntervalSet s = IntervalSet.of('a','z');
		IntervalSet s2 = IntervalSet.of('0','9');
		String expecting = "{}";
		String result = (s.and(s2)).toString();
		assertEquals(expecting, result);
	}

	@Test public void testEmptyIntersectionSingleElements() throws Exception {
		IntervalSet s = IntervalSet.of('a');
		IntervalSet s2 = IntervalSet.of('d');
		String expecting = "{}";
		String result = (s.and(s2)).toString();
		assertEquals(expecting, result);
	}

    @Test public void testNotSingleElement() throws Exception {
        IntervalSet vocabulary = IntervalSet.of(1,1000);
        vocabulary.add(2000,3000);
        IntervalSet s = IntervalSet.of(50,50);
        String expecting = "{1..49, 51..1000, 2000..3000}";
        String result = (s.complement(vocabulary)).toString();
        assertEquals(expecting, result);
    }

	@Test public void testNotSet() throws Exception {
		IntervalSet vocabulary = IntervalSet.of(1,1000);
		IntervalSet s = IntervalSet.of(50,60);
		s.add(5);
		s.add(250,300);
		String expecting = "{1..4, 6..49, 61..249, 301..1000}";
		String result = (s.complement(vocabulary)).toString();
		assertEquals(expecting, result);
	}

	@Test public void testNotEqualSet() throws Exception {
		IntervalSet vocabulary = IntervalSet.of(1,1000);
		IntervalSet s = IntervalSet.of(1,1000);
		String expecting = "{}";
		String result = (s.complement(vocabulary)).toString();
		assertEquals(expecting, result);
	}

	@Test public void testNotSetEdgeElement() throws Exception {
		IntervalSet vocabulary = IntervalSet.of(1,2);
		IntervalSet s = IntervalSet.of(1);
		String expecting = "2";
		String result = (s.complement(vocabulary)).toString();
		assertEquals(expecting, result);
	}

    @Test public void testNotSetFragmentedVocabulary() throws Exception {
        IntervalSet vocabulary = IntervalSet.of(1,255);
        vocabulary.add(1000,2000);
        vocabulary.add(9999);
        IntervalSet s = IntervalSet.of(50, 60);
        s.add(3);
        s.add(250,300);
        s.add(10000); // this is outside range of vocab and should be ignored
        String expecting = "{1..2, 4..49, 61..249, 1000..2000, 9999}";
        String result = (s.complement(vocabulary)).toString();
        assertEquals(expecting, result);
    }

    @Test public void testSubtractOfCompletelyContainedRange() throws Exception {
        IntervalSet s = IntervalSet.of(10,20);
        IntervalSet s2 = IntervalSet.of(12,15);
        String expecting = "{10..11, 16..20}";
        String result = (s.subtract(s2)).toString();
        assertEquals(expecting, result);
    }

	@Test public void testSubtractFromSetWithEOF() throws Exception {
		IntervalSet s = IntervalSet.of(10,20);
		s.add(Token.EOF);
		IntervalSet s2 = IntervalSet.of(12,15);
		String expecting = "{<EOF>, 10..11, 16..20}";
		String result = (s.subtract(s2)).toString();
		assertEquals(expecting, result);
	}

	@Test public void testSubtractOfOverlappingRangeFromLeft() throws Exception {
		IntervalSet s = IntervalSet.of(10,20);
		IntervalSet s2 = IntervalSet.of(5,11);
		String expecting = "{12..20}";
        String result = (s.subtract(s2)).toString();
        assertEquals(expecting, result);

        IntervalSet s3 = IntervalSet.of(5,10);
        expecting = "{11..20}";
        result = (s.subtract(s3)).toString();
        assertEquals(expecting, result);
    }

    @Test public void testSubtractOfOverlappingRangeFromRight() throws Exception {
        IntervalSet s = IntervalSet.of(10,20);
        IntervalSet s2 = IntervalSet.of(15,25);
        String expecting = "{10..14}";
        String result = (s.subtract(s2)).toString();
        assertEquals(expecting, result);

        IntervalSet s3 = IntervalSet.of(20,25);
        expecting = "{10..19}";
        result = (s.subtract(s3)).toString();
        assertEquals(expecting, result);
    }

    @Test public void testSubtractOfCompletelyCoveredRange() throws Exception {
        IntervalSet s = IntervalSet.of(10,20);
        IntervalSet s2 = IntervalSet.of(1,25);
        String expecting = "{}";
        String result = (s.subtract(s2)).toString();
        assertEquals(expecting, result);
    }

    @Test public void testSubtractOfRangeSpanningMultipleRanges() throws Exception {
        IntervalSet s = IntervalSet.of(10,20);
        s.add(30,40);
        s.add(50,60); // s has 3 ranges now: 10..20, 30..40, 50..60
        IntervalSet s2 = IntervalSet.of(5,55); // covers one and touches 2nd range
        String expecting = "{56..60}";
        String result = (s.subtract(s2)).toString();
        assertEquals(expecting, result);

        IntervalSet s3 = IntervalSet.of(15,55); // touches both
        expecting = "{10..14, 56..60}";
        result = (s.subtract(s3)).toString();
        assertEquals(expecting, result);
    }

	/** The following was broken:
	 	{0..113, 115..65534}-{0..115, 117..65534}=116..65534
	 */
	@Test public void testSubtractOfWackyRange() throws Exception {
		IntervalSet s = IntervalSet.of(0,113);
		s.add(115,200);
		IntervalSet s2 = IntervalSet.of(0,115);
		s2.add(117,200);
		String expecting = "116";
		String result = (s.subtract(s2)).toString();
		assertEquals(expecting, result);
	}

    @Test public void testSimpleEquals() throws Exception {
        IntervalSet s = IntervalSet.of(10,20);
        IntervalSet s2 = IntervalSet.of(10,20);
        assertEquals(s, s2);

        IntervalSet s3 = IntervalSet.of(15,55);
        assertFalse(s.equals(s3));
    }

    @Test public void testEquals() throws Exception {
        IntervalSet s = IntervalSet.of(10,20);
        s.add(2);
        s.add(499,501);
        IntervalSet s2 = IntervalSet.of(10,20);
        s2.add(2);
        s2.add(499,501);
        assertEquals(s, s2);

        IntervalSet s3 = IntervalSet.of(10,20);
        s3.add(2);
		assertFalse(s.equals(s3));
    }

    @Test public void testSingleElementMinusDisjointSet() throws Exception {
        IntervalSet s = IntervalSet.of(15,15);
        IntervalSet s2 = IntervalSet.of(1,5);
        s2.add(10,20);
        String expecting = "{}"; // 15 - {1..5, 10..20} = {}
        String result = s.subtract(s2).toString();
        assertEquals(expecting, result);
    }

    @Test public void testMembership() throws Exception {
        IntervalSet s = IntervalSet.of(15,15);
        s.add(50,60);
        assertTrue(!s.contains(0));
        assertTrue(!s.contains(20));
        assertTrue(!s.contains(100));
        assertTrue(s.contains(15));
        assertTrue(s.contains(55));
        assertTrue(s.contains(50));
        assertTrue(s.contains(60));
    }

    // {2,15,18} & 10..20
    @Test public void testIntersectionWithTwoContainedElements() throws Exception {
        IntervalSet s = IntervalSet.of(10,20);
        IntervalSet s2 = IntervalSet.of(2,2);
        s2.add(15);
        s2.add(18);
        String expecting = "{15, 18}";
        String result = (s.and(s2)).toString();
        assertEquals(expecting, result);
    }

    @Test public void testIntersectionWithTwoContainedElementsReversed() throws Exception {
        IntervalSet s = IntervalSet.of(10,20);
        IntervalSet s2 = IntervalSet.of(2,2);
        s2.add(15);
        s2.add(18);
        String expecting = "{15, 18}";
        String result = (s2.and(s)).toString();
        assertEquals(expecting, result);
    }

    @Test public void testComplement() throws Exception {
        IntervalSet s = IntervalSet.of(100,100);
        s.add(101,101);
        IntervalSet s2 = IntervalSet.of(100,102);
        String expecting = "102";
        String result = (s.complement(s2)).toString();
        assertEquals(expecting, result);
    }

	@Test public void testComplement2() throws Exception {
		IntervalSet s = IntervalSet.of(100,101);
		IntervalSet s2 = IntervalSet.of(100,102);
		String expecting = "102";
		String result = (s.complement(s2)).toString();
		assertEquals(expecting, result);
	}

	@Test public void testComplement3() throws Exception {
		IntervalSet s = IntervalSet.of(1,96);
		s.add(99, Lexer.MAX_CHAR_VALUE);
		String expecting = "{97..98}";
		String result = (s.complement(1, Lexer.MAX_CHAR_VALUE)).toString();
		assertEquals(expecting, result);
	}

    @Test public void testMergeOfRangesAndSingleValues() throws Exception {
        // {0..41, 42, 43..65534}
        IntervalSet s = IntervalSet.of(0,41);
        s.add(42);
        s.add(43,65534);
        String expecting = "{0..65534}";
        String result = s.toString();
        assertEquals(expecting, result);
    }

    @Test public void testMergeOfRangesAndSingleValuesReverse() throws Exception {
        IntervalSet s = IntervalSet.of(43,65534);
        s.add(42);
        s.add(0,41);
        String expecting = "{0..65534}";
        String result = s.toString();
        assertEquals(expecting, result);
    }

    @Test public void testMergeWhereAdditionMergesTwoExistingIntervals() throws Exception {
        // 42, 10, {0..9, 11..41, 43..65534}
        IntervalSet s = IntervalSet.of(42);
        s.add(10);
        s.add(0,9);
        s.add(43,65534);
        s.add(11,41);
        String expecting = "{0..65534}";
        String result = s.toString();
        assertEquals(expecting, result);
    }

	/**
	 * This case is responsible for antlr/antlr4#153.
	 * https://github.com/antlr/antlr4/issues/153
	 */
	@Test public void testMergeWhereAdditionMergesThreeExistingIntervals() throws Exception {
		IntervalSet s = new IntervalSet();
		s.add(0);
		s.add(3);
		s.add(5);
		s.add(0, 7);
		String expecting = "{0..7}";
		String result = s.toString();
		assertEquals(expecting, result);
	}

	@Test public void testMergeWithDoubleOverlap() throws Exception {
		IntervalSet s = IntervalSet.of(1,10);
		s.add(20,30);
		s.add(5,25); // overlaps two!
		String expecting = "{1..30}";
		String result = s.toString();
		assertEquals(expecting, result);
	}

	@Test public void testSize() throws Exception {
		IntervalSet s = IntervalSet.of(20,30);
		s.add(50,55);
		s.add(5,19);
		String expecting = "32";
		String result = String.valueOf(s.size());
		assertEquals(expecting, result);
	}

	@Test public void testToList() throws Exception {
		IntervalSet s = IntervalSet.of(20,25);
		s.add(50,55);
		s.add(5,5);
		String expecting = "[5, 20, 21, 22, 23, 24, 25, 50, 51, 52, 53, 54, 55]";
		String result = String.valueOf(s.toList());
		assertEquals(expecting, result);
	}

	/** The following was broken:
	    {'\u0000'..'s', 'u'..'\uFFFE'} & {'\u0000'..'q', 's'..'\uFFFE'}=
	    {'\u0000'..'q', 's'}!!!! broken...
	 	'q' is 113 ascii
	 	'u' is 117
	*/
	@Test public void testNotRIntersectionNotT() throws Exception {
		IntervalSet s = IntervalSet.of(0,'s');
		s.add('u',200);
		IntervalSet s2 = IntervalSet.of(0,'q');
		s2.add('s',200);
		String expecting = "{0..113, 115, 117..200}";
		String result = (s.and(s2)).toString();
		assertEquals(expecting, result);
	}

    @Test public void testRmSingleElement() throws Exception {
        IntervalSet s = IntervalSet.of(1,10);
        s.add(-3,-3);
        s.remove(-3);
        String expecting = "{1..10}";
        String result = s.toString();
        assertEquals(expecting, result);
    }

    @Test public void testRmLeftSide() throws Exception {
        IntervalSet s = IntervalSet.of(1,10);
        s.add(-3,-3);
        s.remove(1);
        String expecting = "{-3, 2..10}";
        String result = s.toString();
        assertEquals(expecting, result);
    }

    @Test public void testRmRightSide() throws Exception {
        IntervalSet s = IntervalSet.of(1,10);
        s.add(-3,-3);
        s.remove(10);
        String expecting = "{-3, 1..9}";
        String result = s.toString();
        assertEquals(expecting, result);
    }

    @Test public void testRmMiddleRange() throws Exception {
        IntervalSet s = IntervalSet.of(1,10);
        s.add(-3,-3);
        s.remove(5);
        String expecting = "{-3, 1..4, 6..10}";
        String result = s.toString();
        assertEquals(expecting, result);
    }


}
