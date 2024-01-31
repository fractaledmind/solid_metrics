# frozen_string_literal: true

module SolidMetrics
  class Processor
    def initialize
      @running = true
    end

    def process
      while @running
        if SolidMetrics.logged_queries.any?
          Query.insert_all(SolidMetrics.logged_queries)
        else
          sleep 1
        end
      end
    end

    def stop!
      @running = false
    end
  end
end
