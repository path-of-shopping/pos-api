module OfficialPoeTrade
  class BaseTradeApiFetcher
    # Constants
    RATE_LIMIT_STATUS = 429.freeze
    MAINTENANCE_STATUS = 405.freeze
    POE_TRADE_BASE_URL = 'https://www.pathofexile.com'.freeze

    def initialize(origin_ip)
      @response = nil
      @origin_ip = origin_ip
      @faraday = Faraday.new(url: POE_TRADE_BASE_URL)
    end

  protected

    def maintenance_check!
      raise MaintenanceException if @response.status == MAINTENANCE_STATUS
    end

    def is_rate_limited?
      @response.status == RATE_LIMIT_STATUS
    end

    def retry_after_limit
      limit_duration = [
        @response.headers['X-Rate-Limit-Ip-State'].split(':').last.to_i,
        @response.headers['X-Rate-Limit-Account-State'] ? @response.headers['X-Rate-Limit-Account-State'].split(':').last.to_i : 0
      ].max

      sleep(limit_duration + 1)

      yield
    end
  end
end
