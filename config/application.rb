require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PathOfShoppingWebApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Additional autoloaded paths
    config.autoload_paths += %W(
      #{config.root}/app/services/api
      #{config.root}/app/services/extractors
      #{config.root}/app/services/fetchers
      #{config.root}/app/services/converters
    )
  end
end
