
# Represents the result of matching a {@link ParseTree} against a tree pattern.
#from io import StringIO
#from antlr4.tree.ParseTreePattern import ParseTreePattern
#from antlr4.tree.Tree import ParseTree
require 'stringio'


class ParseTreeMatch
    # Constructs a new instance of {@link ParseTreeMatch} from the specified
    # parse tree and pattern.
    #
    # @param tree The parse tree to match against the pattern.
    # @param pattern The parse tree pattern.
    # @param labels A mapping from label names to collections of
    # {@link ParseTree} objects located by the tree pattern matching process.
    # @param mismatchedNode The first node which failed to match the tree
    # pattern during the matching process.
    #
    # @exception IllegalArgumentException if {@code tree} is {@code null}
    # @exception IllegalArgumentException if {@code pattern} is {@code null}
    # @exception IllegalArgumentException if {@code labels} is {@code null}
    #
    attr_accessor :tree, :pattern, :labels, :mismatchedNode
    def initialize(tree, pattern, labels, mismatchedNode)
        raise Exception.new("tree cannot be null") if tree.nil? 
        raise Exception.new("pattern cannot be null") if pattern.nil?
        raise Exception.new("labels cannot be null") if labels.nil? 
        self.tree = tree
        self.pattern = pattern
        self.labels = labels
        self.mismatchedNode = mismatchedNode
    end
    #
    # Get the last node associated with a specific {@code label}.
    #
    # <p>For example, for pattern {@code <id:ID>}, {@code get("id")} returns the
    # node matched for that {@code ID}. If more than one node
    # matched the specified label, only the last is returned. If there is
    # no node associated with the label, this returns {@code null}.</p>
    #
    # <p>Pattern tags like {@code <ID>} and {@code <expr>} without labels are
    # considered to be labeled with {@code ID} and {@code expr}, respectively.</p>
    #
    # @param label The label to check.
    #
    # @return The last {@link ParseTree} to match a tag with the specified
    # label, or {@code null} if no parse tree matched a tag with the label.
    #
    def get(label)
        parseTrees = self.labels.get(label, nil)
        if parseTrees.nil? or parseTrees.empty? then
            return nil
        else
            return parseTrees[-1]
        end
    end
    #
    # Return all nodes matching a rule or token tag with the specified label.
    #
    # <p>If the {@code label} is the name of a parser rule or token in the
    # grammar, the resulting list will contain both the parse trees matching
    # rule or tags explicitly labeled with the label and the complete set of
    # parse trees matching the labeled and unlabeled tags in the pattern for
    # the parser rule or token. For example, if {@code label} is {@code "foo"},
    # the result will contain <em>all</em> of the following.</p>
    #
    # <ul>
    # <li>Parse tree nodes matching tags of the form {@code <foo:anyRuleName>} and
    # {@code <foo:AnyTokenName>}.</li>
    # <li>Parse tree nodes matching tags of the form {@code <anyLabel:foo>}.</li>
    # <li>Parse tree nodes matching tags of the form {@code <foo>}.</li>
    # </ul>
    #
    # @param label The label.
    #
    # @return A collection of all {@link ParseTree} nodes matching tags with
    # the specified {@code label}. If no nodes matched the label, an empty list
    # is returned.
    #
    def getAll(label)
        self.labels.get(label, [])
    end

    #
    # Gets a value indicating whether the match operation succeeded.
    #
    # @return {@code true} if the match operation succeeded; otherwise,
    # {@code false}.
    #
    def succeeded
        return self.mismatchedNode.nil?
    end
    #
    # {@inheritDoc}
    #
    def to_s
        StringIO.open do |buf|
            buf.write("Match ")
            if self.succeeded() 
                buf.write("succeeded") 
            else 
                buf.write("failed")
            end
            buf.write("; found ")
            buf.write(self.labels.length.to_s)
            buf.write(" labels")
            return buf.string
        end
    end
end
