
# from uuid import UUID

# BASE_SERIALIZED_UUID = UUID("AADB8D7E-AEEF-4415-AD2B-8204D6CF042E")

# Three inputs
# a UUID 'string' of hexdigits and - {}
# a URN prefixed UUID string
# a IO input of bytes as a string
# an array of bytes/numbers
# a single int

class UUID 

    attr_accessor :byte_array, :value
    attr :uuid_fmt_32, :uuid_fmt_16
    def initialize(uuid)
      @uuid_fmt_32 =  "#{'%x' * 8}#{'-%x%x%x%x'*3}-#{'%x'*12}" 
      @uuid_fmt_16 =  "#{'%02x' * 4}#{'-%02x%02x'*3}-#{'%02x'*6}" 
      case uuid
        when String 
              if  uuid =~ /^urn:/ then
                 # assume urn input 
                 @value = UUID.create_from_uuid_string(uuid.sub('urn:',''))
              elsif  uuid.length > 31 and uuid =~ /^[-0-9a-fA-F{}]+$/
                 # uuid input syntax
                 @value= UUID.create_from_uuid_string(uuid)
              else
                  raise Exception.new("Fail to create uuid from string:#{uuid}")
              end
        when Bignum
           @value = uuid
        when Fixnum
           @value = uuid
        else
          raise Exception.new("Fail to create uuid: #{uuid.class}:#{uuid}")
        end
    end
    def self.create_from_uuid_string(uuid)
      hexstring = uuid.tr('{}-','').downcase
      hexstring.chars.map(&:hex).reduce(0) {|a,b|( (a << 4)|b ) }
    end
    def self.create_from_bytes(input)
        case input
        when String
              byte_string = input.chars
        when Bignum
              hexstring = input 
        when Fixnum
              hexstring = input 
        when Array
              byte_string = input
        end
        unless byte_string.nil?
           hexstring = byte_string.reduce(0) {|a,b| a << 8| b.ord }
        end
        new(hexstring)
    end
    def bytes
        bytes_array.pack('C*')
    end
    def bytes_array(conversion=:self)
        (0..127).step(8).map {|s| 
            if conversion == :self then
              value_byte(s)
            else 
              value_byte(s).send(conversion) 
            end
        }.reverse
    end
    def value_byte(s,mask=0xff) 
          (@value >> s) & mask
    end
    def to_i
      value
    end
    def to_s
          uuid_fmt_16 % bytes_array()
    end
    def eql?(other)
       self == other
    end
    def ==(other)
        self.equal?(other) or other.kind_of? self.class and
          self.value == other.value 
    end
end

