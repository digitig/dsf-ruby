# @author Tim Rowe <digitig@gmail.com>
# It is tempting to make Dsf a mixin, but then a simple implementation would only allow an object to be a member
# of a single DSF. Making it a separate class makes it easier for an object to participate in multiple DSFs (though
# not in multiple sets within a single DSF of course -- then they wouldn't be disjoint!)
#
# Consider making a separate dsf_ruby_mixin.

class DsfRuby

  include Enumerable
  # Create an empty DSF
  # @return [DsfRuby]
  def initialize
    @nodes = []
    @lookup = {}
  end

  def each
    @nodes.each {|n| yield n}
  end

  # Add an object to this DSF
  # @param [Object] obj The object to add
  # @return [Object] The object added, or nil if it was already in the DSF
  def add!(obj)
    unless @lookup.has_key?(obj)
      node = Node(obj)
      @nodes << node
      @lookup[obj] = node
    end
  end

  # Create a new DSF based on this one but with a new object added
  # @param [Object] obj The object to add
  # @return [DsfRuby] The new DSF
  def add(obj)
    res self.clone
    res.add!(obj)
    res
  end

  # @param [Object] obj1
  # @param [Object] obj2
  # @return true if obj1 and obj2 belong to the same set in this DSF.
  def same_set?(obj1, obj2)
    node1 = @lookup[obj1]
    node2 = @lookup[obj2]
    return false if node1 == nil || node2 == nil # not even in this DSF!
    node1.repr == node2.repr
  end

  # @param [Object] obj1
  # @param [Object] obj2
  # @return merge the set containing obj1 with the set containing obj2.
  #   if either or both of obj1 and obj2 doesn't belong to the DSF, it will be added to the DSF before the merge
  def merge!(obj1, obj2)
    add(obj1) unless @lookup.has_key?(obj1)
    add(obj2) unless @lookup.has_key?(obj2)
    # TODO complete implementation of merge!
  end

private
    class Node
      def initialize(obj)
        @value = obj
        @parent = self
        @count = 1
      end

      # is n the representative node of its set?
      def repr?(n)
        n.parent == n
      end

      # return the representative node of n
      def repr(n)
        # Apply path compression whenever we lookup the repr
        n.parent = n.parent.repr unless n.parent.repr?
        n.parent
      end

    end
end
