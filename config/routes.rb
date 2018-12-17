# need to load all classes so we can generate routes from their step definitions
Rails.application.eager_load!

Dvla::Wizardflow::Engine.routes.draw do
  # add routes in here if you want to isolate any thing from the hosting application, and manually mount them
end

Rails.application.routes.draw do
  Dvla::Wizardflow::StepRouter.load
end
