libdir = File.expand_path('lib', File.dirname(__FILE__))
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include? libdir

require 'bundler/setup'
require 'lomatia'
require 'resque/tasks'

namespace "lomatia" do
  desc "Replant branch"
  task :replant, [:path, :source, :target] do |t, options|
    Lomatia::Branch.replant({'path' => options.path,
                             'source' => options.source,
                             'target' => options.target})
  end
end

task :default => ["lomatia:replant"]
