# from antlr4.Token import Token

require 'Token'

class RuleTagToken < Token
    # Constructs a new instance of {@link RuleTagToken} with the specified rule
    # name, bypass token type, and label.
    #
    # @param ruleName The name of the parser rule this rule tag matches.
    # @param bypassTokenType The bypass token type assigned to the parser rule.
    # @param label The label associated with the rule tag, or {@code null} if
    # the rule tag is unlabeled.
    #
    # @exception IllegalArgumentException if {@code ruleName} is {@code null}
    # or empty.

    attr_accessor :label, :ruleName

    def initialize(ruleName, bypassTokenType, label=nil)
        if ruleName.nil? or ruleName.length ==0 then
            raise Exception.new("ruleName cannot be null or empty.")
        end
        self.source = nil
        self.type = bypassTokenType # token type of the token
        self.channel = Token.DEFAULT_CHANNEL # The parser ignores everything not on DEFAULT_CHANNEL
        self.start = -1 # optional; return -1 if not implemented.
        self.stop = -1  # optional; return -1 if not implemented.
        self.tokenIndex = -1 # from 0..n-1 of the token object in the input stream
        self.line = 0 # line=1..n of the 1st character
        self.column = -1 # beginning of the line at which it occurs, 0..n-1
        self.label = label
        self.ruleName = ruleName
        @text = getText()
    end
    def getText()
        if self.label.nil? then
            "<#{@ruleName}>"
        else
            "<#{@label}:#{@ruleName}>"
        end
    end
end
