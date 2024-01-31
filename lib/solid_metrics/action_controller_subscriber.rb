# frozen_string_literal: true

require_relative "subscriber"

module SolidMetrics
  class ActionControllerSubscriber < Subscriber
    attach_to :action_controller

    def process_action(event)
      p({duration: event.duration}.merge(event.payload.except(:connection, :binds)))
    end
  end
end
