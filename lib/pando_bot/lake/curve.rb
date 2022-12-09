# frozen_string_literal: true

# rubocop:disable Naming/MethodParameterName
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
module PandoBot
  module Lake
    # Curve protocal
    class Curve
      A_CONST = 200
      N_COINS = 2
      ONE = 1
      TWO = 2

      attr_reader :a

      def initialize(a = A_CONST)
        @a = a
      end

      def d_const(xp = [])
        xp = xp.map(&:to_f)
        sum = xp.sum
        return 0 if sum <= 0

        dp = 0
        d = sum
        ann = a * N_COINS

        255.times do
          _dp = d

          xp.each do |x|
            _dp = _dp * d / (x * N_COINS)
          end

          dp = d

          d1 = (ann - ONE) * d
          d2 = (N_COINS + ONE) * _dp
          d = (((ann * sum) + (_dp * N_COINS)) * d) / (d1 + d2)

          break if (d - dp).floor(0).zero?
        end

        d.floor(0)
      end

      def y_const(d, x)
        d = d.to_f
        x = x.to_f

        ann = a * N_COINS
        c = (d * d) / (x * N_COINS)
        c = (c * d) / (ann * N_COINS)

        b = x + (d / ann)

        yp = 0
        y = d

        255.times do
          yp = y
          y = ((y * y) + c) / (y + y + b - d)
          break if (y - yp).floor(0).zero?
        end

        y
      end

      def x_const(d, y)
        d = d.to_f
        y = y.to_f
        ann = a * N_COINS
        k = (d * d * d) / ann / N_COINS / N_COINS
        j = (d / ann) - d + y + y
        n = (y - j) / TWO
        Math.sqrt((k / y) + (n * n)) + n
      end

      # swap A for B
      # x, y is liquidity of A, B
      # dx is supply amount of A
      def swap(x, y, dx, d = nil)
        x *= 1e9
        y *= 1e9
        dx *= 1e9

        _d = d || d_const([x, y])
        _x = x + dx
        _y = y_const(_d, _x)
        (y - _y) / 1e9
      end

      # swap A for B
      # x, y is liquidity of A, B
      # dy is wanted amount of B
      def swap_reverse(x, y, dy, d = nil)
        x *= 1e9
        y *= 1e9
        dy *= 1e9
        _d = d || d_const([x, y])
        _y = y - dy
        _x = x_const(_d, _y)
        (_x - x) / 1e9
      end

      def price_impact(dx, dy)
        [(1 - (dy / dx)), 0].max
      end
    end
  end
end
# rubocop:enable Naming/MethodParameterName
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
