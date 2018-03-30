module OfficialPoeTrade
  class QueryFetcher < BaseTradeApiFetcher
    # Constants
    POE_TRADE_QUERY_URL = '/api/trade/search'.freeze
    DEFAULT_QUERY_SORT = {price: 'asc'}.freeze

    def fetch(query)
      @response = @faraday.post do |req|
        req.url "#{POE_TRADE_QUERY_URL}/#{query['league']}"
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Real-IP'] = @origin_ip if @origin_ip.present?

        converted_query = OfficialPoeTrade::QueryConverter.new(query).convert
        log_queries(query, converted_query)

        req.body = {query: converted_query, sort: DEFAULT_QUERY_SORT}.to_json
      end

      maintenance_check!

      if is_rate_limited?
        return retry_after_limit do
          query(query)
        end
      end

      parsed_response = JSON.parse(@response.body)
      return parsed_response['result'], parsed_response['total']
    end

  private

    def log_queries(original_query, converted_query)
      return nil unless Rails.env.development?

      Rails.logger.info 'Processing query...  (original / converted)'
      Rails.logger.info original_query.to_json
      Rails.logger.info converted_query.to_json
    end
  end
end
