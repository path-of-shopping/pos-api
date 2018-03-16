module OfficialPoeTrade
  class ModsFetcher
    # Constants
    MODS_JSON_BASE_URL = 'https://www.pathofexile.com'.freeze
    MODS_JSON_URI = '/api/trade/data/stats'.freeze
    MODS_TYPE_ORDER = %w(pseudo explicit implicit crafted enchant monster)

    def initialize
      @faraday = Faraday.new(url: MODS_JSON_BASE_URL)
    end

    def fetch
      response = @faraday.get do |req|
        req.url MODS_JSON_URI
      end

      raw_mods = JSON.parse(response.body)['result'].map { |result| result['entries'] }
      raw_mods.flatten!

      raw_mods.map! { |mod| { id: mod['id'], name: mod['text'], type: mod['type'] } }

      raw_mods.sort_by { |mod| "#{MODS_TYPE_ORDER.index(mod[:type])}#{mod[:id]}" }
    end

  private

    def compare_mods(mod_a, mod_b)
      type_comparison = MODS_TYPE_ORDER.index(mod_a[:type]) <=> MODS_TYPE_ORDER.index(mod_b[:type])

      return type_comparison unless type_comparison == 0

      mod_a[:id] <=> mod_b[:id]
    end
  end
end
