require 'tty-spinner'
require 'tty-box'
require 'rubyripper/tui/tuiHelpers'

class TUIMessages
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_accessor :state, :custom_message, :error

  def initialize(prefs = nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @state = :welcome
    @custom_message = nil
    @error = nil
    @spinner = TTY::Spinner.new(TUIHelpers.pastel.cyan("[:spinner]") + " " + _("Scanning drive %s for an audio disc...") % [@prefs.cdrom], format: :dots)
  end

  # Update state to scanning and start spinner if not running
  def scan
    @state = :scanning
    @spinner.reset
  end

  def welcome
    @state = :welcome
  end

  def refreshDisc
    scan()
  end

  def noDiscFound
    @state = :no_disc
  end

  def openTray
    @state = :open_tray
  end

  def closeTray
    @state = :close_tray
  end

  def askForDisc
    @state = :ask_for_disc
  end

  def noEjectFound
    @state = :no_eject
  end

  def showError(error)
    @state = :error
    @error = error
  end

  def showMessage(message)
    @state = :custom
    @custom_message = message
  end

  # Draw the message screen
  def draw
    TUIHelpers.clear_screen
    TUIHelpers.draw_header

    content = ""
    case @state
    when :welcome
      content = _("Welcome to RubyRipperRemix %s.") % [$rr_version] + "\n\n" + _("Press [F2] to start scanning the drive.")
    when :scanning
      # The spinner frame is drawn by the app loop
      @spinner.spin
      content = "\n" + @spinner.row
    when :no_disc
      content = TUIHelpers.color(:error, _("No disc found in %s!") % [@prefs.cdrom]) + "\n\n" +
                _("Please insert a disc and push 'Scan drive'.\n\nThe cdrom drive can be set in 'Preferences'.")
    when :open_tray
      content = _("Opening tray of drive %s.") % [@prefs.cdrom]
    when :close_tray
      content = _("Closing tray of the drive.") + "\n\n" + _("Scanning drive %s for an audio disc...") % [@prefs.cdrom]
    when :ask_for_disc
      content = _("Insert an audio-disc and press 'Close tray'.\nThe drive will automatically be scanned for a disc.\n\nIf the tray is already closed, press 'Scan drive'")
    when :no_eject
      content = TUIHelpers.color(:error, _("The eject utility is not found on your system!"))
    when :error
      if @error
        require 'rubyripper/errors'
        content = TUIHelpers.color(:error, Errors.send(@error[0], @error[1]))
      else
        content = TUIHelpers.color(:error, _("An unknown error occurred."))
      end
    when :custom
      content = @custom_message || ""
    end

    box = TTY::Box.frame(
      width: 80,
      height: 15,
      padding: [2, 4],
      style: {
        border: {
          fg: :cyan
        }
      }
    ) { content }
    puts box

    # Footer instructions
    footer_actions = [
      { key: "F2", label: _("Scan drive") },
      { key: "F3", label: _("Open/Close Tray") },
      { key: "F4", label: _("Preferences") },
      { key: "F10", label: _("Exit") }
    ]
    TUIHelpers.draw_footer(footer_actions)
  end
end
