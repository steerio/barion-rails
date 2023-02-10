# frozen_string_literal: true

require 'barion/engine'

# Main module of Barion engine
module Barion
  LOCALES = %w(cs-CZ de-DE en-US es-ES fr-FR hu-HU sk-SK sl-SI)
  BASE_URL = {
    test: 'https://api.test.barion.com',
    prod: 'https://api.barion.com'
  }.freeze

  mattr_accessor :poskey, default: nil
  mattr_accessor :publickey, default: nil
  mattr_accessor :acronym, default: ''
  mattr_accessor :default_payee
  mattr_reader :default_locale, default: 'hu-HU'
  mattr_reader :user_class_name
  mattr_reader :item_class_name
  mattr_reader :rest_client_class_name, default: '::RestClient::Resource'
  cattr_reader :sandbox, default: true

  class << self
    alias_method :sandbox?, :sandbox

    def config
      yield self
    end

    def endpoint
      env = sandbox? ? :test : :prod
      rest_client_class.new BASE_URL[env]
    end

    # rubocop:disable Style/ClassVars
    def callback_host= host
      Engine.routes.default_url_options[:host] = host
    end

    def default_locale= value
      unless LOCALES.include? value
        raise ArgumentError, "Barion.default_locale must be one of {#{LOCALES.join(', ')}}, got #{value}"
      end
      @@default_locale = value
    end

    def sandbox= value
      @@sandbox = !!value
    end

    def user_class_name=(class_name)
      unless class_name.is_a?(String)
        raise ArgumentError, "Barion.user_class must be set to a String, got #{class_name.inspect}"
      end

      @@user_class = nil
      @@user_class_name = class_name
    end

    def user_class
      # This is nil before the initializer is installed.
      @@user_class ||= (@@user_class_name && @@user_class_name.constantize)
    end

    def item_class_name=(class_name)
      unless class_name.is_a?(String)
        raise ArgumentError, "Barion.item_class must be set to a String, got #{class_name.inspect}"
      end

      @@item_class = nil
      @@item_class_name = class_name
    end

    def item_class
      # This is nil before the initializer is installed.
      @@item_class ||= (@@item_class_name && @@item_class_name.constantize)
    end

    def rest_client_class_name=(class_name)
      unless class_name.is_a?(String)
        raise ArgumentError, "Barion.rest_client_class must be set to a String, got #{class_name.inspect}"
      end

      @@rest_client_class = nil
      @@rest_client_class_name = class_name
    end

    def rest_client_class
      # This is nil before the initializer is installed.
      @@rest_client_class ||= (@@rest_client_class_name && @@rest_client_class_name.constantize)
    end
    # rubocop:enable Style/ClassVars
  end

  # Error to signal the data in the db has been changed since saving it
  class TamperedData < RuntimeError
  end

  # Generic error class for Barion module
  class Error < StandardError
    attr_reader :title, :error_code, :happened_at, :auth_data, :endpoint, :errors

    def initialize(params)
      @title = params[:Title]
      @error_code = params[:ErrorCode]
      @happened_at = params[:HappenedAt]
      @auth_data = params[:AuthData]
      @endpoint = params[:Endpoint]
      @errors = Array(params[:Errors]).map { |e| Barion::Error.new(e) } if params.key? :Errors
      super(params[:Description])
    end

    def all_errors
      Array(@errors).map(&:message).join("\n")
    end
  end
end
