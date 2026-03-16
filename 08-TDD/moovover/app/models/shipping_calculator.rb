class ShippingCalculator
  def self.cost(weight)
    if weight > 10
      weight * 2.0
    else
      weight * 1.5
    end
  end
end
