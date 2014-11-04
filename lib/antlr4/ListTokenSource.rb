#
# Provides an implementation of {@link TokenSource} as a wrapper around a list
# of {@link Token} objects.
#
# <p>If the final token in the list is an {@link Token#EOF} token, it will be used
# as the EOF token for every call to {@link #nextToken} after the end of the
# list is reached. Otherwise, an EOF token will be created.</p>
#
#from antlr4.CommonTokenFactory import CommonTokenFactory
#from antlr4.Lexer import TokenSource
#from antlr4.Token import Token

require 'CommonTokenFactory'
require 'TokenSource'
require 'Token'

class ListTokenSource < TokenSource

    # Constructs a new {@link ListTokenSource} instance from the specified
    # collection of {@link Token} objects and source name.
    #
    # @param tokens The collection of {@link Token} objects to provide as a
    # {@link TokenSource}.
    # @param sourceName The name of the {@link TokenSource}. If this value is
    # {@code null}, {@link #getSourceName} will attempt to infer the name from
    # the next {@link Token} (or the previous token if the end of the input has
    # been reached).
    #
    # @exception NullPointerException if {@code tokens} is {@code null}
    attr_accessor :tokens, :sourceName, :pos, :eofToken, :factory
    def initialize(_tokens, source_name=nil)
        raise ReferenceError.new("tokens cannot be null") if tokens.nil? 
        @tokens = _tokens
        @sourceName = source_name
        # The index into {@link #tokens} of token to return by the next call to
        # {@link #nextToken}. The end of the input is indicated by this value
        # being greater than or equal to the number of items in {@link #tokens}.
        @pos = 0
        # This field caches the EOF token for the token source.
        @eofToken = nil
        # This is the backing field for {@link #getTokenFactory} and
        @factory = CommonTokenFactory.DEFAULT
    end


    #
    # {@inheritDoc}
    #
    def column
        if self.pos < self.tokens.length
            return self.tokens[self.pos].column
        elsif not self.eofToken.nil? 
            return self.eofToken.column
        elsif self.tokens.length > 0
            # have to calculate the result from the line/column of the previous
            # token, along with the text of the token.
            lastToken = self.tokens[-1]
            tokenText = lastToken.getText()
            if not tokenText.nil? then
                lastNewLine = tokenText.rfind('\n')
                if lastNewLine >= 0 
                    return tokenText.length - lastNewLine - 1
                end
            end
            return lastToken.column + lastToken.stopIndex - lastToken.startIndex + 1
        end
        # only reach this if tokens is empty, meaning EOF occurs at the first
        # position in the input
        return 0
    end
    #
    # {@inheritDoc}
    #
    def nextToken
        if self.pos >= self.tokens.length then
            if self.eofToken.nil? then
                start = -1
                if self.tokens.length > 0 then
                    previousStop = self.tokens[-1].stopIndex
                    if previousStop != -1 then
                        start = previousStop + 1
                    end
                end
                stop = [-1, start - 1].max
                self.eofToken = self.factory.create([self, self.getInputStream()],
                            Token.EOF, "EOF", Token.DEFAULT_CHANNEL, start, stop, self.line, self.column)
                stop = [-1, start - 1].max
            end
            return self.eofToken
        end
        t = self.tokens[self.pos]
        if self.pos == self.tokens.length - 1 and t.type == Token.EOF
            eofToken = t
        end
        self.pos = self.pos + 1
        return t
    end
    def line
        if self.pos < self.tokens.length
            return self.tokens[self.pos].line
        elsif not self.eofToken.nil? 
            return self.eofToken.line
        elsif self.tokens.length > 0
            # have to calculate the result from the line/column of the previous
            # token, along with the text of the token.
            lastToken = self.tokens[-1]
            line = lastToken.line
            tokenText = lastToken.text
            if not tokenText.nil? then
                for c in tokenText do
                    if c  == '\n'
                        line = line + 1
                    end
                end
            end
            # if no text is available, assume the token did not contain any newline characters.
            return line
        end
        # only reach this if tokens is empty, meaning EOF occurs at the first
        # position in the input
        return 1
    end
    #
    # {@inheritDoc}
    #
    def getInputStream
        if self.pos < self.tokens.length
            return self.tokens[self.pos].getInputStream()
        elsif not self.eofToken.nil?
            return self.eofToken.getInputStream()
        elsif self.tokens.length > 0
            return self.tokens[-1].getInputStream()
        else
            # no input stream information is available
            return nil
        end
    end

    def getSourceName
        return self.sourceName unless self.sourceName.nil?
        inputStream = self.getInputStream()
        if not inputStream.nil?
            return inputStream.getSourceName()
        else
            return "List"
        end
    end
end
