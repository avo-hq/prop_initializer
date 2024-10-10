require_relative "lib/prop_initializer/version"

Gem::Specification.new do |spec|
  spec.name        = "prop_initializer"
  spec.version     = PropInitializer::VERSION
  spec.authors     = [ "Paul Bob" ]
  spec.email       = [ "paul.ionut.bob@gmail.com" ]
  spec.homepage    = "https://github.com/avo-hq/prop_initializer"
  spec.summary     = "A flexible property initializer for Ruby classes inspired by the Literal gem."
  spec.description = "PropInitializer provides an easy way to define properties for Ruby classes with options for defaults and customization. It simplifies the Literal gem's functionality by removing strict type requirements and adapting the initializer process for flexibility."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "zeitwerk", ">= 2.6.18"
end
