require 'rubygems'
require 'spec'
require 'dataflow'

Spec::Runner.configure do |config|
  config.include Dataflow
end

context 'Using "local" for local variables' do
  describe 'An unbound Variable' do
    it 'suspends if an unbound variable has a method called on it until it is bound' do
      local do |big_cat, small_cat|
        t = Thread.new { unify big_cat, small_cat.upcase }
        unify small_cat, 'cat'
        big_cat.should == 'CAT'
      end
    end

    it 'suspends if an unbound variable has a method called on it until it is bound (with nested local variables)' do
      local do |small_cat|
        local do |big_cat|
          t = Thread.new { unify big_cat, small_cat.upcase }
          unify small_cat, 'cat'
          big_cat.should == 'CAT'
        end
      end
    end

    it 'performs order-determining concurrency' do
      local do |x, y, z|
        Thread.new { unify y, x + 2 }
        Thread.new { unify z, y + 3 }
        Thread.new { unify x, 1 }
        z.should == 6
      end
    end
    
    it 'binds on unification' do
      local do |animal|
        unify animal, 'cat'
        animal.should == 'cat'
      end
    end
  end
end

describe 'A bound Variable' do
  it 'does not complain when unifying with an equal object' do
    lambda do
      local do |animal|
        unify animal, 'cat'
        unify animal, 'cat'        
      end
    end.should_not raise_error
  end

  it 'does not complain when unifying with an unequal object when shadowing' do
    lambda do
      local do |animal|
        unify animal, 'cat'
        local do |animal|
          unify animal, 'dog'
        end
      end
    end.should_not raise_error
  end

  it 'complains when unifying with an unequal object' do
    lambda do
      local do |animal|
        unify animal, 'cat'
        unify animal, 'dog'
      end
    end.should raise_error(Dataflow::UnificationError)
  end
end

context 'Using "declare" for object-specific read-only attributes' do
  class Store
    include Dataflow
    declare :animal, :big_cat, :small_cat, :x, :y, :z
  end
  before { @store = Store.new }
  
  describe 'An unbound Variable' do
    it 'suspends if an unbound variable has a method called on it until it is bound' do
      t = Thread.new { unify @store.big_cat, @store.small_cat.upcase }
      unify @store.small_cat, 'cat'
      @store.big_cat.should == 'CAT'
    end

    it 'performs order-determining concurrency' do
      Thread.new { unify @store.y, @store.x + 2 }
      Thread.new { unify @store.z, @store.y + 3 }
      Thread.new { unify @store.x, 1 }
      @store.z.should == 6
    end
    
    it 'binds on unification' do
      unify @store.animal, 'cat'
      @store.animal.should == 'cat'
    end
  end

  describe 'A bound Variable' do
    it 'does not complain when unifying with an equal object' do
      lambda do
        unify @store.animal, 'cat'
        unify @store.animal, 'cat'        
      end.should_not raise_error
    end

    it 'complains when unifying with an unequal object' do
      lambda do
        unify @store.animal, 'cat'
        unify @store.animal, 'dog'
      end.should raise_error(Dataflow::UnificationError)
    end
  end
end