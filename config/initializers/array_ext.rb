class Array

  def mean
    sum.to_f / size
  end

  def median
    sorted = self.sort
    (sorted[(size - 1) / 2] + sorted[size / 2]) / 2.0
  end

end
