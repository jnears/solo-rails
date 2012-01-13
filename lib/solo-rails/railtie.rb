module SoloRails
  class Railtie < Rails::Railtie
    config.solo_rails = ActiveSupport::OrderedOptions.new

    initializer "solo-rails.configure" do |app|
      app.config.solo_rails.to_hash
    end
  end
end
