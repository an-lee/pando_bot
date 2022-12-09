# frozen_string_literal: true

# rubocop:disable Naming/MethodParameterName
module PandoBot
  module Lake
    # Uniswap protocal
    class Uniswap
      def initialize; end

      # swap A for B
      # x, y is liquidity of A, B
      # dx is supply amount of A
      # k is liquidity of pair
      def swap(x, y, dx, k = nil)
        x = x.to_f
        y = y.to_f
        dx = dx.to_f

        _k = (k || (x * y)).to_f
        _x = x + dx
        _y = _k / _x
        y - _y
      end

      # swap A for B
      # x, y is liquidity of A, B
      # dx is supply amount of A
      # dy is wanted amount of B
      def swap_reverse(x, y, dy, k = nil)
        x = x.to_f
        y = y.to_f
        dy = dy.to_f

        _k = (k || (x * y)).to_f
        _y = y - dy
        _x = _k / _y
        _x - x
      end

      def price_impact(x, y, dx, dy)
        x = x.to_f
        y = y.to_f
        dx = dx.to_f
        dy = dy.to_f

        return 0 if x.zero? || y.zero?

        [
          (1 - ((y - dy) / (x + dx) / (y / x))),
          0
        ].max.to_f
      end
    end
  end
end
# rubocop:enable Naming/MethodParameterName
