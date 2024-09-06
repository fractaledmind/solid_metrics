require 'thread'
require 'concurrent'

module SolidMetrics
  mattr_accessor :ignored_queries, default: []
  mattr_accessor :max_queue_size, default: 10000
  mattr_accessor :batch_size, default: 100
  mattr_accessor :flush_interval, default: 5
  mattr_accessor :database_path, default: 'solid_metrics.sqlite3'

  class << self
    def processor
      @processor ||= EventProcessor.new(
        database_path,
        max_size: max_queue_size,
        batch_size: batch_size,
        flush_interval: flush_interval
      )
    end

    def start
      processor.start
    end

    def stop
      processor.stop
    end
  end

  class EventProcessor
    def initialize(db_path, max_size:, batch_size:, flush_interval:)
      @db_path = db_path
      @max_size = max_size
      @batch_size = batch_size
      @flush_interval = flush_interval
      @event_buffer = Concurrent::Array.new
      @drop_count = Concurrent::AtomicFixnum.new(0)
      @total_processed = Concurrent::AtomicFixnum.new(0)
    end

    def start
      @running = true
      @db = SQLite3::Database.new(@db_path)
      ensure_table_exists
      prepare_insert_statement
      @flush_thread = Thread.new { flush_periodically }
    end

    def stop
      @running = false
      @flush_thread.join
      flush # Final flush
      @insert_stmt.close if @insert_stmt
      @db.close
    end

    def push(event)
      if @event_buffer.size < @max_size
        @event_buffer << normalize(event)
        true
      else
        @drop_count.increment
        false
      end
    end

    private
    
    def prepare_insert_statement
      @insert_stmt = @db.prepare(<<-SQL)
        INSERT INTO solid_metrics_queries (name, started_at, ended_at, duration_ms, sql, binds, payload)
        VALUES (?, ?, ?, ?, ?, ?, ?),
               (?, ?, ?, ?, ?, ?, ?),
               (?, ?, ?, ?, ?, ?, ?),
               (?, ?, ?, ?, ?, ?, ?),
               (?, ?, ?, ?, ?, ?, ?)
      SQL
    end

    def normalize(event)
      binds = if event.payload[:type_casted_binds].respond_to?(:call)
        event.payload[:binds].map { |column, value| ActiveRecord::Base.connection.type_cast(value, column) }
      else
        event.payload[:type_casted_binds]
      end

      {
        name: event.payload[:name],
        started_at: event.time,
        ended_at: event.end,
        duration_ms: event.duration,
        sql: event.payload[:sql],
        binds: binds,
        payload: event.payload.except(:connection, :binds, :sql, :name, :type_casted_binds)
      }
    end

    def flush_periodically
      while @running
        sleep @flush_interval
        flush
      end
    end

    def flush
      batch = @event_buffer.shift(@batch_size)
      return if batch.empty?

      write_to_database(batch)
    end

    def write_to_database(batch)
      @db.transaction do
        # Process events in groups of 5
        batch.each_slice(5) do |events|
          # Flatten the events into a single array of values
          values = events.flat_map do |event|
            [event[:name], event[:started_at], event[:ended_at], event[:duration_ms], 
             event[:sql], event[:binds].to_json, event[:payload].to_json]
          end

          # Pad with nil values if we don't have a full set of 5 events
          values.concat([nil] * (35 - values.size))

          # Execute the statement with all values
          @insert_stmt.execute(values)
        end
      end
      @total_processed.increment(batch.size)
    end

    def ensure_table_exists
      @db.execute(<<-SQL)
        CREATE TABLE IF NOT EXISTS solid_metrics_queries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          started_at DATETIME,
          ended_at DATETIME,
          duration_ms FLOAT,
          sql TEXT,
          binds TEXT,
          payload TEXT
        )
      SQL
    end
  end

  class ActiveRecordSubscriber < ActiveSupport::Subscriber
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
      SolidMetrics.processor.push(event)
    end

    private

    def ignore?(event)
      return true if event.payload[:name].nil?
      return true if event.payload[:cached]

      ignorables = IGNORED_QUERIES + SolidMetrics.ignored_queries
      ignorables.any? { |q| q.match?(event.payload[:name]) }
    end

    attach_to :active_record
  end
end