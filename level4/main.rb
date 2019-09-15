require "./price"
require 'json'

input = JSON.parse(File.read('data/input.json'))

#output = Price.calculate_to_json(input)
output = Price.flux_to_json(input)

file = File.open('data/output.json', 'w')
file.puts output.to_json
file.close
