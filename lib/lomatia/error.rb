module Lomatia
  module Error
    class BranchAlreadyMovedError < Exception
    end

    class BranchNotADirectoryError < Exception
    end

    class ForbiddenBagMoveError < Exception
    end

    class SourceBagInvalidError < Exception
    end

    class SourceBagRsyncFailedError < Exception
    end

    class TargetBagInvalidError < Exception
    end
  end
end
