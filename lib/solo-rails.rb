require 'solo-rails/version'
require 'cgi'
require 'open-uri'
require 'chronic'
require 'nokogiri'
require 'solo-rails/railtie' #if defined?(Rails)

module SoloRails

  def initialize
    @site = options[:base_uri]
  end

end