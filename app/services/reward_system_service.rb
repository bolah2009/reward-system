module RewardSystemService
  class Node
    attr_accessor :points

    def initialize(invitee_name, inviter_node = nil)
      @name = invitee_name
      @inviter = inviter_node
      @accepts_invite = false
      @points = 0
      @node_depth = 0
    end

    def parent
      return @inviter if @accepts_invite

      nil
    end

    def accept_invite
      @accepts_invite = true
    end
  end

  class Tree
    SCORE_FACTOR = 0.5

    def initialize
      @store = {}
      @root_node = nil
    end

    # 2018-06-12 09:41 A (inviter) recommends B (invitee)
    def add_node(invitee_name, inviter_name)
      # dont accept any other invite except from the first invite
      return if node_exists? invitee_name

      inviter_node = find_or_create_inviter_node(inviter_name)
      create_node(invitee_name, inviter_node)
    end

    # 2018-06-14 09:41 B accepts
    def accept_invite(invitee_name)
      # dont accept invite for invitation that does not exist
      return unless node_exists?(invitee_name)

      invitee_node = @store[invitee_name]
      invitee_node.accept_invite

      assign_score invitee_node
    end

    def scores
      @store
        .transform_values(&:points)
        .reject { |_key, val| val <= 0 }
    end

    private

    def node_exists?(node_name)
      @store[node_name].present?
    end

    def assign_score(node)
      node = node.parent
      level = 0
      while node.present?
        node.points += score(level)
        level += 1
        node = node.parent
      end
    end

    def score(level)
      SCORE_FACTOR**level
    end

    def find_or_create_inviter_node(inviter_name)
      return @store[inviter_name] if node_exists?(inviter_name)

      create_node(inviter_name)
    end

    def create_node(node_name, parent = nil)
      node = Node.new(node_name, parent)
      @store[node_name] = node
      node
    end
  end

  class ParseData
    LINE_PATTERN = /
      \A(?:
        (?<datetime>\d{4}-\d{2}-\d{2}\s\d{2}:\d{2})     (?# datetime)
        \s
        (?:(?:(?<inviter>\w+) \s recommends \s (?<invitee>\w+))
        |
        (?:(?<accepter>\w+) \s accepts))
      )\z
    /xi

    PARSE_OPTIONS = {
      skip_blanks: true
    }.freeze

    attr_reader :cleaned_data

    def initialize(data)
      @cleaned_data = clean(data)
      @formatted_data = []
    end

    def transform
      cleaned_data.each { |d| add(d) }
      @formatted_data
    end

    def matched_data(raw_data)
      LINE_PATTERN.match(raw_data)&.named_captures
    end

    # Formats each string line for easy access, for example:
    # { datetime: 'Tue, 12 Jun 2018 09:41:00 +0000', action: :recommend, inviter: 'A', invitee: 'B' }
    # { datetime: 'Thu, 14 Jun 2018 09:41:00 +0000', action: :accept, accepter: 'B' }
    def format(raw_data)
      new_data = matched_data(raw_data)
      return if new_data.blank?

      clean_data = { datetime: DateTime.parse(new_data['datetime']) }

      if new_data['accepter'].blank?
        clean_data.merge!({ action: :recommend, inviter: new_data['inviter'], invitee: new_data['invitee'] })
      else
        clean_data[:action] = :accept
        clean_data[:accepter] = new_data['accepter']
      end
      clean_data
    end

    private

    def clean(data)
      data
        .strip
        .split(/(?:\r?\n)+/) # some OS such as DOS and Windows uses \r\n
        .map(&:strip)
    end

    def add(raw_data)
      clean_data = format(raw_data)
      return if clean_data.blank?

      @formatted_data
        .push(clean_data)
        .sort_by! { |el| el[:datetime] }
    end
  end

  class Calculator
    def initialize(data)
      @data = ParseData.new(data)
      @tree = Tree.new
    end

    def generate_scores
      populate_data
      @tree.scores
    end

    private

    def populate_data
      @data.transform.each do |row|
        case row[:action]
        when :recommend
          @tree.add_node(row[:invitee], row[:inviter])
        when :accept
          @tree.accept_invite(row[:accepter])
        end
      end
    end
  end


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
        validate_actions(row, line)
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

    # { datetime: 'Tue, 12 Jun 2018 09:41:00 +0000', action: :recommend, inviter: 'A', invitee: 'B' }
    # { datetime: 'Thu, 14 Jun 2018 09:41:00 +0000', action: :accept, accepter: 'B' }
    def validate_actions(row, line)
      formatted_data = @parsed_data.format(row)

      if formatted_data.present? && formatted_data[:action] == ACTIONS[:recommend]
        return validate_recommendation(formatted_data,
                                       line)
      end

      if formatted_data.present? && formatted_data[:action] == ACTIONS[:accept]
        return validate_acceptance(formatted_data,
                                   line)
      end

      errors.add(:action, "Invitation should have a valid action, e.g. #{ACTIONS.values.first} at line #{line}")
      throw :abort
    end

    def validate_recommendation(formatted_data, line)
      if formatted_data[:inviter].blank?
        errors.add(:inviter, "Invitation should have a valid inviter at line #{line}")
        throw :abort
      end

      return if formatted_data[:invitee].present?

      errors.add(:invitee, "Invitation should have a valid invitee at line #{line}")
      throw :abort
    end

    def validate_acceptance(formatted_data, line)
      return if formatted_data[:accepter].present?

      errors.add(:accepter, "Invitation should have a valid accepter at line #{line}")
      throw :abort
    end
  end

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
