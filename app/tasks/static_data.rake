namespace :static_data do
  desc 'Update static data (mods, leagues, items, etc)'

  task update: :environment do
    puts 'Updating leagues...'
    leagues = OfficialPoeTrade::LeaguesFetcher.new.fetch
    File.open('./app/constants/leagues.yml', 'w') { |file| file.write(leagues.to_yaml) }

    puts 'Done !'
  end
end
