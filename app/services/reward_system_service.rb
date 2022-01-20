module RewardSystemService
  # 2018-06-12 09:41 A recommends B
  # 2018-06-14 09:41 B accepts
  # 2018-06-16 09:41 B recommends C
  # 2018-06-17 09:41 C accepts
  # 2018-06-19 09:41 C recommends D
  # 2018-06-23 09:41 B recommends D
  # 2018-06-25 09:41 D accepts

  class Node
    attr_accessor :points

    def initialize(invitee_name, inviter_node = nil)
      @name = invitee_name
      @inviter = inviter_node
      @accepts_invite = false
      @points = 0
      @node_depth = 0
    end

    def add_child(node)
      node.inviter = self
    end

    def accept_invite
      @accepts_invite = true
    end

    def node_depth
      node = self
      while node.present?
        @node_depth += 1
        node = node.parent
      end
    end

    def parent
      return @inviter if @accepts_invite

      nil
    end
  end

  class Tree
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
      0.5**level
    end

    def scores
      @store
        .transform_values(&:points)
        .reject { |_key, val| val <= 0 }
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
        (?<date>\d{4}-\d{2}-\d{2})                                 (?# date)
        \s
        (?<time>\d{2}:\d{2})                                       (?# time)
        \s
        (?:(?:(?<inviter>\w+) \s recommends \s (?<invitee>\w+))
        |
        (?:(?<accepter>\w+) \s accepts))
      )\z
    /xi

    PARSE_OPTIONS = {
      skip_blanks: true
    }.freeze

    attr_reader :formatted_data

    def initialize(data)
      @data = data.split(/(?:\r?\n)+/).map(&:strip)
      @formatted_data = []
      transform
    end

    def transform
      @data.each { |d| add(d) }
    end

    def add(raw_data)
      clean_data = format(raw_data)
      return if clean_data.blank?

      formatted_data
        .push(clean_data)
        .sort_by! { |el| el[:datetime] }
    end

    # Formats each string line for easy access, for example:
    # { datetime: 'Tue, 12 Jun 2018 09:41:00 +0000', action: :recommend, inviter: 'A', invitee: 'B' }
    # { datetime: 'Thu, 14 Jun 2018 09:41:00 +0000', action: :accept, accepter: 'B' }
    def format(raw_data)
      new_data = LINE_PATTERN.match(raw_data)&.named_captures
      return if new_data.blank?

      datetime = "#{new_data['date']} #{new_data['time']}"

      clean_data = { datetime: DateTime.parse(datetime) }

      if new_data['accepter'].blank?
        clean_data.merge!({ action: :recommend, inviter: new_data['inviter'], invitee: new_data['invitee'] })
      else
        clean_data[:action] = :accept
        clean_data[:accepter] = new_data['accepter']
      end
      clean_data
    end
  end

  class Calculator
    def initialize(data)
      @data = ParseData.new(data).formatted_data
      @tree = Tree.new
      populate_data
    end

    def populate_data
      @data.each do |d|
        case d[:action]
        when :recommend
          @tree.add_node(d[:invitee], d[:inviter])
        when :accept
          @tree.accept_invite(d[:accepter])
        end
      end
    end

    def generate_scores
      @tree.scores
    end
  end
end
