require 'tty-reader'

module TUIKeyHandler
  # Initialize the reader
  def self.reader
    @reader ||= TTY::Reader.new
  end

  # Read a single keypress and map it to a symbol or character string
  # Returns [mapped_symbol_or_char, raw_key_event]
  def self.read_key
    event = reader.read_keypress
    key_name = event.key.name if event.key

    mapped = case key_name
             when :up, :k then :up
             when :down, :j then :down
             when :left, :h then :left
             when :right, :l then :right
             when :escape then :escape
             when :enter, :return then :enter
             when :space then :space
             when :f1 then :f1
             when :f2 then :f2
             when :f3 then :f3
             when :f4 then :f4
             when :f5 then :f5
             when :f10 then :f10
             else
               # Return the character value if it's a regular key
               event.value
             end

    [mapped, event]
  end
end
