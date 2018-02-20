class SearchController < ApplicationController
  # Constants
  ITEMS_PER_QUERY = 10.freeze
  DEFAULT_LEAGUE = 'Standard'.freeze

  # Filters
  before_action :load_search, only: %i(reload items)
  before_action :initialize_poe_trade_api

  def create
    query = params[:query]

    query_response = @poe_trade.query(query)
    initialize_search_object(query_response['id'], query)

    item_ids = query_response['result']
    fetch_response = @poe_trade.fetch_items(item_ids.first(ITEMS_PER_QUERY), query)

    render json: {
      key: @search.key,
      next_item_ids: item_ids.drop(ITEMS_PER_QUERY),
      total: query_response['total'],
      items: fetch_response['result']
    }, status: 200
  end

  def reload
    @search.saw_at = Time.zone.now
    @search.save

    query_response = @poe_trade.query(@search.query)

    item_ids = query_response['result']
    fetch_response = @poe_trade.fetch_items(item_ids.first(ITEMS_PER_QUERY), @search.query)

    render json: {
      key: @search.key,
      next_item_ids: item_ids.drop(ITEMS_PER_QUERY),
      total: query_response['total'],
      items: fetch_response['result']
    }, status: 200
  end

  def items
    fetch_response = @poe_trade.fetch_items(params[:item_ids], @search.query)

    render json: {items: fetch_response['result']}, status: 200
  end

  private

  def league
    return params[:league] if params[:league].present?
    return @search.league if @search.league.present?
    DEFAULT_LEAGUE
  end

  def load_search
    @search = Search.from_key(params[:key]).first

    render json: {error: 'Search object not found.'}, status: 404 unless @search.present?
  end

  def initialize_poe_trade_api
    @poe_trade = PoeTradeApi.new(league, request.remote_ip)
  end

  def initialize_search_object(poe_id, query)
    @search = Search.from_poe_id(poe_id).first

    if (@search.present?)
      @search.saw_at = Time.zone.now
    else
      @search = Search.new(
          key: SecureRandom.uuid,
          poe_id: poe_id,
          query_json: query.to_json,
          league: league,
          saw_at: Time.zone.now
      )
    end

    @search.save
  end
end
