
class ATNType 
    LEXER = 0
    PARSER = 1

    def self.LEXER 
        ATNType::LEXER
    end
    def self.PARSER
        ATNType::PARSER
    end
    def self.fromOrdinal(i)
        case i 
        when ATNType::LEXER then
           ATNType::LEXER
        when ATNType::PARSER then
           ATNType::PARSER
        else
          raise Exception.new("ATNType: Unknown value:#{i} ")
        end
    end
end
