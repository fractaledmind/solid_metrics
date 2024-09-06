# frozen_string_literal: true

require_relative "subscriber"

module SolidMetrics
  class ActiveRecord
    IGNORE_EVENTS_DEFAULT = [
      { event_type: 'sql.active_record', query: /^(begin|commit)( transaction)?$/i },
      { event_type: 'sql.active_record', query: /(solid_queue|good_job)/i },
      { event_type: 'sql.active_record', name: "SCHEMA" },
      { event_type: 'sql.active_record', name: /^SolidMetrics/ },
    ].freeze

    mattr_accessor :ignored_events, default: []
    mattr_accessor :max_queue_size, default: 10000
    mattr_accessor :batch_size, default: 100
    mattr_accessor :flush_interval, default: 5

    class << self
      def ignored_events
        @ignored_events ||= @@ignored_events
      end
    end




    IGNORED_QUERIES = [
      /^ActiveRecord::SchemaMigration/,
      /^ActiveRecord::InternalMetadata/,
    ]



    private

      def ignore?(event)
        return true if event.payload[:name].nil?
        return true if SolidMetrics.ignoring_queries?
        return true if event.payload[:cached]

        ignorables = IGNORED_QUERIES + SolidMetrics.ignored_queries
        ignorables.any? { |q| q.match?(event.payload[:name]) }
      end
  end
end
