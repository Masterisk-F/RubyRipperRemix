require 'io/console'
require 'tty-box'
require 'tty-prompt'
require 'rubyripper/tui/tuiHelpers'
require 'rubyripper/tui/tuiKeyHandler'

class TUIRipStatus
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :logs, :ripping_progress, :encoding_progress, :finished, :success

  def initialize(gui)
    @ui = gui
    @prompt = TTY::Prompt.new
    reset
  end

  def reset
    @logs = []
    @ripping_progress = 0.0
    @encoding_progress = 0.0
    @finished = false
    @cancelled = false
    @success = nil
  end

  def updateProgress(type, value)
    if type == 'encoding'
      @encoding_progress = value
    else
      @ripping_progress = value
    end
  end

  def logChange(text)
    # Append incoming log strings, split by newline
    text.split("\n").each do |line|
      @logs << line.rstrip unless line.strip.empty?
    end
  end

  def scrollToEnd
    # No-op in TUI as we slice the logs array from the end on every draw
  end

  # Draw the ripping progress layout
  def draw
    TUIHelpers.clear_screen
    TUIHelpers.draw_header

    # Ripping Progress Bar
    rip_percent = (@ripping_progress * 100).round(1)
    rip_bar_filled = (@ripping_progress * 30).round
    rip_bar = "█" * rip_bar_filled + "░" * (30 - rip_bar_filled)

    # Encoding Progress Bar
    enc_percent = (@encoding_progress * 100).round(1)
    enc_bar_filled = (@encoding_progress * 30).round
    enc_bar = "█" * enc_bar_filled + "░" * (30 - enc_bar_filled)

    progress_lines = [
      TUIHelpers.color(:title, _("Ripping Status")),
      "",
      "#{_('Ripping progress')}: [#{TUIHelpers.pastel.green(rip_bar)}] #{rip_percent}%",
      "#{_('Encoding progress')}: [#{TUIHelpers.pastel.yellow(enc_bar)}] #{enc_percent}%",
      "",
      TUIHelpers.color(:title, _("Log Output")),
      ""
    ]

    # Get the last 10 lines of logs to fit in the box
    visible_logs = @logs.last(10)
    # Pad with empty lines if logs are short
    while visible_logs.size < 10
      visible_logs << ""
    end

    box_content = progress_lines.join("\n") + visible_logs.join("\n")

    box = TTY::Box.frame(
      width: 80,
      height: 20,
      padding: [1, 2],
      style: {
        border: {
          fg: :cyan
        }
      }
    ) { box_content }
    puts box

    footer_actions = [
      { key: "F10", label: _("Cancel rip") }
    ]
    TUIHelpers.draw_footer(footer_actions)
  end

  # Main polling loop for ripping progress and key events
  def start(rubyripper, thread)
    @rubyripper = rubyripper
    @thread = thread
    reset

    loop do
      # Process events in the update queue
      until @ui.update_queue.empty?
        modus, value = @ui.update_queue.pop
        case modus
        when "ripping_progress"
          updateProgress('ripping', value)
        when "encoding_progress"
          updateProgress('encoding', value)
        when "log_change"
          logChange(value)
        when "dir_exists"
          handle_dir_exists(value)
        when "finished"
          @finished = true
          @success = value
        end
      end

      draw

      break if @finished || @cancelled

      # Non-blocking key check for cancellation
      if STDIN.ready?
        key, _ = TUIKeyHandler.read_key
        if key == :f10 || key == :escape || key == 'q' || key == 'Q'
          cancel_rip
          break
        end
      end

      sleep 0.1
    end
  end

  def cancel_rip
    @cancelled = true
    @rubyripper.cancelRip if @rubyripper
    TUIHelpers.clear_screen
    puts TUIHelpers.color(:error, _("Ripping cancelled by user."))
    sleep(1.5)
  end

  def handle_dir_exists(dirname)
    # Stop drawing and prompt the user synchronously
    TUIHelpers.clear_screen
    TUIHelpers.draw_header
    puts TUIHelpers.color(:error, _("The directory %s already exists.") % [dirname])
    puts ""

    choices = {
      _("Cancel rip") => :cancel,
      _("Delete existing directory (Overwrite)") => :overwrite,
      _("Auto rename directory (Rename)") => :rename
    }

    choice = @prompt.select(_("What do you want RubyRipperRemix to do?"), choices)
    case choice
    when :cancel
      cancel_rip
    when :overwrite
      @rubyripper.overwriteDir
      @ui.continueRip
    when :rename
      @rubyripper.postfixDir
      @ui.continueRip
    end
  end
end
