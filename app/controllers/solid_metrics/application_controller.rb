module SolidMetrics
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    http_basic_authenticate_with name: SolidMetrics.username, password: SolidMetrics.password if SolidMetrics.password
  end
end
