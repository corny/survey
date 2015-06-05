module Names

  extend self

  CURVES               = YAML.load_file Rails.root.join("config/ecdhe_curves.yml")
  SIGNATURE_ALGORITHMS = YAML.load_file Rails.root.join("config/signature_algorithms.yml")

  def curve(number)
    CURVES[number.to_i] || number
  end

  def signature_algorithm(oid)
    SIGNATURE_ALGORITHMS[oid] || oid
  end

end