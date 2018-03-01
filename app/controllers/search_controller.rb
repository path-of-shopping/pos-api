class SearchController < ApplicationController
  # Constants
  ITEMS_PER_QUERY = 10.freeze

  # Filters
  before_action :load_search, only: %i(reload items)
  before_action :initialize_poe_trade_api

  def create
    query = params[:query]

    itemIds, total = @poe_trade.query(query)

    @search = Search.new(key: SecureRandom.uuid, query_json: query.to_json, saw_at: Time.zone.now)
    @search.save

    render json: {
      key: @search.key,
      itemIds: itemIds,
      query: @search.query_json,
      summary: {
        total: total
      }
    }, status: 200
  end

  def reload
    @search.saw_at = Time.zone.now
    @search.save

    itemIds, total = @poe_trade.query(@search.query)

    render json: {
        key: @search.key,
        itemIds: itemIds,
        query: @search.query_json,
        summary: {
            total: total
        }
    }, status: 200
  end

  def items
    render json: {items: @poe_trade.fetch_items(params[:item_ids], @search.query)}, status: 200
  end

private

  def load_search
    @search = Search.from_key(params[:key]).first

    render json: {error: 'Search object not found.'}, status: 404 unless @search.present?
  end

  def initialize_poe_trade_api
    @poe_trade = OfficialPoeTrade.TradeApi.new(request.remote_ip)
  end
end
