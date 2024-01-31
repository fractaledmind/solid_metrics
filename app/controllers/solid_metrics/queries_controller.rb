module SolidMetrics
  class QueriesController < ApplicationController
    # GET /queries
    def index
      @queries = QueryAggregate.order(total_ms: :desc).limit(100)
    end

    # GET /queries/1
    def show
      @query = Query.find(params[:id])
    end
  end
end
