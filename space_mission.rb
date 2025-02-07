# frozen_string_literal: true

class FuelCalculator
  def self.calculate(mass, action, gravity)
    formula = case action
              when :launch then mass * gravity * 0.042 - 33
              when :land then mass * gravity * 0.033 - 42
              end
    fuel = [formula.floor, 0].max

    Ractor.new(fuel, action, gravity) do |fuel, action, gravity|
      additional_fuel = 0
      while fuel.positive?
        additional_fuel += fuel
        fuel = [(fuel * gravity * (action == :launch ? 0.042 : 0.033) - (action == :launch ? 33 : 42)).floor, 0].max
      end
      additional_fuel
    end.take
  end
end

class SpaceMission
  GRAVITY = {
    earth: 9.807,
    moon: 1.62,
    mars: 3.711
  }

  def initialize(mass, flight_path)
    @mass = mass
    @flight_path = flight_path
  end

  def calculate_total_fuel
    validate_flight_path!
    @flight_path.reverse.reduce(0) do |total_fuel, (action, planet)|
      fuel = FuelCalculator.calculate(@mass + total_fuel, action, GRAVITY[planet.to_sym])
      total_fuel + fuel
    end
  end

  private

  def validate_flight_path!
    @flight_path.each do |_, planet|
      raise "Unknown gravity for #{planet}" unless GRAVITY.key?(planet.to_sym)
    end
  end
end

#To test the code, uncomment the following lines
#apollo_11 = SpaceMission.new(28801, [[:launch, "earth"], [:land, "moon"], [:launch, "moon"], [:land, "earth"]])
#puts "Total fuel required: #{apollo_11.calculate_total_fuel}"
