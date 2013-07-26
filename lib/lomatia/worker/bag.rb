module Lomatia
  module Worker
    class Bag
      @queue = :lomatia

      def self.perform(options)
        # TODO: do the real work
        puts options.inspect
      end
    end
  end
end
