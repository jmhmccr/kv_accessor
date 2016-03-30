require 'spec_helper'

RSpec.describe KvAccessor do
  let(:default_details) do
    {
      :make => 'Chevrolet', 'model' => 'Camaro', :model => 'Key not string',
      'submodel' => 'SS', 'model_year' => 1967, price: 40_000.00,
      { 'leather' => 'blue' } => 2_000.00
    }
  end

  let(:default_other) { { upc: '808' } }

  let(:kv_class) do
    Class.new do
      attr_accessor :details, :other
      extend KvAccessor

      # The self is required for consts in anonymous classes.
      self::DETAILS_ACCESSORS =
        kv_accessor :details, :make, year: 'model_year',
                    blue_interior: { 'leather' => 'blue' }

      self::DETAILS_READERS = self::DETAILS_ACCESSORS.merge(
        kv_reader :details, 'model', :price
      )

      self::DETAILS_WRITERS = self::DETAILS_ACCESSORS.merge(
        kv_writer :details, 'color', :price
      )

      self::OTHER_ACCESSORS =
        kv_accessor :other, :upc

      def initialize(details, other)
        self.details = details
        self.other = other
      end
    end
  end

  # For the expect to change, the duping is somehow necessary
  subject(:data_object) { kv_class.new(default_details.dup, default_other.dup) }

  it 'responds to all the accessor names specified' do
    expect(data_object).to respond_to(:make, :year, :blue_interior, :make=,
                                      :year=, :blue_interior=, :model, :price,
                                      :color=, :price=, :upc)
  end

  it 'does not respond to unspecified readers/writers' do
    expect(data_object).not_to respond_to(:submodel, :model=)
  end

  it 'fetches all corresponding reader attributes' do
    expect(data_object).to have_attributes(
      make: 'Chevrolet', model: 'Camaro', blue_interior: 2_000.00,
      price: 40_000.00, year: 1967, upc: '808'
    )
  end

  describe 'attribute assignment' do
    before do
      data_object.make = 'Ford'
      data_object.price = 41_000.00
      data_object.year = 1968
      data_object.blue_interior = 3_000.00
      data_object.color = 'red'
      data_object.upc = '809'
    end

    it 'updates the specified key-value objects' do
      expect(data_object).to have_attributes(
        details: default_details.merge(:make => 'Ford', :price => 41_000.00,
                                       'model_year' => 1968, 'color' => 'red',
                                       { 'leather' => 'blue' } => 3_000.00),
        other: { upc: '809' }
      )
    end

    it 'all the updates are available via the attribute methods' do
      expect(data_object).to have_attributes(
        make: 'Ford', price: 41_000.00, year: 1968, blue_interior: 3_000.00,
        upc: '809'
      )
    end
  end

  describe '.kv_accessor' do
    it 'returns the hash of attributes for the kv_accessor' do
      expect(
        Class.new { extend KvAccessor }
          .kv_accessor(:attributes, :mayonnaise, year: 'release date')
      ).to eq(mayonnaise: :mayonnaise, year: 'release date')
    end
  end

  describe '.kv_reader' do
    it 'returns the hash of attributes for the kv_reader' do
      expect(
        Class.new { extend KvAccessor }
          .kv_reader(:attributes, :iscariot, release: 'born')
      ).to eq(iscariot: :iscariot, release: 'born')
    end
  end

  describe '.kv_writer' do
    it 'returns the hash of attributes for the kv_writer' do
      expect(
        Class.new { extend KvAccessor }
          .kv_writer(:attributes, :adore, vocals: 'singers')
      ).to eq(adore: :adore, vocals: 'singers')
    end
  end
end
