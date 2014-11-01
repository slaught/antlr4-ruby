
require 'test/unit'

$: << 'lib'
require 'antlr4'
require 'IntervalSet' 

class IntervalSetTest < Test::Unit::TestCase

  def setup()
  end
  def teardown 
  end

  def test_create
    n = IntervalSet.new
    assert_not_nil n
    assert_not_nil     n.intervals  
    assert n.intervals.empty?
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
    def test_tostring
      n = IntervalSet.new
      assert_equal "{}", n.toString([]) , "empty toString fail"
      token_names = ['zero','one','two']
      n.addOne(1)
      n.addOne(2)
      assert_equal '{"one", "two"}', n.toString(token_names)
    
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
end # End of TestCase
