module SolidMetrics
  class QueriesController < ApplicationController
    # GET /queries
    def index
      @queries = Query.group(:name).order(count_all: :desc).count
    end

    # GET /queries/1
    def show
      @query = Query.find(params[:id])
    end
  end
end
