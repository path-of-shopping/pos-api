module OfficialPoeTrade
  class ItemsFetcher < BaseTradeApiFetcher
    # Constants
    POE_TRADE_ITEMS_URL = '/api/trade/fetch'.freeze
    PSEUDO_MOD_PREFIX = 'pseudo'.freeze
    DEFAULT_QUERY_SORT = {price: 'asc'}.freeze

    def fetch(item_ids, query)
      @response = @faraday.get do |req|
        req.url hydrated_fetch_url(item_ids, query)
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Real-IP'] = @origin_ip if @origin_ip.present?
      end

      maintenance_check!

      if is_rate_limited?
        return retry_after_limit do
          fetch_items(item_ids, query)
        end
      end

      parsed_response = JSON.parse(@response.body)
      return OfficialPoeTrade::ItemsExtractor.new(parsed_response['result']).extract
    end

  private

    def hydrated_fetch_url(item_ids, query)
      item_ids = item_ids.join(',') if item_ids.is_a? Array
      base_url = "#{POE_TRADE_ITEMS_URL}/#{item_ids}"

      pseudo_mod_ids = pseudo_mod_ids_from(query)

      return base_url if pseudo_mod_ids.empty?

      pseudo_mod_ids = pseudo_mod_ids.map { |pseudo| pseudo.prepend('pseudos[]=') }
      "#{base_url}?#{pseudo_mod_ids.join('&')}"
    end

    def pseudo_mod_ids_from(query)
      return [] unless query['mod'].present?
      mod_ids = []
      query['mod'].each do |mod_block|
        mod_block['mods'].each do |mod_item|
          mod_ids << mod_item['mod'] if mod_item['mod'].start_with?(PSEUDO_MOD_PREFIX)
        end
      end
      mod_ids
    end
  end
end
