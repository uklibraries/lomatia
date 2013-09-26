class LaunchRemoteJob
  @queue = :ingest

  def self.perform payload
    # do nothing
    puts payload
  end
end
