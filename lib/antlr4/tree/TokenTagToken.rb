# A {@link Token} object representing a token of a particular type; e.g.,
# {@code <ID>}. These tokens are created for {@link TagChunk} chunks where the
# tag corresponds to a lexer rule or token type.
#

class TokenTagToken < CommonToken

    # Constructs a new instance of {@link TokenTagToken} with the specified
    # token name, type, and label.
    #
    # @param tokenName The token name.
    # @param type The token type.
    # @param label The label associated with the token tag, or {@code null} if
    # the token tag is unlabeled.
    #
    attr_accessor :tokenName, :label
    def initialize(tokenName, type, label=nil)
        super(type)
        self.tokenName = tokenName
        self.label = label
        @text = getText()
    end
    # <p>The implementation for {@link TokenTagToken} returns the token tag
    # formatted with {@code <} and {@code >} delimiters.</p>
    def getText()
        if self.label.nil?
            return "<" + self.tokenName + ">"
        else
            return "<" + self.label + ":" + self.tokenName + ">"
        end
    end
    # <p>The implementation for {@link TokenTagToken} returns a string of the form
    # {@code tokenName:type}.</p>
    #
    def to_s
        "#{self.tokenName}:#{self.class}" 
    end
end
