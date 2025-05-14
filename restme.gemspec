# frozen_string_literal: true

require_relative "lib/restme/version"

Gem::Specification.new do |spec|
  spec.name = "restme"
  spec.version = Restme::VERSION
  spec.authors = ["everson-ever"]
  spec.email = ["eversonsilva9799@gmail.com"]

  spec.summary = "Rest API support"
  spec.description = "Add filter/pagination/fields select/sort support to your API controllers"
  spec.homepage = "https://github.com/everson-ever/restme"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/everson-ever/restme"
  spec.metadata["changelog_uri"] = "https://github.com/everson-ever/restme/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_development_dependency "actionpack"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "database_cleaner-active_record"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "timecop"
end
