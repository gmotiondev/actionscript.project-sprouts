
module Sprout

  # Concrete param object for :string values
  class StringParam < Tool::Param

    def shell_value
      value.gsub(/ /, '\ ')
    end
  end

end
