module OfficialPoeTrade
  class ModsFetcher
    # Constants
    MODS_JSON_BASE_URL = 'https://www.pathofexile.com'.freeze
    MODS_JSON_URI = '/api/trade/data/stats'.freeze

    def initialize
      @faraday = Faraday.new(url: MODS_JSON_BASE_URL)
    end

    def fetch
      response = @faraday.get do |req|
        req.url MODS_JSON_URI
      end

      raw_mods = JSON.parse(response.body)['result'].map { |result| result['entries'] }
      raw_mods.flatten!

      raw_mods.map { |mod| { id: mod['id'], value: mod['text'], type: mod['type'] } }
    end
  end
end
