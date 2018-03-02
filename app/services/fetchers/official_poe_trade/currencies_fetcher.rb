module OfficialPoeTrade
  class CurrenciesFetcher
    # Constants
    CURRENCIES_JSON_BASE_URL = 'https://www.pathofexile.com'.freeze
    CURRENCIES_JSON_URI = '/api/trade/data/static'.freeze

    def initialize
      @faraday = Faraday.new(url: CURRENCIES_JSON_BASE_URL)
    end

    def fetch
      response = @faraday.get do |req|
        req.url CURRENCIES_JSON_URI
      end

      JSON.parse(response.body)['result']['currency']
    end
  end
end
