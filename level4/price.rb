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

       total_fees = (price_distance + price_total_days) * 0.3
       assistance_fee = self.compute_assistance_fee(total_days)
       insurance_fee = total_fees * 0.5
       drivy_fee = total_fees - assistance_fee - insurance_fee

       { "id"    => rental["id"],
         "price" => (price_distance + price_total_days).floor,
         "commission" => {
           "insurance_fee" => insurance_fee.floor,
           "assistance_fee" => assistance_fee.floor,
           "drivy_fee" => drivy_fee.floor
         }
      }
    }
  end

  def self.compute_assistance_fee(total_days)
    100 * total_days
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

  def self.flux(prices)
    rents = self.calculate(prices)

    rents.map{|rent|
      {
        "id" => rent["id"],
        "actions" => [
          { "who" => "driver",     "type" => "debit",  "amount" => rent["price"] },
          { "who" => "owner",      "type" => "credit", "amount" => (rent["price"] * 0.7) },
          { "who" => "insurance",  "type" => "credit", "amount" => rent["commission"]["insurance_fee"]},
          { "who" => "assistance", "type" => "credit", "amount" => rent["commission"]["assistance_fee"]},
          { "who" => "drivy",      "type" => "credit", "amount" => rent["commission"]["drivy_fee"]}
        ]

      }
    }

  end

  def self.flux_to_json(prices)
    { "rentals" => self.flux(prices) }
  end
end
