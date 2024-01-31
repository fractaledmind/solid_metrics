# frozen_string_literal: true

module SolidMetrics
  class Record < ActiveRecord::Base
    self.abstract_class = true

    connects_to(**SolidMetrics.connects_to) if SolidMetrics.connects_to
  end
end

ActiveSupport.run_load_hooks :solid_metrics_record, SolidMetrics::Record
