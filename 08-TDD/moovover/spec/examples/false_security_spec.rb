# ============================================================
# EXERCISE 6: The False Security Demo
# ============================================================
# This spec achieves 100% C0 AND C1 coverage on ShippingCalculator,
# yet it misses a critical boundary bug.
#
# After running, open coverage/index.html and click on
# shipping_calculator.rb — you should see 100% coverage (all green).
#
# Then discuss:
#   1. What happens when weight == 10?
#   2. Is weight == 10 "heavy" (cost = 20.0) or "light" (cost = 15.0)?
#   3. The spec says nothing about this boundary — yet coverage is 100%.
#   4. What does this tell us about the limits of code coverage?
# ============================================================

require "rails_helper"

RSpec.describe ShippingCalculator do
  it "calculates shipping for a heavy item" do
    expect(ShippingCalculator.cost(15)).to eq(30.0)
  end

  it "calculates shipping for a light item" do
    expect(ShippingCalculator.cost(5)).to eq(7.5)
  end


  # BUG: What happens when weight == 10?
  # The boundary condition is never tested.
  # Is 10 "heavy" or "light"? The spec doesn't say.
  # Coverage shows 100% green — but the boundary is ambiguous.
  #
  # BONUS: Write a spec that tests ShippingCalculator.cost(10).
  # What should the expected result be? 20.0 or 15.0?
  # You need the requirements (not just the code) to decide.
end
