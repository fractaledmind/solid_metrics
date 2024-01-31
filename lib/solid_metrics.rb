# frozen_string_literal: true

require_relative "solid_metrics/version"
require_relative "solid_metrics/engine"

module SolidMetrics
  mattr_accessor :connects_to
  mattr_accessor :ignored_queries, default: []
  mattr_accessor :max_logged_queries, default: 100
  mattr_accessor :queue_name, default: :solid_metrics
  mattr_writer :username
  mattr_writer :password

  class << self
    def ignoring_queries?
      @ignoring_queries ||= false
    end

    def ignoring_queries(&block)
      @ignoring_queries = true
      yield
      @ignoring_queries = false
    end

    def logged_queries
      @logged_queries ||= Array.new
    end

    def reset_logged_queries!
      @logged_queries = Array.new
    end

    # use method instead of attr_accessor to ensure
    # this works if variable set after SolidErrors is loaded
    def username
      @username ||= ENV["SOLIDMETRICS_USERNAME"] || @@username
    end

    # use method instead of attr_accessor to ensure
    # this works if variable set after SolidErrors is loaded
    def password
      @password ||= ENV["SOLIDMETRICS_PASSWORD"] || @@password
    end
  end
end
