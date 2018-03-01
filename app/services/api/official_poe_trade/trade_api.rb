module OfficialPoeTrade
  class TradeApi
    # Constants
    RATE_LIMIT_STATUS = 429.freeze
    POE_TRADE_BASE_URL = 'https://www.pathofexile.com'.freeze
    POE_TRADE_QUERY_URL = '/api/trade/search'.freeze
    POE_TRADE_FETCH_URL = '/api/trade/fetch'.freeze
    PSEUDO_MOD_PREFIX = 'pseudo'.freeze
    DEFAULT_QUERY_SORT = {price: 'asc'}.freeze

    def initialize(origin_ip)
      @origin_ip = origin_ip
      @faraday = Faraday.new(url: POE_TRADE_BASE_URL)
    end

    def query(query)
      response = @faraday.post do |req|
        req.url "#{POE_TRADE_QUERY_URL}/#{query['league']}"
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Real-IP'] = @origin_ip if @origin_ip.present?
        req.body = {query: OfficialPoeTrade::QueryConverter.new(query).convert, sort: DEFAULT_QUERY_SORT}.to_json
      end

      if is_rate_limited(response)
        return retry_after_limit(response) do
          query(query)
        end
      end

      parsed_response = JSON.parse(response.body)
      return parsed_response['result'], parsed_response['total']
    end

    def fetch_items(item_ids, query)
      response = @faraday.get do |req|
        req.url hydrated_fetch_url(item_ids, query)
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Real-IP'] = @origin_ip if @origin_ip.present?
      end

      if is_rate_limited(response)
        return retry_after_limit(response) do
          fetch_items(item_ids, query)
        end
      end

      parsed_response = JSON.parse(response.body)
      return OfficialPoeTrade::ItemsExtractor.new(parsed_response['result']).extract
    end

  private

    def is_rate_limited(response)
      response.status == RATE_LIMIT_STATUS
    end

    def retry_after_limit(response)
      limit_duration = [
          response.headers['X-Rate-Limit-Ip-State'].split(':').last.to_i,
          response.headers['X-Rate-Limit-Account-State'] ? response.headers['X-Rate-Limit-Account-State'].split(':').last.to_i : 0
      ].max

      sleep(limit_duration + 1)

      yield
    end

    def hydrated_fetch_url(item_ids, query)
      item_ids = item_ids.join(',') if item_ids.is_a? Array
      base_url = "#{POE_TRADE_FETCH_URL}/#{item_ids}"

      pseudo_mod_ids = pseudo_mod_ids_from(query)

      return base_url if pseudo_mod_ids.empty?

      pseudo_mod_ids = pseudo_mod_ids.map { |pseudo| pseudo.prepend('pseudos[]=') }
      "#{base_url}?#{pseudo_mod_ids.join('&')}"
    end

    def pseudo_mod_ids_from(query)
      # TODO: Adapt to the custom format
      return [] unless query['stats'].present?
      mod_ids = []
      query['stats'].each do |stat|
        stat['filters'].each do |filter|
          mod_ids << filter['id'] if filter['id'].start_with?(PSEUDO_MOD_PREFIX)
        end
      end
      mod_ids
    end
  end
end
