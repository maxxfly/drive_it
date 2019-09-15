require 'date'

class Price
  def self.get_rate(a, car_id)
    a.each do |rate|
      return rate if rate["id"] == car_id
    end
  end

  def self.calculate(prices)

    prices["rentals"].map{|rental|
      car_rate = self.get_rate(prices["cars"], rental["car_id"])

      price_distance   = car_rate["price_per_km"] * rental["distance"]
      price_total_days = car_rate["price_per_day"] *
                         ((Date.parse(rental["end_date"]) -
                           Date.parse(rental["start_date"])
                          ) + 1)

      { "id"    => rental["id"],
        "price" => (price_distance + price_total_days).floor }
    }
  end

  def self.calculate_to_json(prices)
    { "rentals" => self.calculate(prices) }
  end
end
