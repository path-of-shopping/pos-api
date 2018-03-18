module OfficialPoeTrade
  class ItemsExtractor
    # Constants
    ITEM_RARITY = ['normal', 'magic', 'rare', 'unique'].freeze

    def initialize(items)
      @items = items
    end

    def extract
      @items.map { |item| item_extract(item) }
    end

    private

    def item_extract(item)
      {
          id: item['id'],
          indexedAt: item['source']['indexed'],
          trade: {
              priceAmount: item['info']['price']['amount'],
              priceCurrency: item['info']['price']['currency'],
              whisper: item['account']['whisper'],
              accountName: item['account']['name'],
              characterName: item['account']['lastCharacterName'],
          },
          data: parse_item(item['item'])
      }
    end

    def parse_item(item)
      item_hash = {}

      item_hash['name'] = item['name'] if item['name'].present?
      item_hash['base'] = item['typeLine'] if item['typeLine'].present?
      item_hash['itemLevel'] = item['ilvl'] if item['ilvl'].present?
      item_hash['image'] = item['icon'] if item['icon'].present?
      item_hash['isIdentified'] = item['identified'] if item['identified'].present?
      item_hash['isVerified'] = item['verified'] if item['verified'].present?

      item_hash['pseudoMods'] = item['pseudoMods'].map {|mod| {value: mod}} if item['pseudoMods'].present?
      item_hash['implicitMods'] = item['implicitMods'].map {|mod| {value: mod}} if item['implicitMods'].present?
      item_hash['explicitMods'] = item['explicitMods'].map {|mod| {value: mod}} if item['explicitMods'].present?
      item_hash['properties'] = item['properties'].map {|property| {name: property['name'], value: property['values'].any? ? property['values'].first.first : nil}} if item['properties'].present?
      item_hash['requirements'] = item['requirements'].map {|requirement| {name: requirement['name'], value: requirement['values'].any? ? requirement['values'].first.first : nil}} if item['requirements'].present?
      item_hash['sockets'] = item['sockets'].map {|socket| {group: socket['group'], color: socket['sColour']}} if item['sockets'].present?

      item_hash['rarity'] = ITEM_RARITY[item['frameType']] if item['frameType'].present? && ITEM_RARITY[item['frameType']].present?

      item_hash
    end
  end
end
