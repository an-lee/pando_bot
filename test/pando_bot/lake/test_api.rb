# frozen_string_literal: true

require 'test_helper'
require 'securerandom'

module PandoBot
  module Lake
    class TestAPI < Minitest::Test
      def setup
        @api = PandoBot::Lake::API.new
      end

      def test_pairs
        r = @api.pairs
        refute_nil r
      end

      def test_pre_order
        r = @api.pre_order(
          pay_asset_id: '4d8c508b-91c5-375b-92b0-ee702ed2dac5',
          fill_asset_id: 'c94ac88f-4671-3976-b60a-09064f1811e8',
          funds: 100
        )
        refute_nil r
      end

      def test_order
        assert_raises(Faraday::UnauthorizedError) do
          @api.order SecureRandom.uuid, authorization: ''
        end
      end

      def test_actions
        r = @api.actions(
          user_id: '28d390c7-a31b-4c46-bec2-871c86aaec53',
          follow_id: SecureRandom.uuid,
          asset_id: 'c94ac88f-4671-3976-b60a-09064f1811e8',
          minimum_fill: 1
        )
        refute_nil r
      end

      def test_tradable_asset_ids
        r = @api.tradable_asset_ids
        refute_nil r
      end
    end
  end
end
