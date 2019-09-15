require 'json'
require '../price'

RSpec.describe Price do

  let(:input)    { JSON.parse(File.read('../data/input.json')) }
  let(:expected) { JSON.parse(File.read('../data/expected_output.json')) }

  describe "#compute" do
    it "" do
      expect(Price.flux_to_json(input)).to eq(expected)
    end
  end
end
