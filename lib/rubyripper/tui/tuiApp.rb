require 'thread'
require 'rubyripper/preferences/main'
require 'rubyripper/system/dependency'
require 'rubyripper/tui/tuiHelpers'
require 'rubyripper/tui/tuiKeyHandler'
require 'rubyripper/tui/tuiMessages'
require 'rubyripper/tui/tuiDisc'
require 'rubyripper/tui/tuiPreferences'
require 'rubyripper/tui/tuiRipStatus'

class TUIApp
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :update_queue, :disc, :prefs

  def initialize(prefs = nil, messages = nil, deps = nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @messages = messages ? messages : TUIMessages.new
    @deps = deps ? deps : Dependency.instance
    @disc = TUIDisc.new(self)
    @preferences = TUIPreferences.new(self)
    @rip_status = TUIRipStatus.new(self)
    
    @update_queue = Queue.new
    @current_view = :messages # views: :messages, :disc, :multiple_hits, :rip_status, :summary
    @tray_open = false
    @rubyripper = nil
    @rubyripperThread = nil
  end

  def start
    @prefs.load
    @messages.welcome
    @current_view = :messages

    # Start scanning disc automatically on start, like GTK version does
    scanDisc

    loop do
      # 1. Process all pending queue events
      process_queue

      # 2. Draw and handle input for the current view
      case @current_view
      when :messages
        @messages.draw
        if STDIN.ready?
          key, _ = TUIKeyHandler.read_key
          handle_messages_key(key)
        end
      when :disc
        @disc.draw
        if STDIN.ready?
          key, _ = TUIKeyHandler.read_key
          handle_disc_key(key)
        end
      when :rip_status
        # Pass control to RipStatus rendering loop
        @rip_status.start(@rubyripper, @rubyripperThread)
        if @rip_status.finished
          show_summary(@rip_status.success)
        else
          @current_view = :disc
        end
      when :summary
        @summary.start
        @current_view = :disc
      when :multiple_hits
        @multiple_hits.start
        # It chooses a hit and calls update('scan_disc_finished'), 
        # which will be processed in next iteration's process_queue.
      end

      sleep 0.1
    end
  end

  def continueRip
    updateInterfaceAndStartRip
  end

  private

  def process_queue
    until @update_queue.empty?
      modus, value = @update_queue.pop
      case modus
      when "error"
        displayErrorMessage(value)
      when "error_msg_end"
        @current_view = :disc
      when "scan_disc_finished"
        scanDiscResults
      when "scan_disc_metadata_multiple_records"
        showMultipleRecordsSelection
      end
    end
  end

  def displayErrorMessage(message)
    @messages.showMessage(message)
    @current_view = :messages
    Thread.new do
      sleep(5)
      update("error_msg_end")
    end
  end

  def scanDiscResults
    if @disc.error.nil?
      @current_view = :disc
    else
      @messages.showError(@disc.error)
      @current_view = :messages
    end
  end

  def showMultipleRecordsSelection
    meta_data_type = @disc.disc.metadata.class.to_s
    if meta_data_type == 'MusicBrainz' || meta_data_type == 'Freedb'
      require 'rubyripper/tui/tuiMultipleHits'
      @multiple_hits = TUIMultipleHits.new(@disc.disc.metadata, self)
      @current_view = :multiple_hits
    else
      puts "ERROR: Unknown metadata type, check code!"
      update('scan_disc_finished')
    end
  end

  def show_summary(success)
    require 'rubyripper/tui/tuiSummary'
    @summary = TUISummary.new(self, @rubyripper.fileScheme, @rubyripper.summary, success)
    @current_view = :summary
    @rubyripper = nil
  end

  # Check configuration and kick off ripping
  def startRip
    @disc.save
    require 'rubyripper/rubyripper'
    @rubyripper = Rubyripper.new(self, @disc.disc, @disc.selection)

    errors = @rubyripper.checkConfiguration
    if errors.empty?
      updateInterfaceAndStartRip
    else
      showErrors(errors)
    end
  end

  def updateInterfaceAndStartRip
    @current_view = :rip_status
    @rip_status.reset
    @rubyripperThread = Thread.new do
      @rubyripper.startRip
    end
  end

  def showErrors(errors)
    text = ''
    text << _("Please solve the following configuration errors first:") + "\n"
    errors.each do |error|
      text << '  > ' + Errors.send(error[0], error[1]) + "\n"
    end
    update("error", text)
  end

  def refreshDisc
    cancelTocScan
    @messages.refreshDisc
    @current_view = :messages
    scanDisc
  end

  def scanDisc
    @disc.refresh
  end

  def handleTray
    if @tray_open
      closeDrive
      scanDisc
    else
      cancelTocScan
      openDrive
      askForDisc
    end
  end

  def openDrive
    @tray_open = true
    @messages.openTray
    @current_view = :messages
    @deps.eject(@prefs.cdrom)
  end

  def askForDisc
    @messages.askForDisc
  end

  def closeDrive
    @tray_open = false
    @messages.closeTray
    @current_view = :messages
    @deps.closeTray(@prefs.cdrom)
  end

  def cancelTocScan
    `killall cdrdao 2>&1`
  end

  def exit_app
    `killall cdparanoia 2>&1`
    `killall cdrdao 2>&1`
    TUIHelpers.clear_screen
    puts TUIHelpers.color(:muted, _("Goodbye!"))
    exit(0)
  end

  def handle_messages_key(key)
    case key
    when :f2
      refreshDisc
    when :f3
      handleTray
    when :f4
      @preferences.start
    when :f10
      exit_app
    end
  end

  def handle_disc_key(key)
    case key
    when :f2
      @disc.edit_metadata
    when :f3
      @disc.select_tracks
    when :f4
      @preferences.start
    when :f5
      startRip
    when :f10
      exit_app
    end
  end

  # Callback implementation for Rubyripper and other subsystems
  def update(modus, value = false)
    @update_queue << [modus, value]
  end
end
