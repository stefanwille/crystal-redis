require 'rake'

task :docs do
  sh "crystal docs"
  sh "rm -rf /tmp/doc"
  sh "mv doc /tmp"
  sh "git checkout gh-pages"
  sh "rm -rf doc"
  sh "mv /tmp/doc ."
end
