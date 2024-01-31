# frozen_string_literal: true

require_relative "subscriber"

module SolidMetrics
  class ActiveRecordSubscriber < Subscriber
    attach_to :active_record

    IGNORED_QUERIES = [
      "SCHEMA",
      "TRANSACTION",
      /^ActiveRecord::SchemaMigration/,
      /^ActiveRecord::InternalMetadata/,
      /^SolidMetrics/,
      "SolidQueue::ClaimedExecution Load",
      "SolidQueue::ReadyExecution Pluck",
      "SolidQueue::Pause Pluck",
      "SolidQueue::ScheduledExecution Pluck",
    ]

    def sql(event)
      return if ignore?(event)

      if SolidMetrics.logged_queries.size >= SolidMetrics.max_logged_queries
        SolidMetrics.ignoring_queries do
          ProcessQueryBatchJob.perform_later(SolidMetrics.logged_queries)
          SolidMetrics.reset_logged_queries!
        end
      else
        SolidMetrics.logged_queries << normalized(event)
      end
    end

    private

      def ignore?(event)
        return true if event.payload[:name].nil?
        return true if SolidMetrics.ignoring_queries?

        ignorables = IGNORED_QUERIES + SolidMetrics.ignored_queries
        ignorables.any? { |q| q.match?(event.payload[:name]) }
      end

      def normalized(event)
        {
          sql: event.payload[:sql],
          duration: event.duration,
          name: event.payload[:name],
          binds: event.payload[:type_casted_binds].to_json,
          payload: event.payload.except(:connection, :binds, :sql, :name, :type_casted_binds)
        }
      end
  end
end
