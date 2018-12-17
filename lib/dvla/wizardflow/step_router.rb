module Dvla
  module Wizardflow
    # this class should be referenced from the routes.rb file, calling .load
    class StepRouter
      def self.load
        # need to load all classes so we can generate routes from their step definitions
        Rails.application.eager_load!

        Rails.application.routes.draw do
          namespace :wizards do
            wizard_controllers = Dvla::Wizardflow::BaseController.descendants
            wizard_controllers.each do |klass|
              namespace_name = klass.name.demodulize.gsub("Controller", "").scan(/([A-Z][a-z]+)/).join('_').downcase
              namespace namespace_name.to_sym do
                if klass.steps.present?
                  puts "Setting up routes for #{klass.name}"
                  klass.steps.each do |step|
                    puts "- #{step.to_s}"
                    get step
                  end
                  post :save
                  get :save, to: redirect("wizards/#{namespace_name}")
                  root action: klass.steps.first
                end
              end
            end
          end
        end
      end
    end
  end
end
