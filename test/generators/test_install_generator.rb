# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require "generators/solid_metrics/install/install_generator"

class TestInstallGenerator < Rails::Generators::TestCase
  tests SolidMetrics::InstallGenerator
  destination File.expand_path("../tmp", __dir__)

  setup :prepare_destination

  def after_teardown
    FileUtils.rm_rf destination_root
    super
  end

  test "should generate a Litestream configuration file" do
    run_generator

    assert_migration "db/migrate/create_solid_metrics_tables.rb"
  end
end
