guard 'rack' do
  watch('Gemfile.lock')
  watch(%r{^(?:lib|db/migrate)/(?:[^/]+/)*[^.][^/]*\.rb$})
  watch('config/database.yml')
  watch('config.ru')
end

guard 'test' do
  watch(%r{^lib/((?:[^/]+\/)*)(.+)\.rb$}) do |m|
    "test/unit/#{m[1]}test_#{m[2]}.rb"
  end
  watch(%r{^test/((?:[^/]+\/)*)test.+\.rb$})
  watch('test/helper.rb') { 'test' }
end

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

guard 'shell' do
  watch(%r{db/migrate/\d+_.+.rb}) do |m|
    `bundle exec rake db:migrate[test]`
    `bundle exec rake db:migrate[development]`
  end
end
