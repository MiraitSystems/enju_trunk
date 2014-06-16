module TaxRatesHelper
  def rounding_type_name(type_id)
    TaxRate::ROUNDING_TYPES[type_id]
  end
end
