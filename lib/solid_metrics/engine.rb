# frozen_string_literal: true

module SolidMetrics
  class Engine < ::Rails::Engine
    isolate_namespace SolidMetrics

    config.solid_metrics = ActiveSupport::OrderedOptions.new

    initializer "solid_metrics.config" do
      config.solid_metrics.each do |name, value|
        SolidMetrics.public_send("#{name}=", value)
      end
    end

    initializer "solid_metrics.active_record_subscriber" do
      ActiveSupport.on_load :active_record do
        require "solid_metrics/active_record_subscriber"
      end
    end

    initializer "solid_metrics.action_controller_subscriber" do
      ActiveSupport.on_load :action_controller_base do
        require "solid_metrics/action_controller_subscriber"
      end
    end
  end
end
