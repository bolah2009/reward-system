module RewardSystem
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
        .upcase
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
end
