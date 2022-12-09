# frozen_string_literal: true

require_relative 'lib/pando_bot/version'

Gem::Specification.new do |spec|
  spec.name = 'pando_bot'
  spec.version = PandoBot::VERSION
  spec.authors = ['an-lee']
  spec.email = ['an.lee.work@gmail.com']

  spec.summary = 'An simple API wrapper for pando.im'
  spec.description = 'An simple API wrapper for pando lake/leaf/rings'
  spec.homepage = 'https://github.com/an-lee/pando_bot'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['allowed_push_host'] = "https://rubygems.org/"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/an-lee/pando_bot'
  spec.metadata['changelog_uri'] = 'https://github.com/an-lee/pando_bot/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'activesupport', '>= 5'
  spec.add_dependency 'faraday', '>= 2'
  spec.add_dependency 'faraday-retry', '>= 2'
  spec.add_dependency 'hashids', '>= 1'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
