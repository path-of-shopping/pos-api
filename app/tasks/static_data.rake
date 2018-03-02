namespace :static_data do
  desc 'Update static data (mods, leagues, items, etc)'

  task update: :environment do
    puts 'Updating leagues...'
    File.open('./config/statics/leagues.yml', 'w') { |file| file.write(OfficialPoeTrade::LeaguesFetcher.new.fetch.to_yaml) }

    puts 'Updating mods...'
    File.open('./config/statics/mods.yml', 'w') { |file| file.write(OfficialPoeTrade::ModsFetcher.new.fetch.to_yaml) }

    puts 'Updating currencies...'
    File.open('./config/statics/currencies.yml', 'w') { |file| file.write(OfficialPoeTrade::CurrenciesFetcher.new.fetch.to_yaml) }

    puts 'Updating items...'
    File.open('./config/statics/items.yml', 'w') { |file| file.write(OfficialPoeTrade::ItemsFetcher.new.fetch.to_yaml) }

    puts 'Done !'
  end
end
