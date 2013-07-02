# @author Tim Rowe <digitig@gmail.com>
# It is tempting to make Dsf a mixin, but then a simple implementation would only allow an object to be a member
# of a single DSF. Making it a separate class makes it easier for an object to participate in multiple DSFs (though
# not in multiple sets within a single DSF of course -- then they wouldn't be disjoint!)
#
# Consider making a separate dsf_ruby_mixin.
#
# This is an exercise in learning Ruby, so it is probably not very idiomatic (and it could probably be made a lot more
# efficient), Improvements welcome!

class DsfRuby

  include Enumerable
  # Create an empty DSF
  # @return [DsfRuby]
  def initialize
    @nodes  = []
    @lookup = {}
  end

  # @yield each set in the forest
  def each
    sets.each { |s| yield s }
  end

  # Add one or more objects to this DSF
  # @param [Object] obj The object or objects to add
  # @return [Object] The object added, or nil if it was already in the DSF
  def add!(obj)
    [*obj].each { |o| add_helper!(o) }
  end

  # @param [Object] obj1
  # @param [Object] obj2
  # @return merge the set containing obj1 with the set containing obj2.
  #   if either or both of obj1 and obj2 doesn't belong to the DSF, it will be added to the DSF before the merge
  def merge!(obj1, obj2)
    add(obj1) unless @lookup.has_key?(obj1)
    add(obj2) unless @lookup.has_key?(obj2)
    unless same_set?(obj1, obj2)
      node1, node2 = @lookup[obj1], @lookup[obj2]
      root, child  = node1.count > node2.count ? [node1.repr, node2.repr] : [node2.repr, node1.repr]
      root.count   += child.count
      child.parent = root
    end
  end

  # remove an item from the forest
  def remove!(obj)
    if has_element?(obj)
      node = @lookup[obj]
      @nodes.delete(node)
      if node.repr?
        new_repr = @nodes.find { |n|
          n.parent == node
        }
        if new_repr
          new_repr.parent       = node.parent
          new_repr.parent.count -= 1
          @nodes.each { |n|
            if n.parent == node
              n.parent       = new_repr
              new_repr.count += n.count
            end
          }
        end
      end
      @lookup.delete(obj)
      obj
    end
  end

  def has_element?(e)
    @lookup.include?(e)
  end

  # Create a new DSF based on this one but with a new object added
  # @param [Object] obj The object to add
  # @return [DsfRuby] The new DSF
  def add(obj)
    res = self.clone
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

  def merge(obj1, obj2)
    res = clone
    res.merge!(obj1, obj2)
    res
  end

  def remove(obj)
    res = clone
    res.remove!(obj)
    res
  end

  #@return [Enumerable<Enumerable<Object>>] The individual disjoint sets in the DSF. The sets are in arbitrary order,
  #   and the members of each set are in arbitrary order. Note that the sets are represented as being Enumerable: there
  #   is no guarantee that they will be instances of the Set class
  def sets
    # gather the values in each set
    representative_sets = {}
    @nodes.each { |n| (representative_sets[n.repr] ||= Set.new()) << n.value }
    result = []
    representative_sets.each_value { |n|
      result << n
    }
    result
  end

  def clone
    res = DsfRuby.new
    sets.each { |set|
      res.add!(set)
      repr = set.first
      set.each { |obj| res.merge!(repr, obj) }
    }
    res
  end

  def ==(other)
    sets == other.sets
  end

  # for debugging
  def consistent?
    @nodes.all? { |n|
      @nodes.include?(n.parent) && # All nodes have a valid parent
          @lookup.values.count { |v| v == n } == 1 && # All nodes are the destination of a single lookup
          @nodes.count == @lookup.count }
  end

  private
  class Node
    def initialize(obj)
      @value  = obj
      @parent = self
      @count  = 1
    end

    # is n the representative node of its set?
    def repr?
      @parent == self
    end

    # return the representative node of n
    def repr
      # Apply path compression whenever we lookup the repr
      unless @parent.repr?
        @parent.count        -= count
        @parent.parent.count += count
        @parent              = @parent.repr
      end
      @parent
    end

    def to_a
      "Node #{id}: value = #{@value}; parent = #{@parent}"
    end

    attr_accessor :count, :parent
    attr_reader :value
  end

  def add_helper!(obj)
    unless @lookup.has_key?(obj)
      node = Node.new(obj)
      @nodes << node
      @lookup[obj] = node
    end
  end
end
