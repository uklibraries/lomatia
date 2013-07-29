module Lomatia
  module Worker
    class Bag
      @queue = :lomatia

      def self.perform(options)
        source = File.join(options['source'], options['path'])
        target = File.join(options['target'], options['path'])

        # Make sure the move won't clobber anything.
        raise ForbiddenBagMoveError unless self.can_move_bag?(source, target)

        # Check fixity of source.  This is slow.
        source_bag = BagIt::Bag.new source
        raise SourceBagInvalidError unless source_bag.valid?

        # Copy bag to target node.  This is slow.
        target_path = self.rsync source, target

        # Check fixity of target.  This is slow.
        target_bag = BagIt::Bag.new target_path
        raise TargetBagInvalidError unless target_bag.valid?

        # Do the symlink dance!
        source_path = File.join(
          File.dirname source,
          [
            File.basename(source),
            Digest::MD5.digest("#{source}:#{Process.pid}"),
          ].join('.')
        )
        FileUtils.mv source, source_path

        if File.exist? target and not(File.symlink? target)
          target_old_path = File.join(
            File.dirname target,
            [
              File.basename(target),
              Digest::MD5.digest("#{target}:#{Process.pid}"),
            ].join('.')
          )
          FileUtils.mv target, target_old_path
        end

        File.unlink(target) if File.exist? target
        FileUtils.mv target_path, target
        File.symlink source, target

        # Clear cruft.  This is slow.
        FileUtils.rm_rf target_old_path
        FileUtils.rm_rf source_path
      end

      def self.can_move_bag?(source, target)
        return false unless File.exist? source
        return true  unless File.exist? target

        File.readpath(source) == File.readpath(target)
      end

      def self.rsync(source, target)
        FileUtils.mkdir_p(File.dirname target)
        target_path = File.join(
          File.dirname target,
          [
            File.basename(source),
            Digest::MD5.digest("#{source}:#{Process.pid}"),
          ].join('.')
        )
        rsync_command = '/usr/bin/rsync'
        rsync_options = '-avPOK'

        if system(rsync_command, 
                  rsync_options,
                  source + '/',
                  target_path)
          target_path
        else
          raise SourceBagRsyncFailedError
        end
      end
    end
  end
end
