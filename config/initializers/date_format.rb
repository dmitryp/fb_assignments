date_formats = {
  :us_date => '%m/%d/%Y', # MM/DD/YYYY
}

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(date_formats)
ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS.merge!(date_formats)