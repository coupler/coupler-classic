require 'lotus'

module Coupler
  class Application < Lotus::Application
    configure do
      layout :application
      routes do
        get '/', to: 'home#index'
      end

      load_paths << 'app'

      controller_pattern "%{controller}Controller::%{action}"
      view_pattern       "%{controller}::%{action}"
    end
  end
end
