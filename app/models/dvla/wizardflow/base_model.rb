class Dvla::Wizardflow::BaseModel
  include ActiveModel::AttributeMethods
  include ActiveModel::Validations
  include ActiveModel::Dirty
  include ActiveModel::Conversion

  attr_accessor :id

  def initialize(data = {})
    self.update_attributes(data)
  end

  def attributes
    return self.instance_values
  end

  def update_attributes(data = {})
    data.each do |name, value|
      if self.respond_to? "#{name}="
        self.send("#{name}=", value)
      end
    end
    return self
  end

  def persisted?
    return self.id.present?
  end
end
