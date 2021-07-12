module RBS
  module Collection

    # This class represent the configration file.
    class Config
      PATH = Pathname('rbs_collection.yaml')

      # Generate a rbs lockfile from Gemfile.lock to `config_path`.
      # If `with_lockfile` is true, it respects existing rbs lockfile.
      def self.generate_lockfile(config_path:, gemfile_lock_path:, with_lockfile: true)
        config = from_path(config_path)
        gemfile_lock = Bundler::LockfileParser.new(gemfile_lock_path.read)

        lock_path = to_lockfile_path(config_path)
        lock = from_path(lock_path) if lock_path.exist? && with_lockfile

        GemfileLockLoader.new(lock: lock, gemfile_lock: gemfile_lock).load(config)
        config.dump_to(lock_path)
        config
      end

      def self.from_path(path)
        new(YAML.load(path.read))
      end

      def self.to_lockfile_path(config_path)
        config_path.sub_ext('.lock' + config_path.extname)
      end

      def initialize(data)
        @data = data
      end

      def add_gem(gem)
        gems << gem
      end

      def gem(gem_name)
        gems.find { |gem| gem['name'] == gem_name }
      end

      def path
        Pathname(@data['path'])
      end

      def collections
        @collections ||= (
          @data['collections']
            .map { |c| Collections.from_config_entry(c) }
            # TODO: .push(Collections::Stdlib.new, Collections::Rubygems.new)
        )
      end

      def dump_to(io)
        YAML.dump(@data, io)
      end

      def gems
        @data['gems'] ||= []
      end
    end
  end
end
