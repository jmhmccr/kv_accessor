require_relative 'lib/kv_accessor/version'

Gem::Specification.new do |s|
  s.name          = 'kv_accessor'
  s.author        = 'Jeremiah McCann'
  s.email         = ['kv.accessor.gem@gmail.com']
  s.files         = Dir['lib/**/*.rb', 'bin/*', 'LICENSE', '*.md']
  s.homepage      = 'http://github.com/jmhmccr/kv_accessor'
  s.license       = 'BSD-3-Clause'
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib/']
  s.test_files    = Dir['spec/**/*.rb']
  s.version       = KvAccessor::VERSION

  s.summary     = 'Generate accessor methods for an indexed object'
  s.description = 'Pretty much Forwardable for key-value objects'

  s.add_development_dependency('rspec', '~> 3.4')
end
