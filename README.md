# DvlaWizardflow
This rails engine provides the following wizardflow functionality
- Dvla::Wizardflow::BaseController
  - This controller manages the defined steps and the storage of the data in those steps
- Dvla::Wizardflow::BaseModel
  - This model provides activemodel modules to allow the models to act like activerecord models. Validations and an update_attributes method.
- Routes are generated in your application scope based on steps you've defined in your workflow controllers. So if anything subclasses Dvla::Wizardflow::BaseController, routes will be created for the steps defined.

## Why

GOV.UK services normally follow an approach where data is collected over a number of steps and then submitted once all the data has been gathered. This Wizard gives a standard approach in how the flow uses controllers, models, routes and validation.  

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'dvla-wizardflow'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install dvla-wizardflow
```

## How

The following example of the wizard flow shows how to implement a very basic flow capturing contact information and then displaying the results back.   It contains 2  capture pages then a final page displaying the data captured.    


create a new rails application for the wizard flow.
```bash
$ rails new wizard_demo
```

Update the application model to extend the BaseModel from the Gem
```ruby
# app/models/applicaton_model.rb
class ApplicationModel < Dvla::Wizardflow::BaseModel
end
```

Create a capture email model for the email capture page
```ruby
# app/models/wizard/contact_detail/capture_email.rb
class Wizard::ContactDetail::CaptureEmail < ::ApplicationModel
  attr_accessor :email
end
```

Create a capture name model for the name capture page
```ruby
# app/models/wizard/contact_detail/capture_name.rb
class Wizard::ContactDetail::CaptureName < ::ApplicationModel
  attr_accessor :name
end
```

Create a ContactDetail model. This model encapsulates all the step models used in the wizard flow.
```ruby
# app/models/wizard/contact_detail/contact_detail.rb
class Wizard::ContactDetail::ContactDetail < ::ApplicationModel
   attr_accessor :capture_name, :capture_email, :display_contact

  def initialize(data = {})
    super(data)
    if data.blank?
      @capture_name = Wizard::ContactDetail::CaptureName.new
      @capture_email = Wizard::ContactDetail::CaptureEmail.new
    end
  end

  def capture_name=(data = {})
    @capture_name = Wizard::ContactDetail::CaptureName.new(data)
  end

  def capture_email=(data = {})
    @capture_email = Wizard::ContactDetail::CaptureEmail.new(data)
  end
end
```

A base controller for the application and extended the base controller from the wizard flow.

```ruby
# app/controllers/wizards/base_controller.rb
class Wizards::BaseController < Dvla::Wizardflow::BaseController

end
```

Create a new controller for the contact wizard flow that extends the BaseController.
set_steps method defines the wizard flow steps and the order in which they are executed.

```ruby
# app/controllers/wizards/contact_details_controller.rb
class Wizards::ContactDetailsController < Wizards::BaseController
  set_steps :capture_name, :capture_email, :display_contact
```

The capture_name step is the first step in the flow.  We are creating the contact_detail model if it does not already exist.
```ruby
  def capture_name
    @contact_detail = Wizard::ContactDetail::ContactDetail.new if @contact_detail.blank?
  end
```

The wizard flow always posts back to the same save method within the controller.  The parent model is updated and then tested if is valid. If the model is valid then the parent contact_detail model is saved to the session using the save_object helper method.  
```ruby
  def save
    if @contact_detail.blank?
      @contact_detail = Wizard::ContactDetail::ContactDetail.new
    end

    valid = @contact_detail.send(current_step).update_attributes(whitelisted_params_for_step(current_step)).valid?

    if valid
      save_object(@contact_detail)
      redirect_to_next_step()
    else
      render current_step.to_s
    end
  end
```


The setup method is a before_action in the BaseController.  The following logic in the ContactDetailsController shows how the ContactDetail model is retreived for every action. The session object is also removed if its the last step in the wizard flow.

```ruby
  protected
  def find_object
    super(Wizard::ContactDetail::ContactDetail)
  end

  def setup
    super()
    @contact_detail = find_object()

    if is_last_step?
      # if we're loading the last step - clear the session, since this is the confirmation page
      delete_object()
    end

    # setup form_url and form_method to keep consistent accross views
    @form_url = wizards_contact_details_save_path
    @form_method = :post
  end
```

The params are retrieved from the submitted form and tested if they are valid.
```ruby
private
  def permitted_attributes_for_step(step)
    case step
      when :capture_name
        [:name]
      when :capture_email
        [:email]
      end
  end
```
The model_for_step method defines what model to use for each step of the wizard flow.
```ruby
  def model_for_step(step)
    case step
      when :capture_name
        Wizard::ContactDetail::CaptureName
      when :capture_email
        Wizard::ContactDetail::CaptureEmail
    end
  end
```

A full listing of the ContactDetailsController.rb controller can be found here [ContactDetailsController.rb](ContactDetailsController.md)



Create a view for the first page in the flow to capture the contact name.
```html
 <%-# app/views/wizards/contact_details/capture_name.erb -%>
<h1>Enter Contact Name</h1>
<%= form_with(model: @contact_detail.contact_name, url: @form_url, method: @form_method, local: true) do |form| %>
  <div class="field">
    <%= form.label :name %>
    <%= form.text_field :name %>
  </div>
  <div class="actions">
    <%= form.submit %>
  </div>
<% end %>
```
Create a view for the second page in the flow to capture the contact email.
```html
 <%-# app/views/wizards/contact_details/capture_email.erb -%>
<h1>Enter Contact Email</h1>
<%= form_with(model: @contact_detail.contact_email, url: @form_url, method: @form_method, local: true) do |form| %>
  <div class="field">
    <%= form.label :email %>
    <%= form.text_field :email %>
  </div>
  <div class="actions">
    <%= form.submit %>
  </div>
<% end %>
```

The final confirmation page of the wizard flow showing the data entered in the previous steps.
```html
<%- app/views/wizards/contact_details/display_contact.erb -%>
<h1>Display Contact</h1>
<p>
  <strong>Name:</strong>
  <%= @contact_detail.capture_name.name %>
</p>
<p>
  <strong>Email:</strong>
  <%= @contact_detail.capture_email.email %>
</p>
```

Start the application and navigate to first page in the wizard flow http://localhost:3000/wizards/contact_details/capture_name


## Usage

N.B. As of version 1.0.0 wizard controllers must...
- implement a model_for_step method that receives a step name and returns the fully namespaced model name used to back that step
- implement a permitted_attributes_for_step method that receives a step name and returns an array of parameters that should be whitelisted for model assignment in that step.



## Deploy
The drone file will deploy the version defined in the lib/dvla/wizardflow/version.rb file. When changes are made, this file *must* be updated otherwise drone will try to write a version over the top and fail.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
