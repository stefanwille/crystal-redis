require "rake"

desc "Runs all examples, for qa"
task :default do
  puts "Running all examples..."
  Dir.glob('examples/*.cr').each do |f|
    puts "#{f}:"
    system "crystal run #{f}"
    puts
  end
end
