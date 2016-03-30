# Define reader and writer accessors for a Hash like instance method.
#
# Define reader and writer methods for a method returning a duck that quacks
# like a Hash (`respond_to?(:[])`). The reader/writer can be named separately
# from the '#[]'/'#[]=' key via the alias_accessors argument (this allows for
# aliasing of complex keys or types).
#
# A word of warning: '#inspect' is called on the ':[]' key,
# '#to_s' is called on the 'key' name and the implimentation is via
# 'class_eval'. '#to_s' is called on the passed 'method' name and the method
# is called without regard to the receiver (eg. a Kernel method can be called
# if no instance method overrides it).
#
# Meant as a DSL for creating value style objects that encapsulate a Hash object
# so as to avoid hacks like inheriting from Hash/OpenStruct. Take a look at
# Struct, OpenStruct, and [Virtus](https://github.com/solnic/virtus) for
# alternatives with other features.
#
# @example
#   class MyCar
#     attr_accessor :details
#     extend KvAccessors
#     kv_accessor :details, :make, year: 'model_year',
#                 options: { 'leather' => 'blue' }
#     kv_reader :details, 'model'
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
  #
  # @param keys [#to_s] used for both the key and the attribute name
  # @param aliased_accessors [Hash< #to_s, #inspect >] the key of
  #   aliased_accessors is used as the attribute method name and the value of
  #   aliased_accessors is used as the first argument to `#[]`/`#[]=` off
  #   `method`
  #
  # @return [Hash] all the attribute name => method[key] so this method can be
  #   meaningfully chained.
  #   @example
  #     class Employee
  #       attr_accessor :info
  #       ATTRIBUTES = kv_accessor :info, :ssid, :dob
  #
  #       def initalize(info)
  #         self.info = info.select { |k, v| ATTRIBUTES.key?(k) }
  #       end
  #     end
  def kv_accessor(method, *keys, **aliased_accessors)
    kv_reader(method, *keys, **aliased_accessors).merge(
      kv_writer(method, *keys, **aliased_accessors)
    )
  end

  # Define reader accessors for a Hash like instance method.
  #
  # Define reader accessor methods for each keys+. Accessors named other than
  # the key name can be defined via +aliased_accessors+. Calls to either a
  # +keys+ attribute name or the key of +aliased_accessor+ will call ':[]' off
  # of +method+ with either +key+ or the value described via +aliased_accessors+.
  #
  # @example
  #   class MyCar
  #     attr_accessor :details
  #     extend KvAccessors
  #     kv_reader :details, :make, 'model', year: :model_year
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
  #   c.year = 1968 #=> NoMethodError
  #   c.submodel #=> NoMethodError
  #   c.details
  #   #=> { :make => "Chevrolet", "model" => "Camaro", :model_year => 1967,
  #         "submodel" => "SS" }
  #
  # See the overall {KvAccessors} docs for a better definition of what gets
  # called on what.
  #
  # This is not guarded against any sort of user input. You have been warned.
  #
  # @see kv_accessor
  #
  # @param keys [#to_s] used for both the key and the attribute name
  # @param aliased_accessors [Hash< #to_s, #inspect >] the key of
  #   aliased_accessors is used as the attribute method name and the value of
  #   aliased_accessors is used as the argument to `#[]` off `method`
  #
  # @return [Hash] all the attribute name => method[key] so this method can be
  #   meaningfully chained.
  #   @example
  #     class Employee
  #       attr_accessor :info
  #       ATTRIBUTES = kv_reader :info, :ssid, :birth
  #
  #       def initalize(info)
  #         self.info = info.select { |k, v| ATTRIBUTES.key?(k) }
  #       end
  #     end
  #     employee = Employee.new(ssid: '123-456-7890', birth: '1979-06-23',
  #                             eye_color: 'brown')
  #     employee.birth #=> '1979-06-23'
  #     employee.info
  #     #=> { ssid: '123-456-7890', birth: '1979-06-23' }
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
  # the key name can be defined via +aliased_accessors+. Calls to either a
  # +keys+ attribute name or the key of +aliased_accessor+ will call '#:[]=' off
  # of +method+ with either +key+ or the value described via
  # +aliased_accessors+.
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
  #
  # See the overall {KvAccessors} docs for a better definition of what gets
  # called on what.
  #
  # This is not guarded against any sort of user input. You have been warned.
  #
  # @see kv_accessor
  #
  # @param keys [#to_s] used for both the key and the attribute name
  # @param aliased_accessors [Hash< #to_s, #inspect >] the key of
  #   aliased_accessors is used as the attribute method name and the value of
  #   aliased_accessors is used as the argument to `#[]=` off `method`
  #
  # @return [Hash] all the attribute name => method[key] so this method can be
  #   meaningfully chained.
  #   @example
  #     class Employee
  #       attr_accessor :info
  #       ATTRIBUTES = kv_writer :info, :ssid, :birth
  #
  #       def initalize(info)
  #         self.info = info.select { |k, v| ATTRIBUTES.key?(k) }
  #       end
  #     end
  #
  #     employee = Employee.new(ssid: '123-456-7890', birth: '1979-06-23',
  #                             eye_color: 'brown')
  #     employee.ssid = '555-555-5555'
  #     employee.info
  #     #=> { ssid: '555-555-5555', birth: '1979-06-23' }
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
