require 'base64'
require 'net/ssh'
require 'yaml'

class LaunchRemoteJob
  @queue = :ingest

  def self.perform payload
    file = File.join File.dirname(File.dirname(__FILE__)),
                     'config',
                     'remote-hosts.yml'
    config = YAML.load_file(file)

    server = payload['server']['name']

    if config.has_key? server
      Net::SSH.start(server, config[server]['username']) do |ssh|
        serialized = Base64.strict_encode64(payload.to_json)
        output = ssh.exec!("#{config[server]['create_job']} #{serialized}")
        puts output
      end
    else
      # TODO: fail task
    end
  end
end
