# A sample Guardfile
# More info at https://github.com/guard/guard#readme

group :development do
  guard :livereload do
    watch('example/example.html')
    watch('css/abgrid.css')
    watch(%r{^dist/.+\js$})
  end

  guard :coffeescript, :output => 'dist/' do
    watch(%r{^src/.+\.coffee$})
  end

end
