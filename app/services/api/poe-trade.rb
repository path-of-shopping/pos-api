module Api
  module PoeTrade
    # Constants
    POE_TRADE_BASE_URL = 'https://www.pathofexile.com'.freeze
    POE_TRADE_SEARCH_URL = '/api/trade/search'.freeze

    class << self
      def query(query, league)
        Faraday.new(POE_TRADE_BASE_URL).post do |req|
          req.url "#{POE_TRADE_SEARCH_URL}/#{league}"
          req.headers['Content-Type'] = 'application/json'
          req.headers['X-Real-IP'] = request.remote_ip if request.remote_ip.present?
          req.body = {query: query}.to_json
        end
      end
    end
  end
end
