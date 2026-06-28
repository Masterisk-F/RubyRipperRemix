require 'rubyripper/preferences/main'

require 'rubyripper/tui/tuiHelpers'
require 'rubyripper/tui/tuiKeyHandler'
require 'tty-prompt'

class TUISummary
  include GetText
  GetText.bindtextdomain("rubyripper")

  def initialize(gui, scheme, summary_text, success)
    @ui = gui
    @scheme = scheme
    @summary_text = summary_text
    @success = success
    @prefs = Preferences::Main.instance
    @prompt = TTY::Prompt.new
  end

  def start
    loop do
      draw
      choices = {
        _("Open Log File") => :open_log,
        _("Open Destination Directory") => :open_dir,
        _("Return to Main Menu") => :back
      }
      
      action = @prompt.select(_("Choose an action:"), choices)
      case action
      when :open_log
        log_file = File.join(@scheme.getDir(), "ripping.log")
        if File.exist?(log_file)
          TUIHelpers.clear_screen
          system("#{@prefs.editor} \"#{log_file}\"")
        else
          TUIHelpers.clear_screen
          puts TUIHelpers.color(:error, _("Log file not found!"))
          sleep(1.5)
        end
      when :open_dir
        dir = @scheme.getDir()
        if Dir.exist?(dir)
          TUIHelpers.clear_screen
          system("#{@prefs.filemanager} \"#{dir}\"")
        else
          TUIHelpers.clear_screen
          puts TUIHelpers.color(:error, _("Directory not found!"))
          sleep(1.5)
        end
      when :back
        break
      end
    end
  end

  def draw
    TUIHelpers.clear_screen
    TUIHelpers.draw_header

    # Result Header
    if @success
      header_msg = TUIHelpers.color(:success, _("The rip has successfully finished."))
    else
      header_msg = TUIHelpers.color(:error, _("The rip had some problems. Please check the summary/log."))
    end

    box_content = header_msg + "\n\n" + TUIHelpers.color(:title, _("Short Summary")) + "\n" + @summary_text

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
      { key: "Enter", label: _("Select Action") }
    ]
    TUIHelpers.draw_footer(footer_actions)
  end
end
