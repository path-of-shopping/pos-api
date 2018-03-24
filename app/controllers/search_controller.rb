class SearchController < ApplicationController
  # Constants
  ITEMS_PER_QUERY = 10.freeze
  MAINTENANCE_STATUS = 503.freeze
  SUCCESS_STATUS = 200.freeze

  # Filters
  before_action :load_search, only: %i(reload items)
  before_action :initialize_poe_trade_api

  def create
    query = params[:query]

    response = @poe_trade.query(query)
    return render json: nil, status: MAINTENANCE_STATUS if response == false

    itemIds, total = response
    @search = Search.new(key: SecureRandom.uuid, query_json: query.to_json, saw_at: Time.zone.now)
    @search.save

    render json: {
      key: @search.key,
      itemIds: itemIds,
      query: @search.query_json,
      summary: {
        total: total
      }
    }, status: SUCCESS_STATUS
  end

  def reload
    response = @poe_trade.query(@search.query)
    return render json: nil, status: MAINTENANCE_STATUS if response == false

    @search.saw_at = Time.zone.now
    @search.save

    itemIds, total = response
    render json: {
        key: @search.key,
        itemIds: itemIds,
        query: @search.query_json,
        summary: {
            total: total
        }
    }, status: SUCCESS_STATUS
  end

  def items
    response = @poe_trade.fetch_items(params[:item_ids],@search.query)
    return render json: nil, status: MAINTENANCE_STATUS if response == false

    render json: {items: response}, status: SUCCESS_STATUS
  end

private

  def load_search
    @search = Search.from_key(params[:key]).first

    render json: {error: 'Search object not found.'}, status: 404 unless @search.present?
  end

  def initialize_poe_trade_api
    @poe_trade = OfficialPoeTrade::TradeApi.new(request.remote_ip)
  end
end
