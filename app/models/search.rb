class Search < ApplicationRecord
  # Scopes
  scope :from_poe_id, -> (poe_id) { where(poe_id: poe_id) }
  scope :from_key, -> (key) { where(key: key) }

  # Computed
  def query
    JSON.parse(query_json)
  end
end
