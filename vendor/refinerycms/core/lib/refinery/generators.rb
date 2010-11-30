require 'pathname'

module Refinery
  module Generators
    # The core engine installer streamlines the installation of custom generated
    # engines. It takes the migrations and seeds in your engine and moves them
    # into the rails app db directory, ready to migrate.
    class EngineInstaller < Rails::Generators::Base
      include Rails::Generators::Migration

      class << self
        def engine_name(name = nil)
          @engine_name = name.to_s unless name.nil?
          @engine_name
        end

        def source_root(root = nil)
          Pathname.new(super.to_s)
        end

        # Implement the required interface for Rails::Generators::Migration.
        # taken from http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
        # can be removed once this issue is fixed:
        # # https://rails.lighthouseapp.com/projects/8994/tickets/3820-make-railsgeneratorsmigrationnext_migration_number-method-a-class-method-so-it-possible-to-use-it-in-custom-generators
        def next_migration_number(dirname)
          if ActiveRecord::Base.timestamped_migrations
            Time.now.utc.strftime("%Y%m%d%H%M%S")
          else
            "%.3d" % (current_migration_number(dirname) + 1)
          end
        end
      end

      def generate
        Pathname.glob(self.class.source_root.join('db', '**', '*.rb')) do |path|
          case path.to_s
          when %r{.*/migrate/[^\d].*}
            migration_template path.to_s, Rails.root.join("db/migrate/#{path.split.last.to_s.split('.rb').first}")
          when %r{.*/seeds.*}
            template path.to_s, Rails.root.join(path.to_s.split('/db/').first, 'db', path.to_s.split('/db/').last)
          end
        end

        puts "------------------------"
        puts "Now run:"
        puts "rake db:migrate"
        puts "------------------------"
      end
    end
  end
end

# Below is a hack until this issue:
# https://rails.lighthouseapp.com/projects/8994/tickets/3820-make-railsgeneratorsmigrationnext_migration_number-method-a-class-method-so-it-possible-to-use-it-in-custom-generators
# is fixed on the Rails project.

require 'rails/generators/named_base'
require 'rails/generators/migration'
require 'rails/generators/active_model'
require 'active_record'

module ActiveRecord
  module Generators
    class Base < Rails::Generators::NamedBase #:nodoc:
      include Rails::Generators::Migration

      # Implement the required interface for Rails::Generators::Migration.
      def self.next_migration_number(dirname) #:nodoc:
        next_migration_number = current_migration_number(dirname) + 1
        if ActiveRecord::Base.timestamped_migrations
          [Time.now.utc.strftime("%Y%m%d%H%M%S"), "%.14d" % next_migration_number].max
        else
          "%.3d" % next_migration_number
        end
      end
    end
  end
end