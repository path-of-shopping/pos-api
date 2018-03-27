class SearchController < ApplicationController
  # Constants
  ITEMS_PER_QUERY = 10.freeze
  MAINTENANCE_STATUS = 503.freeze
  SUCCESS_STATUS = 200.freeze

  # Filters
  before_action :load_search, only: %i(reload items)

  def create
    query = params[:query]

    begin
      itemIds, total =  OfficialPoeTrade::QueryFetcher.new(request.remote_ip).fetch(query)
    rescue OfficialPoeTrade::MaintenanceException
      return render_maintenance
    end

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
    begin
      itemIds, total = OfficialPoeTrade::QueryFetcher.new(request.remote_ip).fetch(@search.query)
    rescue OfficialPoeTrade::MaintenanceException
      return render_maintenance
    end

    @search.saw_at = Time.zone.now
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

  def items
    begin
      items = OfficialPoeTrade::ItemsFetcher.new(request.remote_ip).fetch(params[:item_ids], @search.query)
    rescue OfficialPoeTrade::MaintenanceException
      return render_maintenance
    end

    render json: {items: items}, status: SUCCESS_STATUS
  end

private

  def load_search
    @search = Search.from_key(params[:key]).first

    render json: {error: 'Search object not found.'}, status: 404 unless @search.present?
  end

  def render_maintenance
    render json: nil, status: MAINTENANCE_STATUS
  end
end
