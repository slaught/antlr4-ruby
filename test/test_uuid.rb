
require 'test/unit'

$: << 'lib'
require 'uuid'

class UuidTest < Test::Unit::TestCase

  def setup()
    @start = "AADB8D7E-AEEF-4415-AD2B-8204D6CF042E"
  end
  def teardown 
  end

  def test_create
# BASE_SERIALIZED_UUID = UUID("AADB8D7E-AEEF-4415-AD2B-8204D6CF042E")
# Three inputs
# a UUID 'string' of hexdigits and - {}
# a URN prefixed UUID string
# a IO input of bytes as a string
# an array of bytes/numbers
# a single int
#    assert titles.length > 0, 'Titles exist'
#    assert titles.class == Array , 'Titles Array'
    assert true
  #start = "AADB8D7E-AEEF-4415-AD2B-8204D6CF042E"
#u = UUID.new(start) 

  end
  def test_basic_create 
    u = UUID.new( @start )
    assert u
    assert u.class == UUID
    uuid = UUID.new( "{#{@start}}" )
    assert uuid
    assert uuid.class == UUID
    urn_uuid = UUID.new("urn:" + @start )
    assert urn_uuid
    assert u.class == UUID
    assert u == urn_uuid
    assert urn_uuid == uuid
    assert u == uuid
  end
  def test_string
    u = UUID.new( @start )
    assert u
    assert @start.downcase == u.to_s.downcase
    assert @start.upcase == u.to_s.upcase
  end
  def test_int_value
    start_value = 5233100606242806050955395731361295
    start_uuid  = "00010203-0405-0607-0809-0a0b0c0d0e0f"
    u1 = UUID.new(start_value)
    assert u1
    assert u1.to_i == start_value
    assert u1.to_s == start_uuid
  end
  
  def test_create_from_byte_array
      ba = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
      #).pack("C*").chars.reduce(0) {|a,b| ((a << 8)| b.ord) }
      ba_int =  5233100606242806050955395731361295
      bs = "\x00\x00\x01\x02\x03\x04\x05\x06\a\b\t\n\v\f\r\x0E\x0F" 
      u1 = UUID.create_from_bytes(ba)
      assert u1
      u2 = UUID.new(ba_int)
      assert u2
      assert u1 == u2 , "Equality test" 
      assert u1.bytes_array == u2.bytes_array, "Compare created bytes_array"
  end

  def test_bytes_array
      ba_uuid = '00010203-0405-0607-0809-0a0b0c0d0e0f'
      ba = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
      ba_int =  5233100606242806050955395731361295
      u = UUID.new(ba_int)
      assert u
      assert u.bytes_array == ba
      assert u.to_s == ba_uuid
  end
  def test_bytes
      ba_int =  5233100606242806050955395731361295
      bs = "\x00\x01\x02\x03\x04\x05\x06\a\b\t\n\v\f\r\x0E\x0F" 
      u = UUID.create_from_bytes(ba_int)
      assert u
      assert u.bytes.unpack("H*") == bs.unpack("H*"), "Compare bytes to std byte string "
      u2 = UUID.create_from_bytes(bs)
      assert u2
      assert u2.bytes == u.bytes
      
  end
  def test_eql
    u1 = UUID.new(@start)
    u2 = UUID.new("{#{@start}}")
    assert u1.eql? u2
  end
  def test_io
    require 'tempfile'
    x = UUID.new('{00010203-0405-0607-0809-0a0b0c0d0e0f}')
    assert x
    tmpfile = Tempfile.new('test-uuid')
    tmpfile.write(x.bytes)
    tmpfile.rewind
    bytes = tmpfile.read
    v = UUID.create_from_bytes(bytes)
    assert v
    assert x == v
    tmpfile.close!
  end
end

__END__
#          byte_string = ().pack("C*").split('').reduce(0) {|a,b| a << 4| b.ord }
#([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]).pack("C*").split('').reduce(0) {|a,b| a << 4| b.ord }

"\3\u0430\ud6d1\u8206\uad2d\u4417\uaef1\u8d80\uaadd\2\37\u023a" \
"\b\1\4\2\t\2\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4" \
 "\t\t\t\4\n\t\n\4\13\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4" \

 "\3\u0430\ud6d1\u8206\uad2d\u4417\uaef1\u8d80\uaadd\2\37\u023a\b\1\4\2"
 "\t\2\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\4"
 "\13\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4\20\t\20\4\21\t\21\4\22"
