# frozen_string_literal: true

require_relative 'lib/eceval/version'

Gem::Specification.new do |s|
  s.name = 'eceval'
  s.summary = 'Evaluates Ruby code embedded in markdown, merging results'
  s.homepage = 'https://github.com/tomdalling/eceval'
  s.author = 'Tom Dalling'
  s.email = %w(tom tomdalling.com).join('@')
  s.license = 'MIT'

  s.files = Dir['lib/**/*']
  s.executables = %w[eceval]
  s.bindir = 'exe'
  s.version = Eceval::VERSION

  s.add_dependency 'dry-cli', '~> 0.6'

  s.add_development_dependency 'test_bench'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'super_diff'
  s.add_development_dependency 'gem-release'
end
