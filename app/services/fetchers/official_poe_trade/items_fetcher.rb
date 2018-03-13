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

      items = JSON.parse(response.body)['result'].map { |result| result['entries'] }
      items.flatten!

      items.map! { |item| {
          id: generate_id_for(item['name'], item['type']),
          name: item['name'],
          base: item['type'],
          isUnique: item['flags'].present? ? item['flags'].keys.include?(UNIQUE_FLAG) : false
      }}

      items.uniq! { |item| item[:id] }
      
      items.sort_by { |item| "#{item[:base]}_#{item[:name]}" }
    end

  private

    def generate_id_for(name, base)
      parts = []
      parts << name if name
      parts << base if base

      parts.join('-').downcase.gsub(' ', '-').gsub(/[^a-z\-]/, '')
    end
  end
end
