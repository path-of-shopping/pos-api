module OfficialPoeTrade
  class ItemsFetcher
    # Constants
    ITEMS_JSON_BASE_URL = 'https://www.pathofexile.com'.freeze
    ITEMS_JSON_URI = '/api/trade/data/items'.freeze
    UNIQUE_FLAG = 'unique'.freeze

    def initialize
      @faraday = Faraday.new(url: ITEMS_JSON_BASE_URL)
    end

    def fetch
      response = @faraday.get do |req|
        req.url ITEMS_JSON_URI
      end

      raw_items = JSON.parse(response.body)['result'].map { |result| result['entries'] }
      raw_items.flatten!

      raw_items.map! { |item| { name: item['name'], base: item['type'], isUnique: item['flags'].present? ? item['flags'].keys.include?(UNIQUE_FLAG) : false } }

      raw_items.sort_by { |item| item[:name] || "_#{item[:base]}" }
    end
  end
end
