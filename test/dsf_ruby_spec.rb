$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# I'd like to include more test cases, but I don't know how to stop that being ridiculously verbose
# without Cucumber, which at the moment doesn't work on Rub 2.0
require 'dsf-ruby'

describe 'DsfRuby' do
  describe 'when first created' do
    before(:each) do
      @dsf = DsfRuby.new
    end
    it 'is empty' do
      @dsf.count.should == 0
    end
    it 'is consistent' do
      @dsf.consistent?.should == true
    end
  end

  describe 'applying mutable operations' do
    describe 'when a single item is added' do
      context 'to an empty dsf' do
        before(:each) do
          @dsf      = DsfRuby.new
          @test_obj = 0
          @dsf.add!(@test_obj)
        end
        it 'has a size of 1' do
          @dsf.count.should == 1
        end
        it 'contains that element' do
          @dsf.has_element?(@test_obj).should == true
        end
        it 'contains a set that contains the added item' do
          (@dsf.find { |o| o.include?(@test_obj) }).should_not == nil
        end
        it 'should contain the added element in that one set' do
          sets = @dsf.sets().first()
          sets.include?(@test_obj).should == true
        end
        it 'is consistent' do
          @dsf.consistent?.should == true
        end
      end
      context 'to a dsf that does not already contain that item' do
        before(:each) do
          @dsf      = DsfRuby.new
          @test_obj = 1
          @dsf.add!(0)
          @prev_size = @dsf.count
          @prev_dsf  = @dsf.clone
          @dsf.add!(@test_obj)
        end
        it 'has a size one greater than before' do
          @dsf.count.should == @prev_size + 1
        end
        it 'contains that element' do
          @dsf.has_element?(@test_obj).should == true
        end
        it 'contains a set that contains the added item' do
          (@dsf.find { |o| o.include?(@test_obj) }).should_not == nil
        end

        it 'contains all the items it did previously' do
          @prev_dsf.each { |item|
            @dsf.include?(item).should == true
          }
        end
        it 'is consistent' do
          @dsf.consistent?.should == true
        end
      end
      context 'to a dsf that already contains that item' do
        before (:each) do
          @dsf      = DsfRuby.new
          @test_obj = 0
          @dsf.add!(@test_obj)
          @prev_size = @dsf.count
          @prev_dsf  = @dsf.clone
          @dsf.add!(@test_obj)
        end
        it 'has the same size as before' do
          @dsf.count.should == @prev_dsf.count
        end
        it 'contains all the items it did previously' do
          @prev_dsf.each { |item|
            @dsf.include?(item).should == true
          }
        end
        it 'is consistent' do
          @dsf.consistent?.should == true
        end
      end
    end
    describe 'when an enumerable collection of items is added' do
      context 'to an empty dsf' do
        before (:each) do
          @dsf = DsfRuby.new
        end
        it 'contains each element of the enumeration exactly once' do
          test_enum = [1, 2, 3, 1, 4]
          @dsf.add!(test_enum)
          @dsf.count.should == 4
          test_enum.each { |o| @dsf.has_element?(o).should == true }
        end
      end
    end
    describe 'when two member objects are merged' do
      context 'each set is a singleton' do
        before (:each) do
          @dsf  = DsfRuby.new
          @objs = [1, 2, 3]
          @dsf.add!(@objs)
          @prev_dsf_count = @dsf.count
          @dsf.merge!(@objs[0], @objs[2])
        end
        it 'contains one fewer set' do
          @dsf.count.should == @prev_dsf_count - 1
        end
        it 'contains a set that includes the joined members' do
          (@dsf.find { |s| s.include?(@objs[0]) && s.include?(@objs[2]) }).should_not == nil
        end
        it 'is consistent' do
          @dsf.consistent?.should == true
        end
      end
      context 'each set is a member of a different set of more than one item' do
        before (:each) do
          @dsf  = DsfRuby.new
          @objs = [1, 2, 3, 4, 5]
          @dsf.add!(@objs)
          @dsf.merge!(@objs[0], @objs[2])
          @dsf.merge!(@objs[1], @objs[3])
          @prev_dsf_count = @dsf.count
          @dsf.merge!(@objs[0], @objs[3])
        end
        it 'contains one fewer set' do
          @dsf.count.should == @prev_dsf_count - 1
        end
        it 'contains a set that includes the joined members' do
          (@dsf.find { |s|
            s.include?(@objs[0]) &&
                s.include?(@objs[1]) &&
                s.include?(@objs[2]) &&
                s.include?(@objs[3])
          }).should_not == nil
        end
      end
      context 'the merged items already belong the same set' do
        before (:each) do
          @dsf  = DsfRuby.new
          @objs = [1, 2, 3, 4, 5]
          @dsf.add!(@objs)
          @dsf.merge!(@objs[0], @objs[1])
          @dsf.merge!(@objs[1], @objs[2])
          @prev_dsf_sets = @dsf.sets
          @dsf.merge!(@objs[0], @objs[2])
        end
        it 'leaves the set unchanged' do
          @dsf.sets.should == @prev_dsf_sets
        end
      end
    end

    describe 'when an item is removed' do
      context 'the item is a member of the set' do
        before (:all) do
          @dsf = DsfRuby.new
          @dsf.add!([1, 2, 3])
          @result = @dsf.remove!(2)
        end
        it 'no longer contains that element' do
          @dsf.has_element?(2).should == false
        end
        it 'returns the removed element' do
          @result.should == 2
        end
        it 'is consistent' do
          @dsf.consistent?.should == true
        end
      end
      context 'the item is a member of a non-singleton set' do
        before (:each) do
          @dsf = DsfRuby.new
          @dsf.add!([1, 2, 3])
          @dsf.merge!(1, 2)
        end
        # here's a place where I would like to use Cucumber to define a whole set of test cases
        it 'no longer contains that element (1)' do
          @dsf.remove!(1)
          @dsf.has_element?(1).should == false
          @dsf.sets.count.should == 2
          @dsf.consistent?.should == true
        end
        it 'no longer contains that element (2)' do
          @dsf.remove!(2)
          @dsf.has_element?(2).should == false
          @dsf.sets.count.should == 2
          @dsf.consistent?.should == true
        end
      end
      context 'the item is not a member of the set' do
        before (:all) do
          @dsf = DsfRuby.new
          @dsf.add!([1, 2, 3])
          @result = @dsf.remove!(4)
        end
        it 'returns nil' do
          @result.should == nil
        end
        it 'is consistent' do
          @dsf.consistent?.should == true
        end
      end
    end
  end
  describe 'applying immutable operations' do
    describe 'when a single item is added' do
      context 'to an empty dsf' do
        before(:each) do
          @dsf      = DsfRuby.new
          @test_obj = 0
          @new_dsf  = @dsf.add(@test_obj)
        end
        it 'has a size of 1' do
          @new_dsf.count.should == 1
        end
        it 'contains that element' do
          @new_dsf.has_element?(@test_obj).should == true
        end
        it 'contains a set that contains the added item' do
          (@new_dsf.find { |o| o.include?(@test_obj) }).should_not == nil
        end
        it 'should contain the added element in that one set' do
          sets = @new_dsf.sets().first()
          sets.include?(@test_obj).should == true
        end
      end
      context 'to a dsf that does not already contain that item' do
        before(:each) do
          @dsf      = DsfRuby.new
          @test_obj = 1
          @dsf.add!(0)
          @new_dsf = @dsf.add(@test_obj)
        end
        it 'has a size one greater than before' do
          @new_dsf.count.should == @dsf.count + 1
        end
        it 'contains that element' do
          @new_dsf.has_element?(@test_obj).should == true
        end
        it 'contains a set that contains the added item' do
          (@new_dsf.find { |o| o.include?(@test_obj) }).should_not == nil
        end
        it 'leaves the existing dsf without that element' do
          (@dsf.find { |o| o.include?(@test_obj) }).should == nil
        end

        it 'contains all the items the old one did' do
          @dsf.sets.flatten.each { |item|
            @new_dsf.include?(item).should == true
          }
        end
        context 'to a dsf that already contains that item' do
          before (:each) do
            @dsf      = DsfRuby.new
            @test_obj = 0
            @dsf.add!(@test_obj)
            @new_dsf = @dsf.add(@test_obj)
          end
          it 'has the same size as before' do
            @new_dsf.count.should == @dsf.count
          end
          it 'contains all the items it did previously' do
            @dsf.sets.flatten.each { |item|
              @new_dsf.include?(item).should == true
            }
          end
        end
      end
    end
    describe 'when an enumerable collection of items is added' do
      context 'to an empty dsf' do
        before (:each) do
          @dsf = DsfRuby.new
        end
        it 'contains each element of the enumeration exactly once' do
          test_enum = [1, 2, 3, 1, 4]
          @new_dsf  = @dsf.add(test_enum)
          @new_dsf.count.should == 4
          test_enum.each { |o| @new_dsf.has_element?(o).should == true }
        end
        it 'should leave the old dsf empty' do
          @dsf.count.should == 0
        end
      end
    end
    describe 'when two member objects are merged' do
      context 'each set is a singleton' do
        before (:each) do
          @dsf  = DsfRuby.new
          @objs = [1, 2, 3]
          @dsf.add!(@objs)
          @new_dsf = @dsf.merge(@objs[0], @objs[2])
        end
        it 'contains one fewer set' do
          @new_dsf.count.should == @dsf.count - 1
        end
        it 'contains a set that includes the joined members' do
          (@new_dsf.find { |s| s.include?(@objs[0]) && s.include?(@objs[2]) }).should_not == nil
        end
      end
      context 'each set is a member of a different set of more than one item' do
        before (:each) do
          @dsf  = DsfRuby.new
          @objs = [1, 2, 3, 4, 5]
          @dsf.add!(@objs)
          @dsf.merge!(@objs[0], @objs[2])
          @dsf.merge!(@objs[1], @objs[3])
          @new_dsf = @dsf.merge(@objs[0], @objs[3])
        end
        it 'contains one fewer set' do
          @new_dsf.count.should == @dsf.count - 1
        end
        it 'contains a set that includes the joined members' do
          (@new_dsf.find { |s|
            s.include?(@objs[0]) &&
                s.include?(@objs[1]) &&
                s.include?(@objs[2]) &&
                s.include?(@objs[3])
          }).should_not == nil
        end
      end
      context 'the merged items already belong the same set' do
        before (:each) do
          @dsf  = DsfRuby.new
          @objs = [1, 2, 3, 4, 5]
          @dsf.add!(@objs)
          @dsf.merge!(@objs[0], @objs[1])
          @dsf.merge!(@objs[1], @objs[2])
          @new_dsf = @dsf.merge(@objs[0], @objs[2])
        end
        it 'leaves the set unchanged' do
          @new_dsf.sets.should == @dsf.sets
        end
      end
    end

    describe 'when an item is removed' do
      context 'the item is a member of the set' do
        before (:all) do
          @dsf = DsfRuby.new
          @dsf.add!([1, 2, 3])
          @new_dsf = @dsf.remove(2)
        end
        it 'no longer contains that element' do
          @new_dsf.has_element?(2).should == false
        end
        it 'leaves the item in the old set' do
          @dsf.has_element?(2).should == true
        end
      end
      context 'the item is not a member of the set' do
        before (:all) do
          @dsf = DsfRuby.new
          @dsf.add!([1, 2, 3])
          @new_dsf = @dsf.remove(4)
        end
        it 'does nothing' do
          @new_dsf.should == @dsf
        end
      end
    end

  end
end
