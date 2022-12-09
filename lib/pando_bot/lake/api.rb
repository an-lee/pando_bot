# frozen_string_literal: true

module PandoBot
  # for Pando Lake/4swap
  module Lake
    attr_reader :client

    # HTTP API
    class API
      def initialize(endpoint = 'https://api.4swap.org')
        @client = Faraday.new(url: endpoint) do |f|
          f.request :json
          f.request :retry
          f.response :raise_error
          f.response :logger
          f.response :json
        end
      end

      def pre_order(**params)
        path = '/api/orders/pre'

        payload = {
          pay_asset_id: params[:pay_asset_id],
          fill_asset_id: params[:fill_asset_id],
          funds: params[:funds]&.to_s,
          amount: params[:amount]&.round(8)&.to_s
        }.compact

        r = @client.post path, payload.to_json
        r.body
      end

      def order(order_id, authorization:)
        path = "/api/orders/#{order_id}"
        r = @client.get path, nil, { Authorization: authorization }
        r.body
      end

      def pairs
        path = '/api/pairs'
        @client.get(path).body
      end

      def actions(**options)
        path = '/api/actions'
        payload = {
          action: [3, options[:user_id], options[:follow_id], options[:asset_id], options[:route_id],
                   options[:minimum_fill]].join(',')
        }
        @client.post(path, payload.to_json).body
      end

      def tradable_asset_ids
        _pairs = pairs['data']['pairs']
        _ids = []
        _pairs.each do |pair|
          _ids.push(pair['base_asset_id'])
          _ids.push(pair['quote_asset_id'])
        end
        _ids.uniq!
      end
    end
  end
end
