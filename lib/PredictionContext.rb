#from io import StringIO
#from antlr4.RuleContext import RuleContext
#from antlr4.atn.ATN import ATN
#from antlr4.atn.ATNState import ATNState

require 'RuleContext'
require 'double_key_map'

class PredictionContext

    # Represents {@code $} in local context prediction, which means wildcard.
    # {@code#+x =#}.
    def self.EMPTY 
      @@EMPTY = EmptyPredictionContext.new if @@EMPTY.nil?
      @@EMPTY
    end
    # Represents {@code $} in an array in full context mode, when {@code $}
    # doesn't mean wildcard: {@code $ + x = [$,x]}. Here,
    # {@code $} = {@link #EMPTY_RETURN_STATE}.
    EMPTY_RETURN_STATE = 0x7FFFFFFF

    @@globalNodeCount = 1
    @@id = @@globalNodeCount

    # Stores the computed hash code of this {@link PredictionContext}. The hash
    # code is computed in parts to match the following reference algorithm.
    #
    # <pre>
    #  private int referenceHashCode() {
    #      int hash = {@link MurmurHash#initialize MurmurHash.initialize}({@link #INITIAL_HASH});
    #
    #      for (int i = 0; i &lt; {@link #size()}; i++) {
    #          hash = {@link MurmurHash#update MurmurHash.update}(hash, {@link #getParent getParent}(i));
    #      }
    #
    #      for (int i = 0; i &lt; {@link #size()}; i++) {
    #          hash = {@link MurmurHash#update MurmurHash.update}(hash, {@link #getReturnState getReturnState}(i));
    #      }
    #
    #      hash = {@link MurmurHash#finish MurmurHash.finish}(hash, 2# {@link #size()});
    #      return hash;
    #  }
    # </pre>
    #/
    attr_accessor :cachedHashCode 
    def initalize(cachedHashCode)
        self.cachedHashCode = cachedHashCode
    end

    # This means only the {@link #EMPTY} context is in set.
    def isEmpty
        return self.object_id == self.EMPTY.object_id
    end
    def hasEmptyPath
        return self.getReturnState(self.length - 1) == EMPTY_RETURN_STATE
    end
    def hash
        return self.cachedHashCode
    end
    def self.calculateEmptyHashCode
        "".hash
    end
    def self.calculateHashCode(parent, returnState)
          "#{parent}#{returnState}".hash
    end
end

#  Used to cache {@link PredictionContext} objects. Its used for the shared
#  context cash associated with contexts in DFA states. This cache
#  can be used for both lexers and parsers.
class PredictionContextCache

    attr_accessor :cache
    def initialize 
        self.cache = Hash.new
    end

    #  Add a context to the cache and return it. If the context already exists,
    #  return that one instead and do not add a new context to the cache.
    #  Protect shared cache from unsafe thread access.
    #
    def add(ctx)
        if ctx==PredictionContext.EMPTY
            return PredictionContext.EMPTY
        end
        existing = self.cache.get(ctx)
        return existing if not existing.nil? 
        self.cache[ctx] = ctx
        return ctx
    end
    def get(ctx)
        return self.cache.get(ctx)
    end
    def length
        return self.cache.length
    end
end

class SingletonPredictionContext < PredictionContext

    def self.create(parent, returnState)
        if returnState == PredictionContext.EMPTY_RETURN_STATE and parent.nil? 
            # someone can pass in the bits of an array ctx that mean $
            return SingletonPredictionContext.EMPTY
        else
            return SingletonPredictionContext.new(parent, returnState)
        end
    end

    attr_accessor :parentCtx, :returnState
    def initialize( parent, returnState)
        #assert returnState!=ATNState.INVALID_STATE_NUMBER
        if parent.nil? then
          hashCode = calculateEmptyHashCode
        else
          hashCode = calculateHashCode(parent, returnState) 
        end
        super(hashCode)
        @parentCtx = parent
        @returnState = returnState
    end

    def length 
        return 1
    end

    def getParent(index)
        # assert index == 0
        return self.parentCtx
    end

    def getReturnState(index)
        #assert index == 0
        return self.returnState
    end

    def eql?(other)
      self == other
    end
    def ==(other)
        return false if self.class != other.class
        return true if self.object_id == other.object_id
        if self.hash != other.hash
            false #      can't be same if hash is different
        else
            self.returnState == other.returnState and self.parentCtx==other.parentCtx
        end
    end
    def hash
        return self.cachedHashCode
    end

    def to_s 
        if self.parentCtx.nil? then
            up = "" 
        else 
            up = self.parentCtx.to_s
        end
        if up.length==0
            if self.returnState == self.EMPTY_RETURN_STATE
                return "$"
            else
                return self.returnState.to_s
            end
        else
            return "#{self.returnState} #{up}"
        end
    end
end
class EmptyPredictionContext < SingletonPredictionContext

    def initialize
        super(nil, self.EMPTY_RETURN_STATE)
    end

    def isEmpty
       true
    end

    def getParent(index)
      nil
    end

    def getReturnState(index)
        self.returnState
    end

    def ==(other)
        self.object_id ==  other.object_id
    end

    def to_s
        "$"
    end
end

class ArrayPredictionContext < PredictionContext
    # Parent can be null only if full ctx mode and we make an array
    #  from {@link #EMPTY} and non-empty. We merge {@link #EMPTY} by using null parent and
    #  returnState == {@link #EMPTY_RETURN_STATE}.

    def initialzie(parents, returnStates)
        super(calculateHashCode(parents, returnStates))
#        assert parents is not None and len(parents)>0
#        assert returnStates is not None and len(returnStates)>0
        self.parents = parents
        self.returnStates = returnStates
    end

    def isEmpty
        # since EMPTY_RETURN_STATE can only appear in the last position, we
        # don't need to verify that size==1
        return self.returnStates[0]==PredictionContext.EMPTY_RETURN_STATE
    end

    def length
        return self.returnStates.length()
    end

    def getParent(index)
        return self.parents[index]
    end
    def getReturnState(index)
        return self.returnStates[index]
    end
    def eql?(other)
      self == other
    end
    def ==(other)
        return false if self.class != other.class
        return true if self.object_id == other.object_id
        if self.hash() != other.hash
            false # can't be same if hash is different
        else
            self.returnStates==other.returnStates and self.parents==other.parents
        end
    end

    def to_s
        if self.isEmpty()
            return "[]"
        end
        StringIO.open  do |buf|
            buf.write("[")
            for i in 0..self.returnStates.length-1 do
                buf.write(", ") if i>0
                if self.returnStates[i]==PredictionContext.EMPTY_RETURN_STATE
                    buf.write("$")
                    next
                end
                buf.write(self.returnStates[i].to_s)
                if not self.parents[i].nil?
                    buf.write(' ')
                    buf.write(self.parents[i].to_s())
                end
            end
            buf.write("]")
            return buf.string()
        end
     end
end
#  Convert a {@link RuleContext} tree to a {@link PredictionContext} graph.
#  Return {@link #EMPTY} if {@code outerContext} is empty or null.
#/

module PredictionContextFunctions 

  def self.included(klass)
    klass.send(:include, PredictionContextFunctions::Methods )
    klass.send(:extend, PredictionContextFunctions::Methods )
  end

module Methods
def PredictionContextFromRuleContext(atn, outerContext=nil)
    outerContext = RuleContext.EMPTY if outerContext.nil?

    # if we are in RuleContext of start rule, s, then PredictionContext
    # is EMPTY. Nobody called us. (if we are empty, return empty)
    if outerContext.parentCtx.nil? or outerContext == RuleContext.EMPTY
        return PredictionContext.EMPTY
    end

    # If we have a parent, convert it to a PredictionContext graph
    parent = PredictionContextFromRuleContext(atn, outerContext.parentCtx)
    state = atn.states[outerContext.invokingState]
    transition = state.transitions[0]
    return SingletonPredictionContext.create(parent, transition.followState.stateNumber)
end


def calculateListsHashCode(parents, returnStates)
        str_parents = parents.map{|parent| parent.to_s }
        str_rs = returnStates.map{|r| r.to_s }
        return [str_parents,str_rs].flatten.join('').hash 
end
#def merge(a:PredictionContext, b:PredictionContext, rootIsWildcard:bool, mergeCache:dict):
def merge(a, b, rootIsWildcard, mergeCache)
    #assert a is not None and b is not None # must be empty context, never null

    # share same graph if both same
    return a if a==b

    if a.kind_of? SingletonPredictionContext and b.kind_of? SingletonPredictionContext
        return mergeSingletons(a, b, rootIsWildcard, mergeCache)
    end

    # At least one of a or b is array
    # If one is $ and rootIsWildcard, return $ as# wildcard
    if rootIsWildcard then
        return a if  a.kind_of? EmptyPredictionContext 
        return b if b.kind_of? EmptyPredictionContext 
    end
    # convert singleton so both are arrays to normalize
    if a.kind_of? SingletonPredictionContext 
        a = ArrayPredictionContext.new(a)
    end
    if b.kind_of? SingletonPredictionContext
        b = ArrayPredictionContext.new(b)
    end
    return mergeArrays(a, b, rootIsWildcard, mergeCache)
end

#
# Merge two {@link SingletonPredictionContext} instances.
#
# <p>Stack tops equal, parents merge is same; return left graph.<br>
# <embed src="images/SingletonMerge_SameRootSamePar.svg" type="image/svg+xml"/></p>
#
# <p>Same stack top, parents differ; merge parents giving array node, then
# remainders of those graphs. A new root node is created to point to the
# merged parents.<br>
# <embed src="images/SingletonMerge_SameRootDiffPar.svg" type="image/svg+xml"/></p>
#
# <p>Different stack tops pointing to same parent. Make array node for the
# root where both element in the root point to the same (original)
# parent.<br>
# <embed src="images/SingletonMerge_DiffRootSamePar.svg" type="image/svg+xml"/></p>
#
# <p>Different stack tops pointing to different parents. Make array node for
# the root where each element points to the corresponding original
# parent.<br>
# <embed src="images/SingletonMerge_DiffRootDiffPar.svg" type="image/svg+xml"/></p>
#
# @param a the first {@link SingletonPredictionContext}
# @param b the second {@link SingletonPredictionContext}
# @param rootIsWildcard {@code true} if this is a local-context merge,
# otherwise false to indicate a full-context merge
# @param mergeCache
#/
#def mergeSingletons(a:SingletonPredictionContext, b:SingletonPredictionContext, rootIsWildcard:bool, mergeCache:dict):
def mergeSingletons(a, b, rootIsWildcard, mergeCache)
    if mergeCache then
        previous = mergeCache.get(a,b)
        if not previous.nil? 
            return previous
        end
        previous = mergeCache.get(b,a)
        if not previous.nil? 
            return previous
        end
    end
    rootMerge = mergeRoot(a, b, rootIsWildcard)
    if rootMerge then
        if mergeCache then
            mergeCache.put(a, b, rootMerge)
        end
        return rootMerge
    end

    if a.returnState==b.returnState then
        parent = merge(a.parentCtx, b.parentCtx, rootIsWildcard, mergeCache)
        # if parent is same as existing a or b parent or reduced to a parent, return it
        return a if parent == a.parentCtx # ax + bx = ax, if a=b
        return b if parent == b.parentCtx # ax + bx = bx, if a=b
        # else: ax + ay = a'[x,y]
        # merge parents x and y, giving array node with x,y then remainders
        # of those graphs.  dup a, a' points at merged array
        # new joined parent so create new singleton pointing to it, a'
        a_ = SingletonPredictionContext.create(parent, a.returnState)
        mergeCache.put(a, b, a_) if mergeCache 
        return a_
    else # a != b payloads differ
        # see if we can collapse parents due to $+x parents if local ctx
        singleParent = nil
        if a.object_id == b.object_id or (not a.parentCtx.nil? and a.parentCtx==b.parentCtx) # ax + bx = [a,b]x
            singleParent = a.parentCtx
        end
        if not singleParent.nil? # parents are same
            # sort payloads and use same parent
            payloads = [ a.returnState, b.returnState ]
            if a.returnState > b.returnState then
                payloads[0] = b.returnState
                payloads[1] = a.returnState
            end
            parents = [singleParent, singleParent]
            a_ = ArrayPredictionContext.new(parents, payloads)
            mergeCache.put(a, b, a_) if mergeCache 
            return a_
        end
        # parents differ and can't merge them. Just pack together
        # into array; can't merge.
        # ax + by = [ax,by]
        payloads = [ a.returnState, b.returnState ]
        parents = [ a.parentCtx, b.parentCtx ]
        if a.returnState > b.returnState # sort by payload
            payloads[0] = b.returnState
            payloads[1] = a.returnState
            parents = [ b.parentCtx, a.parentCtx ]
        end
        a_ = ArrayPredictionContext.new(parents, payloads)
        mergeCache.put(a, b, a_) if mergeCache 
        return a_
    end
end


#
# Handle case where at least one of {@code a} or {@code b} is
# {@link #EMPTY}. In the following diagrams, the symbol {@code $} is used
# to represent {@link #EMPTY}.
#
# <h2>Local-Context Merges</h2>
#
# <p>These local-context merge operations are used when {@code rootIsWildcard}
# is true.</p>
#
# <p>{@link #EMPTY} is superset of any graph; return {@link #EMPTY}.<br>
# <embed src="images/LocalMerge_EmptyRoot.svg" type="image/svg+xml"/></p>
#
# <p>{@link #EMPTY} and anything is {@code #EMPTY}, so merged parent is
# {@code #EMPTY}; return left graph.<br>
# <embed src="images/LocalMerge_EmptyParent.svg" type="image/svg+xml"/></p>
#
# <p>Special case of last merge if local context.<br>
# <embed src="images/LocalMerge_DiffRoots.svg" type="image/svg+xml"/></p>
#
# <h2>Full-Context Merges</h2>
#
# <p>These full-context merge operations are used when {@code rootIsWildcard}
# is false.</p>
#
# <p><embed src="images/FullMerge_EmptyRoots.svg" type="image/svg+xml"/></p>
#
# <p>Must keep all contexts; {@link #EMPTY} in array is a special value (and
# null parent).<br>
# <embed src="images/FullMerge_EmptyRoot.svg" type="image/svg+xml"/></p>
#
# <p><embed src="images/FullMerge_SameRoot.svg" type="image/svg+xml"/></p>
#
# @param a the first {@link SingletonPredictionContext}
# @param b the second {@link SingletonPredictionContext}
# @param rootIsWildcard {@code true} if this is a local-context merge,
# otherwise false to indicate a full-context merge
#/
#def mergeRoot(a:SingletonPredictionContext, b:SingletonPredictionContext, rootIsWildcard:bool):
def mergeRoot(a, b, rootIsWildcard)
    if rootIsWildcard
        return PredictionContext.EMPTY if a == PredictionContext.EMPTY ## + b =#
        return PredictionContext.EMPTY if b == PredictionContext.EMPTY # a +# =#
    else
        if a == PredictionContext.EMPTY and b == PredictionContext.EMPTY
            return PredictionContext.EMPTY # $ + $ = $
        elsif a == PredictionContext.EMPTY # $ + x = [$,x]
            payloads = [ b.returnState, PredictionContext.EMPTY_RETURN_STATE ]
            parents = [ b.parentCtx, nil ]
            return ArrayPredictionContext.new(parents, payloads)
        elsif b == PredictionContext.EMPTY # x + $ = [$,x] ($ is always first if present)
            payloads = [ a.returnState, PredictionContext.EMPTY_RETURN_STATE ]
            parents = [ a.parentCtx, nil ]
            return ArrayPredictionContext.new(parents, payloads)
        end
    end
    return nil
end

#
# Merge two {@link ArrayPredictionContext} instances.
#
# <p>Different tops, different parents.<br>
# <embed src="images/ArrayMerge_DiffTopDiffPar.svg" type="image/svg+xml"/></p>
#
# <p>Shared top, same parents.<br>
# <embed src="images/ArrayMerge_ShareTopSamePar.svg" type="image/svg+xml"/></p>
#
# <p>Shared top, different parents.<br>
# <embed src="images/ArrayMerge_ShareTopDiffPar.svg" type="image/svg+xml"/></p>
#
# <p>Shared top, all shared parents.<br>
# <embed src="images/ArrayMerge_ShareTopSharePar.svg" type="image/svg+xml"/></p>
#
# <p>Equal tops, merge parents and reduce top to
# {@link SingletonPredictionContext}.<br>
# <embed src="images/ArrayMerge_EqualTop.svg" type="image/svg+xml"/></p>
#/
#def mergeArrays(a:ArrayPredictionContext, b:ArrayPredictionContext, rootIsWildcard:bool, mergeCache:dict):
def mergeArrays(a, b, rootIsWildcard, mergeCache)
    if mergeCache 
        previous = mergeCache.get(a,b)
        return previous unless previous.nil?
        previous = mergeCache.get(b,a)
        return previous unless previous.nil?
    end
    # merge sorted payloads a + b => M
    i = 0 # walks a
    j = 0 # walks b
    k = 0 # walks target M array

    mergedReturnStates = Array.new(a.returnState.length + b.returnStates.length)
    mergedParents = Array.new(mergedReturnStates.length)
    # walk and merge to yield mergedParents, mergedReturnStates
    while i<a.returnStates.length and j<b.returnStates.length do
        a_parent = a.parents[i]
        b_parent = b.parents[j]
        if a.returnStates[i]==b.returnStates[j] then
            # same payload (stack tops are equal), must yield merged singleton
            payload = a.returnStates[i]
            # $+$ = $
            bothDollars = payload == PredictionContext.EMPTY_RETURN_STATE and \
                            a_parent.nil? and b_parent.nil? 
            ax_ax = ( ! a_parent.nil? and ! b_parent.nil?) and a_parent==b_parent # ax+ax -> ax
            if bothDollars or ax_ax
                mergedParents[k] = a_parent # choose left
                mergedReturnStates[k] = payload
            else # ax+ay -> a'[x,y]
                mergedParent = merge(a_parent, b_parent, rootIsWildcard, mergeCache)
                mergedParents[k] = mergedParent
                mergedReturnStates[k] = payload
            end
            i = i + 1 # hop over left one as usual
            j = j + 1 # but also skip one in right side since we merge
        elsif a.returnStates[i]<b.returnStates[j] # copy a[i] to M
            mergedParents[k] = a_parent
            mergedReturnStates[k] = a.returnStates[i]
            i = i + 1 
        else # b > a, copy b[j] to M
            mergedParents[k] = b_parent
            mergedReturnStates[k] = b.returnStates[j]
            j = j + 1 
        end
        k = k + 1
    end
    # copy over any payloads remaining in either array
    if i < a.returnStates.length then
        for p in i..a.returnStates.length()-1 do 
            mergedParents[k] = a.parents[p]
            mergedReturnStates[k] = a.returnStates[p]
            k = k + 1
        end
    else
        for p in j..b.returnStates.length()-1  do
            mergedParents[k] = b.parents[p]
            mergedReturnStates[k] = b.returnStates[p]
            k = k + 1
        end
    end

    # trim merged if we combined a few that had same stack tops
    if k < mergedParents.length() # write index < last position; trim
        if k == 1 # for just one merged element, return singleton top
            a_ = SingletonPredictionContext.create(mergedParents[0], mergedReturnStates[0])
            mergeCache.put(a,b,a_) if mergeCache 
            return a_
        end
        mergedParents = mergedParents[0,k]
        mergedReturnStates = mergedReturnStates[0,k]
    end
    capM = ArrayPredictionContext.new(mergedParents, mergedReturnStates)

    # if we created same array as a or b, return that instead
    # TODO: track whether this is possible above during merge sort for speed
    if capM==a
        mergeCache.put(a,b,a) if mergeCache 
        return a
    end
    if capM==b
        mergeCache.put(a,b,b) if mergeCache 
        return b
    end
    combineCommonParents(mergedParents)

    mergeCache.put(a,b,capM) if mergeCache 
    return capM
end

#
# Make pass over all <em>M</em> {@code parents}; merge any {@code equals()}
# ones.
#/
def combineCommonParents(parents)
    uniqueParents = Hash.new

    parents.each{|parent| 
        if not uniqueParents.has_key? parent
            uniqueParents[parent] = parent
        end
    }
    parents.each_index {|p|
        parents[p] = uniqueParents[parents[p]]
    }
end
def getCachedPredictionContext(context, contextCache, visited)
    if context.isEmpty()
        return context
    end
    existing = visited[context]
    return existing unless existing.nil? 
    existing = contextCache.get(context)
    if not existing.nil? then 
        visited[context] = existing
        return existing
    end
    changed = false
    parents = Array.new context.lenght()
    parents.each_index do |i| 
        parent = getCachedPredictionContext(context.getParent(i), contextCache, visited)
        if changed or parent != context.getParent(i)
            if not changed then
                parents = Array.new context.length()
                context.each_index {|j| #for j in range(0, len(context)):
                    parents[j] = context.getParent(j)
                }
                changed = True
            end
            parents[i] = parent
        end
    end
    if not changed
        contextCache.add(context)
        visited[context] = context
        return context
    end
    updated = nil
    if parents.length == 0
        updated = PredictionContext.EMPTY
    elsif parents.length == 1
        updated = SingletonPredictionContext.create(parents[0], context.getReturnState(0))
    else
        updated = ArrayPredictionContext(parents, context.returnStates)
    end

    contextCache.add(updated)
    visited[updated] = updated
    visited[context] = updated

    return updated
end

#	# extra structures, but cut/paste/morphed works, so leave it.
#	# seems to do a breadth-first walk
#	public static List<PredictionContext> getAllNodes(PredictionContext context) {
#		Map<PredictionContext, PredictionContext> visited =
#			new IdentityHashMap<PredictionContext, PredictionContext>();
#		Deque<PredictionContext> workList = new ArrayDeque<PredictionContext>();
#		workList.add(context);
#		visited.put(context, context);
#		List<PredictionContext> nodes = new ArrayList<PredictionContext>();
#		while (!workList.isEmpty()) {
#			PredictionContext current = workList.pop();
#			nodes.add(current);
#			for (int i = 0; i < current.size(); i++) {
#				PredictionContext parent = current.getParent(i);
#				if ( parent!=null && visited.put(parent, parent) == null) {
#					workList.push(parent);
#				}
#			}
#		}
#		return nodes;
#	}
# ter's recursive version of Sam's getAllNodes()
def getAllContextNodes(context, nodes=nil, visited=nil)
    if nodes.nil? 
        nodes = Array.new
        return getAllContextNodes(context, nodes, visited)
    elsif visited.nil? 
        visited = Hash.new
        return getAllContextNodes(context, nodes, visited)
    else
        if context.nil? or visited.has_key? context
            return nodes
        end
        visited[context] =  context
        nodes.add(context)
        for i in 0..context.length do
            getAllContextNodes(context.getParent(i), nodes, visited)
        end
        return nodes
    end
end
end
end 
