
# from uuid import UUID

# BASE_SERIALIZED_UUID = UUID("AADB8D7E-AEEF-4415-AD2B-8204D6CF042E")

class UUID 

    attr_accessor :hexstring, :hexdigits
    attr :uuid_fmt
    def initialize(uuid)
      @hexstring = uuid.tr('{}-','').downcase
      @hexdigits = @hexstring.split('').map(&:hex) 
      @uuid_fmt =  "#{'%x' * 8}#{'-%x%x%x%x'*3}-#{'%x'*12}" 
    end
    def self.create_from_bytes(byte_string)
        hexstring = byte_string.unpack('H*').first 
        new(hexstring)
    end
    def bytes
        bytes_array.pack('C*')
    end
    def bytes_array
      [ nibble_to_byte(@hexdigits[0..1]),
       nibble_to_byte(@hexdigits[2..3]),
       nibble_to_byte(@hexdigits[4..5]),
       nibble_to_byte(@hexdigits[6..7]),
       nibble_to_byte(@hexdigits[8..9]),
       nibble_to_byte(@hexdigits[10..11]),
       nibble_to_byte(@hexdigits[12..13]),
       nibble_to_byte(@hexdigits[14..15]),
       nibble_to_byte(@hexdigits[16..17]),
       nibble_to_byte(@hexdigits[18..19]),
       nibble_to_byte(@hexdigits[20..21]),
       nibble_to_byte(@hexdigits[22..23]),
       nibble_to_byte(@hexdigits[24..25]),
       nibble_to_byte(@hexdigits[26..27]),
       nibble_to_byte(@hexdigits[28..29]),
       nibble_to_byte(@hexdigits[30..31]),
      ]
    end
    def to_i
      nibble_to_byte(@hexdigits) #
    end
    def to_s
        uuid_fmt % hexdigits
    end
    def nibble_to_byte(a)
      a.reduce(0){|a,b| (a << 4|b) }
    end
    def eql?(other)
       self == other
    end
    def ==(other)
        self.equal?(other) or other.kind_of? self.class and
          self.hexstring == other.hexstring
    end
end

__END__
start = "AADB8D7E-AEEF-4415-AD2B-8204D6CF042E"

u = UUID.new(start) 
print "Test roundtrip: ",  u.to_s.upcase == start
puts 
print "Test int: ", "%x" % u.to_i == start.tr('{}-','').downcase
puts

x = UUID.new('{00010203-0405-0607-0809-0a0b0c0d0e0f}')
print "Braces tests: ", x.to_s == '00010203-0405-0607-0809-0a0b0c0d0e0f'
puts 

puts ("# %x #" * 16 ) % x.bytes_array
puts x.bytes_array.map{|b| b.class }.uniq
File.open('t.log', 'wb') do |io|
    raise Exception.new('not binary') unless io.binmode
    io.write(x.bytes)
end

puts ""

print "bytes compare: ", u.bytes == u.hexstring.unpack('H*')
print "bytes first: ", u.bytes
puts ""

print "round trip: hex: ", u.bytes.unpack('H*')
puts ""
print "cmp? ", u.bytes_array.pack('C*').unpack('H*').first == u.hexstring.downcase
puts ""

w = UUID.create_from_bytes(u.bytes) 

print "Compare create_from_bytes: ", w == u
puts ""
print "Compare self ", w == w, w == x.to_s
puts ""

v = nil
File.open('t.log', 'rb') do |io|
    bytes =  io.read()
    v = UUID.create_from_bytes(bytes) 
end

print "Compare after read(t.log): ", x == v
puts '' # "\n#{w.to_s}, #{v.to_s}"

__END__
"\3\u0430\ud6d1\u8206\uad2d\u4417\uaef1\u8d80\uaadd\2\37\u023a" \
"\b\1\4\2\t\2\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4" \
 "\t\t\t\4\n\t\n\4\13\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4" \

 "\3\u0430\ud6d1\u8206\uad2d\u4417\uaef1\u8d80\uaadd\2\37\u023a\b\1\4\2"
 "\t\2\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\4"
 "\13\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4\20\t\20\4\21\t\21\4\22"



#>>> uuid.UUID(bytes=x.bytes)
#UUID('00010203-0405-0607-0809-0a0b0c0d0e0f')

#>>> # get the raw 16 bytes of the UUID
#>>> x.bytes
#'\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b\x0c\r\x0e\x0f'
#
#>>> # make a UUID from a 16-byte string
#>>> uuid.UUID(bytes=x.bytes)
#UUID('00010203-0405-0607-0809-0a0b0c0d0e0f')
__END__
irb(main):071:0> hexdigits.reduce(0) {|a,b| (a << 4|b) }
=> 227108742152097063827714301457224107054
irb(main):072:0> "%x" % _
=> "aadb8d7eaeef4415ad2b8204d6cf042e"
irb(main):073:0> uuid.tr('{}-','').downcase
=> "aadb8d7eaeef4415ad2b8204d6cf042e"
irb(main):074:0> uuid.tr('{}-','').downcase == "%






__END__
uuid.tr('{}-','').downcase == "%x" % hexdigits.reduce(0){|a,b| (a << 4|b) }
=> true
=> "aadb8d7e-aeef-4415-ad2b-8204d6cf042e"
hexdigits = uuid.tr('{}-','').split('').map(&:hex) 
=> [10, 10, 13, 11, 8, 13, 7, 14, 10, 14, 14, 15, 4, 4, 1, 5, 10, 13, 2, 11,
8, 2, 0, 4, 13, 6, 12, 15, 0, 4, 2, 14]


    
    def to_s
      ""
    end
#UUID('886313e1-3b8a-5372-9b90-0c9aee199e5d')
#    def save(io)
 #       self.checkVersion()
 #       self.checkUUID()
    def checkUUID(self):
        uuid = self.readUUID()
        if not uuid in SUPPORTED_UUIDS:
            raise Exception("Could not deserialize ATN with UUID: " + str(uuid) + \
                            " (expected " + str(SERIALIZED_UUID) + " or a legacy UUID).", uuid, SERIALIZED_UUID)
        self.uuid = uuid

    def readInt(self):
        i = self.data[self.pos]
        self.pos += 1
        return i

    def readInt32(self):
        low = self.readInt()
        high = self.readInt()
        return low | (high << 16)

    def readLong(self):
        low = self.readInt32()
        high = self.readInt32()
        return (low & 0x00000000FFFFFFFF) | (high << 32)

    def readUUID(self):
        low = self.readLong()
        high = self.readLong()
        allBits = (low & 0xFFFFFFFFFFFFFFFF) | (high << 64)
        return UUID(int=allBits)


# make a UUID based on the host ID and current time
#>>> uuid.uuid1()
#UUID('a8098c1a-f86e-11da-bd1a-00112444be1e')
#
#>>> # make a UUID using an MD5 hash of a namespace UUID and a name
#>>> uuid.uuid3(uuid.NAMESPACE_DNS, 'python.org')
#UUID('6fa459ea-ee8a-3ca4-894e-db77e160355e')
#
##>>> # make a random UUID
#>>> uuid.uuid4()
#UUID('16fd2706-8baf-433b-82eb-8c7fada847da')
#
#>>> # make a UUID using a SHA-1 hash of a namespace UUID and a name
#>>> uuid.uuid5(uuid.NAMESPACE_DNS, 'python.org')
#UUID('886313e1-3b8a-5372-9b90-0c9aee199e5d')
#
#>>> # make a UUID from a string of hex digits (braces and hyphens ignored)
#>>> x = uuid.UUID('{00010203-0405-0607-0809-0a0b0c0d0e0f}')
#
#>>> # convert a UUID to a string of hex digits in standard form
#>>> str(x)
#'00010203-0405-0607-0809-0a0b0c0d0e0f'
#
#>>> # get the raw 16 bytes of the UUID
#>>> x.bytes
#'\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b\x0c\r\x0e\x0f'
#
#>>> # make a UUID from a 16-byte string
#>>> uuid.UUID(bytes=x.bytes)
#UUID('00010203-0405-0607-0809-0a0b0c0d0e0f')
