module RewardSystem
  class Main
    attr_reader :validator, :errors, :calculator

    delegate :errors, :invalid?, to: :validator
    delegate :generate_scores, to: :calculator

    def initialize(data)
      @validator = Validator.new(data)
      @calculator = Calculator.new(data)
    end
  end
end
