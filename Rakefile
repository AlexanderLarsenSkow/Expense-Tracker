require "rake/testtask"

desc 'Run Sinatra App'
task :run do
  system('ruby expense.rb')
end

desc 'Run tests'
task :default => :test

Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

