KvAccessor
==========

Define reader and writer accessor methods for an attribute/method that quacks
like a Hash (`respond_to?(:[])`).

```ruby
class MyCar
  extend KvAccessors
  attr_accessor :details

  kv_accessor :details, :make, 'model'

  def initialize(details = {})
    self.details = details
  end
end

car = MyCar.new(:make => 'Chevrolet', 'model' => 'Camaro')
car.make #=> "Chevrolet"
car.model #=> "Camaro"
```

Installation
------------

Gem

```terminal
$ gem install kv_accessor
```

Bundler

```ruby
gem 'kv_accessor'
```

Usage
-----

Easily encapsulate Hash like objects.

The reader/writer can be named separately from the `#[]`/`#[]=` key via an
alias_accessors argument (this allows for aliasing of complex keys or class
differences like Symbol vs. String).

No initializer is implemented, so any needed initialization is up to the owner.

A word of warning: `#inspect` is called on the `:[]` key the implimentation is
via `class_eval`. `#to_s` is called on the passed `method` name and the method
is called without regard to the receiver (eg. a Kernel method can be called
if no instance method overrides it).

No guarding against user input exists. Only values should come from user input.

Meant as a DSL for creating value style objects that encapsulate a Hash object
so as to avoid inheriting from Hash/OpenStruct. Take a look at Struct,
OpenStruct, and [Virtus](https://github.com/solnic/virtus) for alternatives with
other features.

An extended example:

```ruby
class MyCar
  attr_accessor :details
  extend KvAccessors

  kv_accessor :details, :make, :year => 'model_year',
              :blue_interior_cost => { 'leather' => 'blue' }
  kv_reader :details, 'model', :ac?, :seats
  kv_writer :details, 'price'

  def initialize(details = {})
    self.details = details
  end
end

c = MyCar.new(:make => 'Chevrolet', 'model' => 'Camaro', 'model_year' => 1967,
              'submodel' => 'SS', 'price' => 20_000.00, :ac? => true,
	      :seats => 4, { 'leather' => 'blue' } => 2_000.00)
c.make
#=> "Chevrolet"
c.model
#=> "Camaro"

# Even though the 'submodel' is a part of 'details', all the attributes need to
# be specified.
c.submodel
#=> NoMethodError

# '#model' was defined as a kv_reader only
c.model = 'Corvette'
#=> NoMethodError

# Full on accessor
c.year
#=> 1967
c.year = 1968
#=> 1968
c.year
#=> 1968
c.details['model_year']
#=> 1968

# Using a complex key with alias.
# This example is a little contrived, but this has plenty of uses, like using
# classes as keys.
# This example key lookup would be:
# 'details[{ 'leather' => 'blue' }]'
c.blue_interior_cost
#=> 2_000.00
c.blue_interior_cost = 4_000.00
#=> 4_000.00
c.details[{ 'leather' => 'blue' }]
#=> 4_000.00

# kv_writer with no reader present
c.price
#=> NoMethodError
c.price = 25_000.00
#=> 25_000.00
c.details['price']
#=> 25_000.00

c.details
#=> { :make => "Chevrolet", "model" => "Camaro", "model_year" => 1967,
#     "submodel" => "SS", { "leather" => "blue" } => 4_000.00,
#     "price" => 25_000.00}
```

Can be used for whatever attributes respond to '#[]'/'#[]='.

```ruby
class Employee < ActiveRecord::Base
  store :settings, coder: JSON
  has_one :office
  extend KvAccessors

  # Could just use a normal delegator here, but this shows any object with a
  # '#[]'/'#[]=' can work since ActiveRecord models define a '#[]' interface
  # for their columns.
  kv_reader :office, 'chair', 'table'

  # Define for as many attributes as you like
  kv_accessor :settings, 'wallpaper', :language

  after_initialize { settings ||= {} }
end

c = Employee.new

# Since an '#office' hasn't been assigned yet, this will try to call '#[]' on
# nil. Best to always set a default like 'settings' in 'after_initialize'.
c.chair
#=> NoMethodError

c.office = Office.new(chair: true, table: false)
c.chair
#=> true

c.wallpaper = 'birdy'
```

Since the kv_accessor/reader/writer methods return a hash, an easy pattern to
manage the accessors during runtime would be to assign the result to a const.

```ruby
class MyCar
  extend KvAccessors

  attr_accessor :details

  # The kv_* methods return a hash of 'attribute_name => key' for convenience.
  # I like to use this to easily filter out keys in the initializer.
  SERIALIZABLE_ACCESSORS =
    kv_accessor :details, :make, :year => 'model_year',
                :blue_interior_cost => { 'leather' => 'blue' }

  SERIALIZABL_READERS = SERIALIZABLE_ACCESSORS.merge(
    kv_writer :details, 'model'
  )

  SERIALIZABLE_WRITERS = SERIALIZABLE_ACCESSORS.merge(
    kv_writer :details, 'price'
  )

  def initialize(details = {})
    self.details = details
  end

  def serializable_hash
    ACCESSORS.merge(READERS).merge(WRITERS)
      .map { |name, key| [name.to_s, details[key]] }.to_h
  end
end

c = Car.new(:make => 'Chevrolet', 'model' => 'Camaro', 'model_year' => 1967,
            'submodel' => 'SS', 'price' => 25_000.00,
            { 'leather' => 'blue' } => 4000.00)

c.serializable_hash
#=> { "make" => "Chevrolet", "model" => "Camaro", "year" => 1967,
#     "blue_interior_cost" => 4000.00, "price" => 25_000.00}
```

Resources
---------

[rubydoc.info documentation](http://www.rubydoc.info/gems/kv_accessor)

Contributing
------------

Normal github PR flow.


LICENSE
-------

3 Clause BSD
