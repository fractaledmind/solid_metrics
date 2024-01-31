module SolidMetrics
  class ProcessQueryBatchJob < Job
    def perform(queries)
      Query.insert_all(queries)
    end
  end
end
