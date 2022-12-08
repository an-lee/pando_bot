# frozen_string_literal: true

module PandoBot
  module Lake
    class PairRoutes
      PRECISION = 8
      HASH_SALT = "uniswap routes"

      attr_reader :pairs, :uniswap, :curve, :routes

      def initialize(pairs)
        @uniswap = PandoBot::Lake::Uniswap.new
        @curve = PandoBot::Lake::Curve.new
        @routes = {}.with_indifferent_access
        @pairs =
          pairs.map do |pair|
            pair = pair.with_indifferent_access

            base_amount = pair[:base_amount].to_f
            quote_amount = pair[:quote_amount].to_f
            fill_percent = 1 - pair[:fee_percent].to_f

            d = 0
            d = @curve.d_const([base_amount * 1e9, quote_amount * 1e9]) if pair[:swap_method] == "curve"

            pair.merge(
              base_amount: base_amount,
              quote_amount: quote_amount,
              fill_percent: fill_percent,
              K: (base_amount * quote_amount),
              D: d
            )
          end
        @pairs.each do |pair|
          set_asset_route pair[:base_asset_id], pair
          set_asset_route pair[:quote_asset_id], pair
        end
        @pairs.freeze
      end

      def pre_order(input_asset:, output_asset:, input_amount: nil, output_amount: nil)
        funds = input_amount.to_f.ceil(PRECISION)
        amount = output_amount.to_f.floor(PRECISION)

        if input_amount.present?
          raise PandoBot::Lake::SwapError, "input amount invalid" if input_amount.negative?

          best = best_route input_asset, output_asset, input_amount
          amount = best[:amount]
        elsif output_amount.present?
          raise PandoBot::Lake::SwapError, "output amount invalid" if output_amount.negative?

          best = best_route_reverse input_asset, output_asset, output_amount
          funds = best[:funds]
        else
          raise PandoBot::Lake::SwapError, "input or output are needed"
        end

        raise PandoBot::Lake::SwapError, "no pair route found" if best.blank?

        raise PandoBot::Lake::SwapError, "swap amount not support" if amount.blank? || funds.blank?

        best
          .merge(
            {
              amount: format("%.#{PRECISION}f", amount),
              funds: format("%.#{PRECISION}f", funds),
              route_assets: best[:route_assets],
              price_impact: best[:price_impact],
              routes: Hashids.new(HASH_SALT).encode(best[:route_ids]),
              pay_asset_id: input_asset,
              fill_asset_id: output_asset,
              pay_amount: format("%.#{PRECISION}f", funds),
              fill_amount: format("%.#{PRECISION}f", amount),
              state: "Done"
            }
          )
      end

      private

      def set_asset_route(asset, pair)
        routes = @routes[asset].dup || []
        opposit = opposit_asset(pair, asset)

        return if opposit.in?(routes)

        @routes[asset] = routes.push(opposit)
      end

      def find_pair(base, quote)
        @pairs.find(&lambda { |p|
          p1 = p[:base_asset_id] == base && p[:quote_asset_id] == quote
          p2 = p[:base_asset_id] == quote && p[:quote_asset_id] == base
          p1 || p2
        })
      end

      def find_pair_by_route_id(id)
        @pairs.find(&->(p) { p[:route_id] == id })
      end

      def opposit_asset(pair, input)
        input == pair[:base_asset_id] ? pair[:quote_asset_id] : pair[:base_asset_id]
      end

      def best_route(input_asset, output_asset, input_amount)
        deep = 4
        best = {}
        queue = [
          {
            key: input_asset,
            ctx: {
              route_assets: [input_asset],
              route_ids: [],
              amount: 0,
              funds: 0,
              price_impact: 0
            }
          }
        ]

        while queue.size.positive?
          current = queue.pop
          step_input_amount = current[:ctx][:amount].zero? ? input_amount : current[:ctx][:amount]
          neibors = @routes[current[:key]] || []

          neibors.each do |neibor|
            next if current[:ctx][:route_ids].size == deep - 1 && neibor != output_asset

            pair = find_pair current[:key], neibor
            next if pair.blank?
            next if pair[:route_id].in?(current[:ctx][:route_ids])

            transaction = swap pair, current[:key], step_input_amount
            next if transaction.blank?

            new_ctx = {
              route_assets: (current[:ctx][:route_assets] + [neibor]),
              route_ids: (current[:ctx][:route_ids] + [pair[:route_id]]),
              amount: transaction[:amount],
              funds: transaction[:funds],
              price_impact: (((1 + current[:ctx][:price_impact]) * (1 + transaction[:price_impact])) - 1)
            }

            if neibor == output_asset
              best = new_ctx if best.blank? || best[:amount].to_f < new_ctx[:amount]
              next
            end

            queue.push({ key: neibor, ctx: new_ctx }) if new_ctx[:route_assets].size < deep
          end
        end

        best
      end

      def best_route_reverse(input_asset, output_asset, output_amount)
        deep = 4
        best = nil
        queue = [
          {
            key: output_asset,
            ctx: {
              route_assets: [output_asset],
              route_ids: [],
              amount: 0,
              funds: 0,
              price_impact: 0
            }
          }
        ]

        while queue.size.positive?
          current = queue.pop
          step_input_amount = current[:ctx][:funds].zero? ? output_amount : current[:ctx][:funds]
          neibors = @routes[current[:key]] || []

          neibors.each do |neibor|
            next if current[:ctx][:route_ids].size == deep - 1 && neibor != input_asset

            pair = find_pair current[:key], neibor
            next if pair.blank?
            next if pair[:route_id].in?(current[:ctx][:route_ids])

            transaction = swap_reverse pair, neibor, step_input_amount
            next if transaction.blank?

            new_ctx = {
              route_assets: ([neibor] + current[:ctx][:route_assets]),
              route_ids: ([pair[:route_id]] + current[:ctx][:route_ids]),
              amount: transaction[:amount],
              funds: transaction[:funds],
              price_impact: (((1 + current[:ctx][:price_impact]) * (1 + transaction[:price_impact])) - 1)
            }

            if neibor == input_asset
              best = new_ctx if best.blank? || best[:funds] > new_ctx[:funds]
              next
            end

            if new_ctx[:route_assets].size < deep || (new_ctx[:route_assets].size == deep && neibor == input_asset)
              queue.push({ key: neibor,
                           ctx: new_ctx })
            end
          end
        end

        best
      end

      def swap(pair, input_asset, input_amount)
        dy = 0
        price_impact = 0
        dx = input_amount.to_f * pair[:fill_percent]

        x = pair[:base_amount]
        y = pair[:quote_amount]

        x, y = y, x if input_asset != pair[:base_asset_id]

        if pair[:swap_method] == "curve"
          dy = @curve.swap(x, y, dx)
          dy = dy.to_f.floor(PRECISION)
          price_impact = curve.price_impact(input_amount, dy)
        else
          dy = @uniswap.swap(x, y, dx)
          dy = dy.to_f.floor(PRECISION)
          price_impact = uniswap.price_impact(x, y, input_amount, dy)
        end

        return if dy <= 0

        {
          funds: input_amount.to_f.round(PRECISION),
          amount: dy,
          price_impact: price_impact
        }
      end

      def swap_reverse(pair, input_asset, output_amount)
        dx = 0
        price_impact = 0

        dy = output_amount

        x = pair[:base_amount]
        y = pair[:quote_amount]

        x, y = y, x if input_asset != pair[:base_asset_id]

        return if dy > y

        if pair[:swap_method] == "curve"
          dx = @curve.swap_reverse(x, y, dy)
          dx = (dx / pair[:fill_percent]).to_f.ceil(PRECISION)
          price_impact = curve.price_impact(dx, output_amount)
        else
          dx = @uniswap.swap_reverse(x, y, dy)
          dx = (dx / pair[:fill_percent]).to_f.ceil(PRECISION)
          dx = dx.to_f.ceil(PRECISION)
          price_impact = uniswap.price_impact(x, y, dx, output_amount)
        end

        return if dx <= 0

        {
          funds: dx,
          amount: output_amount,
          price_impact: price_impact
        }
      end
    end
  end
end
