begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec
rescue LoadError
  $stderr.puts('RSpec is a development dependency for KvAccessor')
end
