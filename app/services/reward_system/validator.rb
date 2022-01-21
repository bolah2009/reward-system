module RewardSystem
  class Validator
    include ActiveModel::Model

    ACTIONS = { accept: :accept, recommend: :recommend }.freeze

    attr_accessor :data

    validates :data, presence: true

    validate :check_data

    def initialize(raw_data)
      @data = raw_data
      @parsed_data = ParseData.new(data)
    end

    private

    def check_data
      return if errors.present?

      validate_each_line
    end

    def validate_each_line
      @parsed_data.cleaned_data.each_with_index do |row, index|
        line = index + 1 # index starts with 0
        matched_data = @parsed_data.matched_data(row)
        validate_format(matched_data, line)
        validate_date(matched_data, line)
      end
    end

    def validate_format(row, line)
      return if row.present?

      errors.add(:format, "Invalid invitation format in line #{line}")
      throw :abort
    end

    def validate_date(row, line)
      DateTime.parse(row['datetime'])
    rescue Date::Error
      errors.add(:date, "Invalid date format in line #{line}")
      throw :abort
    end
  end
end
