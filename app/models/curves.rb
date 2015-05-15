module Curves

  extend self

  NAMES = YAML.load_file(Rails.root.join "config/ecdhe_curves.yml")

  def name(number)
  	NAMES[number.to_i] || number
  end

end