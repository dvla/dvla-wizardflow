module Dvla
  module Wizardflow
    class Engine < ::Rails::Engine
      isolate_namespace Dvla::Wizardflow

      config.autoload_paths += Dir["#{config.root}/lib/**/"]
    end
  end
end
