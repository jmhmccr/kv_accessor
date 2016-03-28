# Define reader and writer accessors for a Hash like instance method.
#
# Define reader and writer methods for a method returning a duck that quacks
# like a Hash (`respond_to?(:[]`). The reader/writer can be named separately
# from the ':[]' key via the alias_accessors argument (this allows for aliasing
# of complex keys).
#
# A word of warning: '#inspect' is called on the ':[]' key,
# '#to_s' is called on the 'key' name and the implimentation is via
# 'class_eval'. '#to_s' is called on the passed 'method' name and the method
# is called without regard to the receiver (eg. a Kernel method can be called
# if no instance method overrides it).
#
# This is purely meant to be a DSL for creating value style objects. Take a look
# at Struct, OpenStruct, and Virtus before choosing this.
#
# @example
#   class MyCar
#     attr_accessor :details
#     extend KvAccessors
#     kv_accessor :details, :make, year: 'model_year',
#                 options: { 'leather' => 'blue' }
#     kv_reader 'model'
#
#     def initialize(details = {})
#       @details = details
#     end
#   end
#
#   c = MyCar.new(:make => 'Chevrolet', 'model' => 'Camaro',
#                 'model_year' => 1967, 'submodel' => 'SS',
#                 { 'leather' => 'blue' } => 2000.00)
#   c.make
#   #=> "Chevrolet"
#   c.model
#   #=> "Camaro"
#   c.model = 'Corvette'
#   #=> NoMethodError
#   c.year
#   #=> 1967
#   c.year = 1968
#   #=> 1968
#   c.year
#   #=> 1968
#
#   # using a complex key with alias. The key lookup would be:
#   # details[{ 'leather' => 'blue' }]
#   c.options
#   #=> 2000.00
#   c.options
#   #=> 4000.00
#
#   c.submodel
#   #=> NoMethodError
#   c.details
#   #=> { :make => "Chevrolet", "model" => "Camaro", "model_year" => 1967,
#   #     "submodel" => "SS", { "leather" => "blue" } => 4000.00 }
module KvAccessor
  # Define reader and writter accessors for a Hash like instance method.
  #
  # Define reader and writter methods for each +keys+. Accessors named
  # other than the key name can be defined via +aliased_accessors+.
  # Calls to +name+ will call ':[]' on +method+ with either +key+ or the
  # value described via +aliased_accessors+.
  #
  # See the overall {KvAccessors} docs for a better definition of what gets
  # called on what.
  #
  # This is not guarded against any sort of user input. You have been warned.
  #
  # @example
  #   class MyCar
  #     attr_accessor :details
  #     extend KvAccessors
  #     kv_accessor :details, :make, 'model', year: :model_year
  #
  #     def initialize(details = {})
  #       @details = details
  #     end
  #   end
  #
  #   c = MyCar.new(:make => 'Chevrolet', 'model' => 'Camaro',
  #                 :model_year => 1967, 'submodel' => 'SS')
  #   c.make
  #   #=> "Chevrolet"
  #   c.model
  #   #=> "Camaro"
  #   c.year
  #   #=> 1966
  #   c.year = 1967
  #   #=> 1967
  #   c.year
  #   #=> 1967
  #   c.submodel
  #   #=> NoMethodError
  #   c.details
  #   #=> { :make => "Chevrolet", "model" => "Camaro", :model_year => 1968,
  #   #     "submodel" => "SS"
  def kv_accessor(method, *keys, **aliased_accessors)
    kv_reader(method, *keys, **aliased_accessors)
    kv_writer(method, *keys, **aliased_accessors)
  end

  # Define reader accessors for a Hash like instance method.
  #
  # Define reader accessor methods for each +keys+. Accessors named other than
  # the key name can be defined via +aliased_accessors+. Calls to +name+ will
  # call ':[]' on +method+ with either +key+ or the value described via
  # +aliased_accessors+.
  #
  # See the overall {KvAccessors} docs for a better definition of what gets
  # called on what.
  #
  # This is not guarded against any sort of user input. You have been warned.
  #
  # @example
  #   class MyCar
  #     attr_accessor :details
  #     extend KvAccessors
  #     kv_accessor :details, :make, 'model', year: :model_year
  #
  #     def initialize(details = {})
  #       @details = details
  #     end
  #   end
  #
  #   c = MyCar.new(:make => 'Chevrolet', 'model' => 'Camaro',
  #                 :model_year => 1967, 'submodel' => 'SS')
  #   c.make #=> "Chevrolet"
  #   c.model #=> "Camaro"
  #   c.year #=> 1967
  #   c.year = 1968
  #   c.year #=> 1968
  #   c.submodel #=> NoMethodError
  #   c.details
  #   #=> { :make => "Chevrolet", "model" => "Camaro", :model_year => 1968,
  #         "submodel" => "SS" }
  def kv_reader(method, *keys, **aliased_accessors)
    accessors = Hash[keys.map { |v| [v, v] }].merge(aliased_accessors)
    accessors.each do |name, key|
      begin
        line_no = __LINE__ + 1
        str = <<-EOMETHODDEF
          def #{name}
            #{method}[#{key.inspect}]
          end
        EOMETHODDEF

        module_eval(str, __FILE__, line_no)
      # If it's not a class or module, it's an instance
      rescue NoMethodError
        instance_eval(str, __FILE__, line_no)
      end
    end
  end

  # Define writter accessors for a Hash like instance method.
  #
  # Define writter accessor methods for each +keys+. Accessors named other than
  # the key name can be defined via +aliased_accessors+. Calls to +name+ will
  # call ':[]' on +method+ with either +key+ or the value described via
  # +aliased_accessors+.
  #
  # See the overall {KvAccessors} docs for a better definition of what gets
  # called on what.
  #
  # This is not guarded against any sort of user input. You have been warned.
  #
  # @example
  #   class MyCar
  #     attr_accessor :details
  #     extend KvAccessors
  #     kv_writer :details, 'model', year: :model_year
  #
  #     def initialize(details = {})
  #       @details = details
  #     end
  #   end
  #
  #   c = MyCar.new(:make => 'Chevrolet', 'model' => 'Camaro',
  #                 :model_year => 1967, 'submodel' => 'SS')
  #   c.make
  #   #=> NoMethodError
  #   c.model = 'Corvette'
  #   #=> "Corevette"
  #   #=> 1967
  #   c.year = 1968
  #   #=> 1968
  #   c.year
  #   #=> NoMethodError
  #   c.submodel = 'RS'
  #   #=> NoMethodError
  #   c.details
  #   #=> { :make => "Chevrolet", "model" => "Corvette", :model_year => 1968,
  #   #     "submodel" => "SS"
  def kv_writer(method, *keys, **aliased_accessors)
    accessors = Hash[keys.map { |v| [v, v] }].merge(aliased_accessors)
    accessors.each do |name, key|
      begin
        line_no = __LINE__ + 1
        str = <<-EOMETHODDEF
          def #{name}=(value)
            #{method}[#{key.inspect}] = value
          end
        EOMETHODDEF

        module_eval(str, __FILE__, line_no)
      # If it's not a class or module, it's an instance
      rescue NoMethodError
        instance_eval(str, __FILE__, line_no)
      end
    end
  end
end
