class PoeTradeApi
  # Constants
  RATE_LIMIT_STATUS = 429.freeze
  POE_TRADE_BASE_URL = 'https://www.pathofexile.com'.freeze
  POE_TRADE_QUERY_URL = '/api/trade/search'.freeze
  POE_TRADE_FETCH_URL = '/api/trade/fetch'.freeze
  PSEUDO_MOD_PREFIX = 'pseudo'.freeze
  DEFAULT_QUERY_SORT = {price: 'asc'}.freeze

  def initialize(league, origin_ip)
    @league = league
    @origin_ip = origin_ip
    @faraday = Faraday.new(url: POE_TRADE_BASE_URL)
  end

  def query(query)
    response = @faraday.post do |req|
      req.url "#{POE_TRADE_QUERY_URL}/#{@league}"
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-Real-IP'] = @origin_ip if @origin_ip.present?
      req.body = {query: query, sort: DEFAULT_QUERY_SORT}.to_json
    end

    handle_response_or_retry(response) do
      query(query)
    end
  end

  def fetch_items(item_ids, query)
    response = @faraday.get do |req|
      req.url hydrated_fetch_url(item_ids, query)
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-Real-IP'] = @origin_ip if @origin_ip.present?
    end

    handle_response_or_retry(response) do
      fetch_items(item_ids, query)
    end
  end

  private

  def handle_response_or_retry(response)
    return JSON.parse(response.body) unless response.status == RATE_LIMIT_STATUS

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
    mod_ids = []
    query['stats'].each do |stat|
      stat['filters'].each do |filter|
        mod_ids << filter['id'] if filter['id'].start_with?(PSEUDO_MOD_PREFIX)
      end
    end
    mod_ids
  end
end
