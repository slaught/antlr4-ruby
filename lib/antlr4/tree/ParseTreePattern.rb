# A pattern like {@code <ID> = <expr>;} converted to a {@link ParseTree} by
# {@link ParseTreePatternMatcher#compile(String, int)}.
#
#from antlr4.tree.ParseTreePatternMatcher import ParseTreePatternMatcher
#from antlr4.tree.Tree import ParseTree
#from antlr4.xpath.XPath import XPath


class ParseTreePattern

    # Construct a new instance of the {@link ParseTreePattern} class.
    #
    # @param matcher The {@link ParseTreePatternMatcher} which created this
    # tree pattern.
    # @param pattern The tree pattern in concrete syntax form.
    # @param patternRuleIndex The parser rule which serves as the root of the
    # tree pattern.
    # @param patternTree The tree pattern in {@link ParseTree} form.
    #
    attr_accessor :matcher, :patternRuleIndex, :pattern, :patternTree
    def initialize(matcher, pattern, patternRuleIndex, patternTree)
        self.matcher = matcher
        self.patternRuleIndex = patternRuleIndex
        self.pattern = pattern
        self.patternTree = patternTree
    end

    #
    # Match a specific parse tree against this tree pattern.
    #
    # @param tree The parse tree to match against this tree pattern.
    # @return A {@link ParseTreeMatch} object describing the result of the
    # match operation. The {@link ParseTreeMatch#succeeded()} method can be
    # used to determine whether or not the match was successful.
    #
    def match(tree)
        return self.matcher.match(tree, self)
    end

    #
    # Determine whether or not a parse tree matches this tree pattern.
    #
    # @param tree The parse tree to match against this tree pattern.
    # @return {@code true} if {@code tree} is a match for the current tree
    # pattern; otherwise, {@code false}.
    #
    def matches(tree)
        return self.matcher.match(tree, self).succeeded()
    end

    # Find all nodes using XPath and then try to match those subtrees against
    # this tree pattern.
    #
    # @param tree The {@link ParseTree} to match against this pattern.
    # @param xpath An expression matching the nodes
    #
    # @return A collection of {@link ParseTreeMatch} objects describing the
    # successful matches. Unsuccessful matches are omitted from the result,
    # regardless of the reason for the failure.
    #
    def findAll(tree, xpath)
        subtrees = XPath.findAll(tree, xpath, self.matcher.parser)
        subtrees.map do |t| 
            match = self.match(t)
            if match.succeeded() then
                match
            end
        end.compact
    end
end
