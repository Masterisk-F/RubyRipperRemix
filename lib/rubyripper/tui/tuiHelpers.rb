require 'pastel'
require 'tty-box'
require 'tty-table'

module TUIHelpers
  # Setup color palette
  def self.pastel
    @pastel ||= Pastel.new
  end

  # Color shorthand
  def self.color(name, text)
    case name
    when :title
      pastel.bold.cyan(text)
    when :highlight
      pastel.bold.yellow(text)
    when :success
      pastel.bold.green(text)
    when :error
      pastel.bold.red(text)
    when :muted
      pastel.dark.gray(text)
    when :accent
      pastel.bold.magenta(text)
    else
      text
    end
  end

  # Clear terminal screen completely
  def self.clear_screen
    print "\e[2J\e[H"
  end

  # Render application header box
  def self.draw_header
    version_text = "RubyRipperRemix v#{$rr_version || '0.8.0rc4_0.2.0'}"
    box = TTY::Box.frame(
      width: 80,
      height: 3,
      align: :center,
      padding: [0, 0],
      style: {
        border: {
          fg: :cyan
        }
      }
    ) { version_text }
    puts box
  end

  # Format status indicator
  def self.status_indicator(active, label)
    if active
      "[#{pastel.bold.green('x')}] #{label}"
    else
      "[ ] #{label}"
    end
  end

  # Render screen border and footer actions
  def self.draw_footer(actions = [])
    actions_str = actions.map { |a| "[#{color(:highlight, a[:key])}]#{a[:label]}" }.join("  ")
    box = TTY::Box.frame(
      width: 80,
      height: 3,
      padding: [0, 1],
      style: {
        border: {
          fg: :cyan
        }
      }
    ) { actions_str }
    puts box
  end
end
