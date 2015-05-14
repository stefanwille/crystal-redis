require 'rake'

desc 'Runs all examples, for qa'
task :default do
  puts 'Running all examples...'
  Dir.glob('examples/*.cr').each do |f|
    puts "#{f}:"
    system "crystal run #{f}"
    puts
  end
end

task :docs do
  sh "crystal docs"
  sh "rm -rf /tmp/doc"
  sh "mv doc /tmp"
  sh "git checkout gh-pages"
  sh "rm -rf doc"
  sh "mv /tmp/doc ."
end