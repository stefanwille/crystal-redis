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

desc 'Generates api doc. Ugly workaround for a Crystal bug.'
task :docs do
  puts 'Generating docs'
  sh "rm -rf ../crystal-redis-docs"
  sh "cp -R . ../crystal-redis-docs"
  sh "rm -rf ../crystal-redis-docs/.git"
  sh "cd ../crystal-redis-docs/ && git init"
  sh "cd ../crystal-redis-docs/ && crystal docs"
  sh "open ../crystal-redis-docs/doc/index.html"
end

