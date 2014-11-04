
class CommonTokenStream < BufferedTokenStream

    attr_accessor :channel
    def initialize(lexer, channel=Token.DEFAULT_CHANNEL)
        super(lexer)
        self.channel = channel
    end

    def adjustSeekIndex(i)
        return self.nextTokenOnChannel(i, self.channel)
    end

    def LB(k)
        return nil if k==0 or (self.index-k)<0
        i = self.index
        n = 1
        # find k good tokens looking backwards
        while n <= k do 
            # skip off-channel tokens
            i = self.previousTokenOnChannel(i - 1, self.channel)
            n = n + 1
        end
        return nil if i < 0
        return self.tokens[i]
    end
    def LT(k)
        self.lazyInit()
        return nil if k == 0
        return self.LB(-k) if k < 0
        i = self.index
        n = 1 # we know tokens[pos] is a good one
        # find k good tokens
        while n < k do 
            # skip off-channel tokens, but make sure to not look past EOF
            if self.sync(i + 1)
                i = self.nextTokenOnChannel(i + 1, self.channel)
            end
            n = n + 1
        end
        return self.tokens[i]
    end
    # Count EOF just once.#/
    def getNumberOfOnChannelTokens
        n = 0
        self.fill()
        for i in 0..self.tokens.length-1 do
            t = self.tokens[i]
            if t.channel==self.channel
                n = n + 1
            end
            break if t.type==Token.EOF
        end
        return n
    end
end
