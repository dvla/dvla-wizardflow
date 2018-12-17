class Wizards::ContactDetailsController < Wizards::BaseController
  set_steps :capture_name, :capture_email, :display_contact

  def capture_name
    @contact_detail = Wizard::ContactDetail::ContactDetail.new if @contact_detail.blank?
  end

  def capture_email
  end

  def display_contact
  end

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



  private

  def permitted_attributes_for_step(step)
    case step
      when :capture_name
        [:name]
      when :capture_email
        [:email]
      end
  end

  def model_for_step(step)
    case step
      when :capture_name
        Wizard::ContactDetail::CaptureName
      when :capture_email
        Wizard::ContactDetail::CaptureEmail
    end

  end

end
