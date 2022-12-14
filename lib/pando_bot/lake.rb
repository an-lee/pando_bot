# frozen_string_literal: true

require_relative 'lake/api'
require_relative 'lake/curve'
require_relative 'lake/pair_routes'
require_relative 'lake/uniswap'

module PandoBot
  # API for Pando Lake/4swap
  module Lake
    def self.api
      @api = PandoBot::Lake::API.new
    end
  end
end
