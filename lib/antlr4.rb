
class Lexer
#  attr_accessor :atn, :decisionsToDFA
#  attr_accessor :tokenNames, :ruleNames
end

class Parser

#  attr_accessor :_predicates, :_actions, :_interp 
#  attr_accessor :grammarFileName, :atn, :decisionsToDFA
#  attr_accessor :sharedContextCache, :tokenNames, :ruleNames

end

class ATNDeserializer
end

class ParseTreeListener
end

class Token
    INVALID_TYPE = 0

    # During lookahead operations, this "token" signifies we hit rule end ATN
    # state
    # and did not follow it despite needing to.
    EPSILON = -2

    MIN_USER_TOKEN_TYPE = 1

    def self.EOF 
        -1 
    end

    # All tokens go to the parser (unless skip() is called in that rule)
    # on a particular "channel".  The parser tunes to a particular channel
    # so that whitespace etc... can go to the parser on a "hidden" channel.

    DEFAULT_CHANNEL = 0

    # Anything on different channel than DEFAULT_CHANNEL is not parsed
    # by parser.

    HIDDEN_CHANNEL = 1


end

class ParserRuleContext
end
