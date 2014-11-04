# This default implementation of {@link TokenFactory} creates
# {@link CommonToken} objects.
require 'Token'

require 'TokenFactory'

class CommonTokenFactory < TokenFactory
    #
    # The default {@link CommonTokenFactory} instance.
    #
    # <p>
    # This token factory does not explicitly copy token text when constructing
    # tokens.</p>
    #
    @@default = nil
    def self.DEFAULT 
      @@default = new() if @@default.nil?
      @@default
    end

    attr_accessor :copyText
    def initialize(copyText=false)
        # Indicates whether {@link CommonToken#setText} should be called after
        # constructing tokens to explicitly set the text. This is useful for cases
        # where the input stream might not be able to provide arbitrary substrings
        # of text from the input after the lexer creates a token (e.g. the
        # implementation of {@link CharStream#getText} in
        # {@link UnbufferedCharStream} throws an
        # {@link UnsupportedOperationException}). Explicitly setting the token text
        # allows {@link Token#getText} to be called at any time regardless of the
        # input stream implementation.
        #
        # <p>
        # The default value is {@code false} to avoid the performance and memory
        # overhead of copying text for every token unless explicitly requested.</p>
        #
        self.copyText = copyText
    end
    def create(source, type, text, channel, start, stop, line, column)
        t = CommonToken.new(source, type, channel, start, stop)
        t.line = line
        t.column = column
        if not text.nil? then
            t.text = text
        elsif self.copyText and not source[1].nil? then
            t.text = source[1].getText(start,stop)
        end
        return t
    end

    def createThin(type, text)
        t = CommonToken.new(type)
        t.text = text
        return t
    end
end
