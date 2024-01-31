# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module SolidMetrics
  #
  # Rails generator used for setting up SolidMetrics in a Rails application.
  # Run it with +bin/rails g solid_metrics:install+ in your console.
  #
  class InstallGenerator < Rails::Generators::Base
    include ActiveRecord::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    class_option :database, type: :string, aliases: %i[--db], desc: "The database for your migration. By default, the current environment's primary database is used."
    class_option :skip_migrations, type: :boolean, default: nil, desc: "Skip migrations"

    # Generates monolithic migration file that contains all database changes.
    def create_migration_file
      return if options[:skip_migrations]

      migration_template "create_solid_metrics_tables.rb.erb", File.join(db_migrate_path, "create_solid_metrics_tables.rb")
    end

    private

    def migration_version
      "[#{ActiveRecord::VERSION::STRING.to_f}]"
    end
  end
end
