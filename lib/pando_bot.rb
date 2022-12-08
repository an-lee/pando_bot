# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "hashids"
require_relative "pando_bot/version"
require_relative "pando_bot/lake"

module PandoBot
  class Error < StandardError; end

  module Lake
    class Error < Error; end
  end

  module Lake
    class SwapError < Lake::Error; end
  end
end
