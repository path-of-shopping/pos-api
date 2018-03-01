module OfficialPoeTrade
  class LeaguesFetcher
    # Constants
    LEAGUE_JSON_BASE_URL = 'https://www.pathofexile.com'.freeze
    LEAGUE_JSON_URI = '/api/trade/data/leagues'.freeze

    def initialize
      @faraday = Faraday.new(url: LEAGUE_JSON_BASE_URL)
    end

    def fetch
      response = @faraday.get do |req|
        req.url LEAGUE_JSON_URI
      end

      JSON.parse(response.body)['result'].map { |result| result['id'] }
    end
  end
end
