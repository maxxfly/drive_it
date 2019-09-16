require 'json'
require '../price'

RSpec.describe Price do

  let(:input)    { JSON.parse(File.read('../data/input.json')) }
  let(:expected) { JSON.parse(File.read('../data/expected_output.json')) }

  describe "#get_options" do
    it "retrieve good options" do
      expect(Price.get_options(input, 1)).to contain_exactly("gps", "baby_seat")
      expect(Price.get_options(input, 2)).to contain_exactly("additional_insurance")
      expect(Price.get_options(input, 3)).to be_empty
    end
  end

  describe "#compute" do
    it "" do
      expect(Price.flux_to_json(input)).to eq(expected)
    end
  end
end
