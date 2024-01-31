module SolidMetrics
  class Job < ActiveJob::Base
    queue_as SolidMetrics.queue_name
  end
end
