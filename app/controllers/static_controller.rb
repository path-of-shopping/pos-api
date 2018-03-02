class StaticController < ApplicationController
  def index
    render json: {
      currencies: STATIC_CURRENCIES,
      items: STATIC_ITEMS,
      leagues: STATIC_LEAGUES,
      mods: STATIC_MODS
    }
  end
end
