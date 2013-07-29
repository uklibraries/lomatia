require 'digest/md5'

module Lomatia
  module Worker
    class Bag
      @queue = :lomatia

      def self.perform(options)
        source = File.join(options['source'], options['path'])
        target = File.join(options['target'], options['path'])

        # Temporary paths for the move.
        source_old_path = self.temp_path_for(source, 'old_path')
        target_new_path = self.temp_path_for(target, 'new_path')
        target_old_path = self.temp_path_for(target, 'old_path')

        # Make sure the move won't clobber anything.
        raise ForbiddenBagMoveError unless self.can_move_bag?(source, target)

        # Check fixity of source.  This is slow.
        source_bag = BagIt::Bag.new source
        raise SourceBagInvalidError unless source_bag.valid?

        # Copy bag to target node.  This is slow.
        self.rsync source, target_new_path

        # Check fixity of target.  This is slow.
        target_bag = BagIt::Bag.new target_new_path
        raise TargetBagInvalidError unless target_bag.valid?

        # Do the symlink dance!
        FileUtils.mv source, source_old_path
        FileUtils.mv target, target_old_path
        FileUtils.mv target_new_path, target
        File.symlink source, target

        # Clear cruft.  This is slow.
        [
          source_old_path,
          target_old_path,
        ].each do |path|
          if File.symlink? path
            File.unlink path
          else
            FileUtils.rm_rf path
          end
        end
      end

      def self.can_move_bag?(source, target)
        return false unless File.exist? source
        return true  unless File.exist? target

        File.readpath(source) == File.readpath(target)
      end

      def self.rsync(source, target)
        FileUtils.mkdir_p(File.dirname target)
        rsync_command = '/usr/bin/rsync'
        rsync_options = '-avPOK'

        if system(rsync_command, 
                  rsync_options,
                  source + '/',
                  target)
          true
        else
          raise SourceBagRsyncFailedError
        end
      end

      def self.temp_path_for(path, label)
        File.join(
          File.dirname path,
          [
            File.basename path,
            Digest::MD5.digest("#{label}:#{Process.pid}"),
          ].join('.')
        )
      end
    end
  end
end
