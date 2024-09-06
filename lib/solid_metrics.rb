# frozen_string_literal: true

require_relative "solid_metrics/version"
require_relative "solid_metrics/engine"

module SolidMetrics
  mattr_accessor :connects_to
  mattr_writer :username
  mattr_writer :password

  class << self
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
