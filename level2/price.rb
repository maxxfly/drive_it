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

      total_days = (Date.parse(rental["end_date"]) -
                    Date.parse(rental["start_date"])
                    ) + 1

      price_total_days = self.compute_price_total_days(
                           car_rate["price_per_day"],
                           total_days
                         )

      { "id"    => rental["id"],
        "price" => (price_distance + price_total_days).floor
     }
    }
  end

  def self.compute_price_total_days(normal_price_per_day, total_days)
    (1..total_days).map {|number_day|
      normal_price_per_day * ( 1 - self.reduce_long_retail(number_day))
    }.sum
  end

  def self.reduce_long_retail(number_day)
    if number_day > 10
      0.5
    elsif number_day > 4
      0.3
    elsif number_day > 1
      0.1
    else
      0
    end
  end

  def self.calculate_to_json(prices)
    { "rentals" => self.calculate(prices) }
  end
end
