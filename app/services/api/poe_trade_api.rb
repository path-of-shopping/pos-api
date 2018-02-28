class PoeTradeApi
  # Constants
  RATE_LIMIT_STATUS = 429.freeze
  POE_TRADE_BASE_URL = 'https://www.pathofexile.com'.freeze
  POE_TRADE_QUERY_URL = '/api/trade/search'.freeze
  POE_TRADE_FETCH_URL = '/api/trade/fetch'.freeze
  PSEUDO_MOD_PREFIX = 'pseudo'.freeze
  DEFAULT_QUERY_SORT = {price: 'asc'}.freeze

  def initialize(origin_ip)
    @origin_ip = origin_ip
    @faraday = Faraday.new(url: POE_TRADE_BASE_URL)
  end

  def query(query)
    puts query
    puts convert_query(query)
    response = @faraday.post do |req|
      req.url "#{POE_TRADE_QUERY_URL}/#{query['league']}"
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-Real-IP'] = @origin_ip if @origin_ip.present?
      req.body = {query: convert_query(query), sort: DEFAULT_QUERY_SORT}.to_json
    end

    handle_response_or_retry(response) do
      query(query)
    end
  end

  def fetch_items(item_ids, query)
    response = @faraday.get do |req|
      req.url hydrated_fetch_url(item_ids, query)
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-Real-IP'] = @origin_ip if @origin_ip.present?
    end

    handle_response_or_retry(response) do
      fetch_items(item_ids, query)
    end
  end

  private

  def handle_response_or_retry(response)
    return JSON.parse(response.body) unless response.status == RATE_LIMIT_STATUS

    limit_duration = [
      response.headers['X-Rate-Limit-Ip-State'].split(':').last.to_i,
      response.headers['X-Rate-Limit-Account-State'] ? response.headers['X-Rate-Limit-Account-State'].split(':').last.to_i : 0
    ].max

    sleep(limit_duration + 1)

    yield
  end

  def hydrated_fetch_url(item_ids, query)
    item_ids = item_ids.join(',') if item_ids.is_a? Array
    base_url = "#{POE_TRADE_FETCH_URL}/#{item_ids}"

    pseudo_mod_ids = pseudo_mod_ids_from(query)

    return base_url if pseudo_mod_ids.empty?

    pseudo_mod_ids = pseudo_mod_ids.map { |pseudo| pseudo.prepend('pseudos[]=') }
    "#{base_url}?#{pseudo_mod_ids.join('&')}"
  end

  def pseudo_mod_ids_from(query)
    # TODO: Adapt to the custom format
    return [] unless query['stats'].present?
    mod_ids = []
    query['stats'].each do |stat|
      stat['filters'].each do |filter|
        mod_ids << filter['id'] if filter['id'].start_with?(PSEUDO_MOD_PREFIX)
      end
    end
    mod_ids
  end

  def convert_query(query)
    poe_query = {}

    poe_query['name'] = query['name']['name'] if query['name'].present? && query['name']['name'].present?
    poe_query['type'] = query['name']['type'] if query['name'].present? && query['name']['type'].present?

    poe_query['status'] = {option: query['trade']['status']} if query['trade']['status'].present?

    poe_query['filters'] = {}

    if query['type'].present?
      poe_query['filters']['type_filters'] = {}
      poe_query['filters']['type_filters']['filters'] = {}
      poe_query['filters']['type_filters']['filters']['category'] = {option: query['type']['category']} if query['type']['category'].present?
      poe_query['filters']['type_filters']['filters']['rarity'] = {option: query['type']['rarity']} if query['type']['rarity'].present?
    end
    
    if query['weapon'].present?
      poe_query['filters']['weapon_filters'] = {}
      poe_query['filters']['weapon_filters']['filters'] = {}
      poe_query['filters']['weapon_filters']['filters']['damage'] = convert_min_max(query['weapon']['damage']) if query['weapon']['damage'].present?
      poe_query['filters']['weapon_filters']['filters']['crit'] = convert_min_max(query['weapon']['critical']) if query['weapon']['critical'].present?
      poe_query['filters']['weapon_filters']['filters']['pdps'] = convert_min_max(query['weapon']['pdps']) if query['weapon']['pdps'].present?
      poe_query['filters']['weapon_filters']['filters']['aps'] = convert_min_max(query['weapon']['aps']) if query['weapon']['aps'].present?
      poe_query['filters']['weapon_filters']['filters']['dps'] = convert_min_max(query['weapon']['dps']) if query['weapon']['dps'].present?
      poe_query['filters']['weapon_filters']['filters']['edps'] = convert_min_max(query['weapon']['edps']) if query['weapon']['edps'].present?
    end

    if query['armour'].present?
      poe_query['filters']['armour_filters'] = {}
      poe_query['filters']['armour_filters']['filters'] = {}
      poe_query['filters']['armour_filters']['filters']['ar'] = convert_min_max(query['armour']['armour']) if query['armour']['armour'].present?
      poe_query['filters']['armour_filters']['filters']['es'] = convert_min_max(query['armour']['energy']) if query['armour']['energy'].present?
      poe_query['filters']['armour_filters']['filters']['ev'] = convert_min_max(query['armour']['evasion']) if query['armour']['evasion'].present?
      poe_query['filters']['armour_filters']['filters']['block'] = convert_min_max(query['armour']['block']) if query['armour']['block'].present?
    end

    if query['socket'].present? && query['socket']['sockets'].present?
      poe_query['filters']['socket_filters'] = {}
      poe_query['filters']['socket_filters']['filters'] = {}
      poe_query['filters']['socket_filters']['filters']['sockets'] = {}
      poe_query['filters']['socket_filters']['filters']['sockets']['r'] = query['socket']['sockets']['red'].to_i if query['socket']['sockets']['red'].present?
      poe_query['filters']['socket_filters']['filters']['sockets']['g'] = query['socket']['sockets']['green'].to_i if query['socket']['sockets']['green'].present?
      poe_query['filters']['socket_filters']['filters']['sockets']['b'] = query['socket']['sockets']['blue'].to_i if query['socket']['sockets']['blue'].present?
      poe_query['filters']['socket_filters']['filters']['sockets']['min'] = query['socket']['sockets']['min'].to_i if query['socket']['sockets']['min'].present?
      poe_query['filters']['socket_filters']['filters']['sockets']['max'] = query['socket']['sockets']['max'].to_i if query['socket']['sockets']['max'].present?
    end

    if query['socket'].present? && query['socket']['links'].present?
      poe_query['filters']['socket_filters']['filters']['links'] = {}
      poe_query['filters']['socket_filters']['filters']['links']['r'] = query['socket']['links']['red'].to_i if query['socket']['links']['red'].present?
      poe_query['filters']['socket_filters']['filters']['links']['g'] = query['socket']['links']['green'].to_i if query['socket']['links']['green'].present?
      poe_query['filters']['socket_filters']['filters']['links']['b'] = query['socket']['links']['blue'].to_i if query['socket']['links']['blue'].present?
      poe_query['filters']['socket_filters']['filters']['links']['min'] = query['socket']['links']['min'].to_i if query['socket']['links']['min'].present?
      poe_query['filters']['socket_filters']['filters']['links']['max'] = query['socket']['links']['max'].to_i if query['socket']['links']['max'].present?
    end

    if query['requirement'].present?
      poe_query['filters']['req_filters'] = {}
      poe_query['filters']['req_filters']['filters'] = {}
      poe_query['filters']['req_filters']['filters']['lvl'] = convert_min_max(query['requirement']['level']) if query['requirement']['level'].present?
      poe_query['filters']['req_filters']['filters']['str'] = convert_min_max(query['requirement']['strength']) if query['requirement']['strength'].present?
      poe_query['filters']['req_filters']['filters']['dex'] = convert_min_max(query['requirement']['dexterity']) if query['requirement']['dexterity'].present?
      poe_query['filters']['req_filters']['filters']['int'] = convert_min_max(query['requirement']['intelligence']) if query['requirement']['intelligence'].present?
    end
    
    if query['map'].present?
      poe_query['filters']['map_filters'] = {}
      poe_query['filters']['map_filters']['filters'] = {}
      poe_query['filters']['map_filters']['filters']['map_tier'] = convert_min_max(query['map']['tier']) if query['map']['tier'].present?
      poe_query['filters']['map_filters']['filters']['map_packsize'] = convert_min_max(query['map']['packSize']) if query['map']['packSize'].present?
      poe_query['filters']['map_filters']['filters']['map_iiq'] = convert_min_max(query['map']['iiq']) if query['map']['iiq'].present?
      poe_query['filters']['map_filters']['filters']['map_iir'] = convert_min_max(query['map']['iir']) if query['map']['iir'].present?
      poe_query['filters']['map_filters']['filters']['map_series'] = {option: query['map']['series']} if query['map']['series'].present?
      poe_query['filters']['map_filters']['filters']['map_shaped'] = {option: query['map']['shaped'] == '1' ? 'true' : 'false'} if query['map']['shaped'].present?
    end
    
    if query['miscellaneous'].present?
      poe_query['filters']['misc_filters'] = {}
      poe_query['filters']['misc_filters']['filters'] = {}
      poe_query['filters']['misc_filters']['filters']['quality'] = convert_min_max(query['miscellaneous']['quality']) if query['miscellaneous']['quality'].present?
      poe_query['filters']['misc_filters']['filters']['ilvl'] = convert_min_max(query['miscellaneous']['itemLevel']) if query['miscellaneous']['itemLevel'].present?
      poe_query['filters']['misc_filters']['filters']['gem_level'] = convert_min_max(query['miscellaneous']['gemLevel']) if query['miscellaneous']['gemLevel'].present?
      poe_query['filters']['misc_filters']['filters']['talisman_tier'] = convert_min_max(query['miscellaneous']['talismanTier']) if query['miscellaneous']['talismanTier'].present?
      poe_query['filters']['misc_filters']['filters']['shaper_item'] = {option: query['miscellaneous']['shaperItem'] == '1' ? 'true' : 'false'} if query['miscellaneous']['shaperItem'].present?
      poe_query['filters']['misc_filters']['filters']['elder_item'] = {option: query['miscellaneous']['elderItem'] == '1' ? 'true' : 'false'} if query['miscellaneous']['elderItem'].present?
      poe_query['filters']['misc_filters']['filters']['alternate_item'] = {option: query['miscellaneous']['alternateArt'] == '1' ? 'true' : 'false'} if query['miscellaneous']['alternateArt'].present?
      poe_query['filters']['misc_filters']['filters']['corrupted'] = {option: query['miscellaneous']['corrupted'] == '1' ? 'true' : 'false'} if query['miscellaneous']['corrupted'].present?
      poe_query['filters']['misc_filters']['filters']['enchanted'] = {option: query['miscellaneous']['enchanted'] == '1' ? 'true' : 'false'} if query['miscellaneous']['enchanted'].present?
      poe_query['filters']['misc_filters']['filters']['identified'] = {option: query['miscellaneous']['identified'] == '1' ? 'true' : 'false'} if query['miscellaneous']['identified'].present?
      poe_query['filters']['misc_filters']['filters']['crafted'] = {option: query['miscellaneous']['crafted'] == '1' ? 'true' : 'false'} if query['miscellaneous']['crafted'].present?
    end

    if query['trade'].present?
      poe_query['filters']['trade_filters'] = {}
      poe_query['filters']['trade_filters']['filters'] = {}
      poe_query['filters']['trade_filters']['filters']['account'] = {input: query['trade']['account']} if query['trade']['account'].present?
      poe_query['filters']['trade_filters']['filters']['sale_type'] = {option: query['trade']['saleType']} if query['trade']['saleType'].present?

      if query['trade']['price'].present?
        poe_query['filters']['trade_filters']['filters']['price'] = {}
        poe_query['filters']['trade_filters']['filters']['price']['option'] = query['trade']['price']['currency'].to_i if query['trade']['price']['currency'].present?
        poe_query['filters']['trade_filters']['filters']['price']['min'] = query['trade']['price']['min'].to_i if query['trade']['price']['min'].present?
        poe_query['filters']['trade_filters']['filters']['price']['max'] = query['trade']['price']['max'].to_i if query['trade']['price']['max'].present?
      end
    end

    poe_query
  end

  def convert_min_max(min_max)
    converted_min_max = {}
    converted_min_max['min'] = min_max['min'].to_i if min_max['min'].present?
    converted_min_max['max'] = min_max['max'].to_i if min_max['max'].present?
    converted_min_max
  end
end
