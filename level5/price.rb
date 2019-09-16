require 'date'

class Price
  def self.get_rate(a, car_id)
    a.each do |rate|
      return rate if rate["id"] == car_id
    end
  end

  def self.get_options(a, rent_id)
    a["options"].select{|option| option["rental_id"] == rent_id}
                .map{|e| e["type"]}
  end

  def self.calculate(prices)

    prices["rentals"].map{|rental|
      car_rate = self.get_rate(prices["cars"], rental["car_id"])
      rent_options = self.get_options(prices, rental["id"])

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

       total_price = price_distance + price_total_days

       { "id"         => rental["id"],
         "options"    => rent_options,
         "price"      => total_price,
         "total_days" => total_days,
         "commission" => {
           "insurance_fee"  => insurance_fee,
           "assistance_fee" => assistance_fee,
           "drivy_fee"      => drivy_fee
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

    rents.map do |rent|
      if rent["options"].include?("gps")
        # 5€/day, => owner
        rent["price"] += 500 * rent["total_days"]
      end

      if rent["options"].include?("baby_seat")
        # 2€/day, => owner
        rent["price"] += 200 * rent["total_days"]
      end

      if rent["options"].include?("additional_insurance")
        # 10€/day => Drivy
        rent["price"] +=  1000 * rent["total_days"]
        rent["commission"]["drivy_fee"] += 1000 * rent["total_days"]
      end

      income_owner = rent["price"] - rent["commission"]["insurance_fee"] - rent["commission"]["assistance_fee"] - rent["commission"]["drivy_fee"]

      {
        "id"      => rent["id"],
        "options" => rent["options"],
        "actions" => [
          { "who" => "driver",     "type" => "debit",  "amount" => rent["price"].floor },
          { "who" => "owner",      "type" => "credit", "amount" => income_owner.floor },
          { "who" => "insurance",  "type" => "credit", "amount" => rent["commission"]["insurance_fee"].floor},
          { "who" => "assistance", "type" => "credit", "amount" => rent["commission"]["assistance_fee"].floor},
          { "who" => "drivy",      "type" => "credit", "amount" => rent["commission"]["drivy_fee"].floor}
        ]
      }
    end

  end

  def self.flux_to_json(prices)
    { "rentals" => self.flux(prices) }
  end
end
