class SearchController < ApplicationController
  def create
    query_response = Api::PoeTrade.query(params[:query], params[:league])

    # DB save the query

    # Fetch results

    # Craft response

    render json: res.body, status: res.status
  end

  def reload
    # params[:search_id]

    # Load de la DB

    # query PoeTrade

    # Idem que le create
  end

  def fetch_items
    # params[:item_ids]

    # Craft response

  end
end
