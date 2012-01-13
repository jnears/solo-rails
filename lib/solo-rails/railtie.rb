module SoloRails

  class Railtie < Rails::Railtie
	ActionView::Base.send :include, SoloRailsHelpers
  end

end