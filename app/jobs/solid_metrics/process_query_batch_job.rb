module SolidMetrics
  class ProcessQueryBatchJob < Job
    def perform(queries)
      aggregates = QueryAggregate.where(sql: queries.map { |q| q[:sql] })
                                 .pluck(:sql, :count, :total_ms, :p50_ms, :p99_ms)
                                 .to_h { |sql, *args| [sql, args] }

      QueryAggregate.upsert_all(
        queries.group_by { |q| q[:sql] }.map do |sql, group|
          count, total_ms, p50ms, p99ms = aggregates[sql]
          durations = group.map { |q| q[:duration_ms] }

          {
            sql: sql,
            count: count ? count + group.size : group.size,
            total_ms: (total_ms ? durations << total_ms : durations).sum,
            p50_ms: percentile((p50ms ? durations << p50ms : durations), 0.5),
            p99_ms: percentile((p99ms ? durations << p99ms : durations), 0.99),
            name: group.group_by { |q| q[:name] }.count == 1 ? group.first[:name] : nil,
          }
        end,
        unique_by: :sql,
      )
    end

    private

      # adapted from: https://github.com/ankane/active_median/blob/master/lib/active_median/enumerable.rb
      def percentile(values, percentile)
        percentile = percentile.to_f
        raise ArgumentError, "percentile is not between 0 and 1" if percentile < 0 || percentile > 1

        # uses C=1 variant, like percentile_cont
        # https://en.wikipedia.org/wiki/Percentile#The_linear_interpolation_between_closest_ranks_method
        sorted = values.sort
        x = percentile * (sorted.size - 1)
        r = x % 1
        i = x.floor
        if i == sorted.size - 1
          sorted[-1]
        else
          sorted[i] + r * (sorted[i + 1] - sorted[i])
        end
      end
  end
end
