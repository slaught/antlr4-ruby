
#from enum import IntEnum
# Represents the type of recognizer an ATN applies to.
class ATNType #(IntEnum)
    LEXER = 0
    PARSER = 1

    def self.fromOrdinal(i)
        self._value2member_map_[i]
    end
end
