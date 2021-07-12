require 'digest/sha2'
require 'open3'

module RBS
  module Collection
    module Collections
      def self.from_config_entry(collection_entry)
        # TODO: other kind of collection?
        Git.new(**collection_entry.slice('name', 'revision', 'remote', 'repo_dir').transform_keys(&:to_sym))
      end

      class Git
        attr_reader :name, :revision, :remote, :repo_dir

        def initialize(name:, revision:, remote:, repo_dir:)
          @name = name
          @revision = revision
          @remote = remote
          @repo_dir = repo_dir || 'gems'

          setup!
        end

        def has?(config_entry)
          gem_name = config_entry['name']
          gem_repo_dir.join(gem_name).directory?
        end

        def versions(config_entry)
          gem_name = config_entry['name']
          gem_repo_dir.join(gem_name).glob('*/').map { |path| path.basename.to_s }
        end

        def install(dest, config_entry)
          gem_name = config_entry['name']
          version = config_entry['version'] or raise
          dest = dest.join(gem_name)
          dest.mkpath
          src = gem_repo_dir.join(gem_name, version)

          FileUtils.cp_r(src, dest)
          dest.join(version, '.meta.yaml').write(YAML.dump(config_entry))
        end

        def to_lockfile
          {
            'name' => name,
            'revision' => resolved_revision,
            'remote' => remote,
            'repo_dir' => repo_dir,
          }
        end

        private def setup!
          git_dir.mkpath
          if git_dir.join('.git').directory?
            # TODO: Skip fetch if unnecessary
            git 'fetch', 'origin'
          else
            git 'clone', remote, git_dir.to_s
          end

          git 'checkout', revision
        end

        private def git_dir
          @git_dir ||= (
            base = Pathname(ENV['XDG_CACHE_HOME'] || File.expand_path("~/.cache"))
            dir = base.join('rbs', Digest::SHA256.hexdigest(remote))
            dir.mkpath
            dir
          )
        end

        private def gem_repo_dir
          git_dir.join @repo_dir
        end

        private def resolved_revision
          @resolved_revision ||= resolve_revision(revision)
        end

        private def resolve_revision(rev)
          git('rev-parse', rev).chomp
        end

        private def git(*cmd)
          sh! 'git', *cmd
        end

        private def sh!(*cmd)
          RBS.logger.debug "$ #{cmd.join(' ')}"
          Open3.capture3(*cmd, chdir: git_dir).then do |out, err, status|
            raise "Unexpected status #{status.exitstatus}\n\n#{err}" unless status.success?

            out
          end
        end
      end

      # signatures that are bundled in rbs gem under the stdlib/ directory
      class Stdlib
        attr_reader :name

        def has?(config_name)
          raise NotImplementedError
        end

        def versions(config_name)
          raise NotImplementedError
        end
      end

      # sig/ directory
      class Rubygems
      end
    end
  end
end
