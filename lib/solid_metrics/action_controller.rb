# frozen_string_literal: true

require_relative "subscriber"

module SolidMetrics
  class ActionControllerSubscriber < Subscriber
    IGNORE_EVENTS_DEFAULT = [
      { event_type: 'sql.active_record', query: /^(begin|commit)( transaction)?$/i },
      { event_type: 'sql.active_record', query: /(solid_queue|good_job)/i },
      { event_type: 'process_action.action_controller', controller: 'Rails::HealthController' }
    ].freeze

    attach_to :action_controller

    def process_action(event)
      p({duration: event.duration}.merge(event.payload.except(:connection, :binds)))
    end
  end
end
