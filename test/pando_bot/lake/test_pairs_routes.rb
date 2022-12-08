# frozen_string_literal: true

require "test_helper"

module PandoBot
  module Lake
    class TestPairsRoutes < Minitest::Test
      def setup
        pairs = PandoBot::Lake.api.pairs
        @routes = PandoBot::Lake::PairRoutes.new pairs
      end

      def routes
        assert_instance_of PandoBot::Lake::PairRoutes, @routes
      end

      def pre_order
        r = @routes.pre_order(
          input_asset: "4d8c508b-91c5-375b-92b0-ee702ed2dac5",
          output_asset: "c94ac88f-4671-3976-b60a-09064f1811e8",
          input_amount: 100
        )
        refute_nil r[:fill_amount]
      end
    end
  end
end
