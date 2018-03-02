namespace :static_data do
  desc 'Update static data (mods, leagues, items, etc)'

  task update: :environment do
    puts 'Updating leagues...'
    File.open('./app/constants/leagues.yml', 'w') { |file| file.write(OfficialPoeTrade::LeaguesFetcher.new.fetch.to_yaml) }

    puts 'Updating mods...'
    File.open('./app/constants/mods.yml', 'w') { |file| file.write(OfficialPoeTrade::ModsFetcher.new.fetch.to_yaml) }

    puts 'Done !'
  end
end
