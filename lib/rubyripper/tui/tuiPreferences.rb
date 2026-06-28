require 'rubyripper/preferences/main'
require 'rubyripper/tui/tuiHelpers'
require 'rubyripper/tui/tuiKeyHandler'
require 'tty-prompt'

class TUIPreferences
  include GetText
  GetText.bindtextdomain("rubyripper")

  TABS = [:secure, :toc, :codecs, :metadata, :other]
  TAB_LABELS = {
    secure: "Secure Ripping",
    toc: "TOC Analysis",
    codecs: "Codecs",
    metadata: "Metadata",
    other: "Other"
  }

  def initialize(gui)
    @ui = gui
    @prefs = Preferences::Main.instance
    @current_tab = :secure
    @focus = :tabs # :tabs or :items
    @selected_item_idx = 0
    @prompt = TTY::Prompt.new
  end

  def start
    loop do
      draw
      key, _ = TUIKeyHandler.read_key
      break if handle_key(key)
    end
  end

  private

  # Build the items list for the current tab
  def current_items
    case @current_tab
    when :secure
      [
        { key: :cdrom, type: :string, label: _("CD-ROM Device"), val: @prefs.cdrom },
        { key: :offset, type: :int, label: _("CD-ROM Offset"), val: @prefs.offset },
        { key: :padMissingSamples, type: :bool, label: _("Pad missing samples with zeroes"), val: @prefs.padMissingSamples },
        { key: :reqMatchesAll, type: :int, label: _("Match all chunks count"), val: @prefs.reqMatchesAll },
        { key: :reqMatchesErrors, type: :int, label: _("Match erroneous chunks count"), val: @prefs.reqMatchesErrors },
        { key: :maxTries, type: :int, label: _("Max trials (0=unlimited)"), val: @prefs.maxTries },
        { key: :accRip, type: :bool, label: _("AccurateRip validation"), val: @prefs.accRip },
        { key: :ctdb, type: :bool, label: _("CTDB verification (image only)"), val: @prefs.ctdb },
        { key: :verifyEverytime, type: :bool, label: _("Verify every trial"), val: @prefs.verifyEverytime },
        { key: :rippersettings, type: :string, label: _("Extra cd-paranoia parameters"), val: @prefs.rippersettings },
        { key: :eject, type: :bool, label: _("Eject on completion"), val: @prefs.eject },
        { key: :noLog, type: :bool, label: _("Only keep log when errors"), val: @prefs.noLog }
      ]
    when :toc
      [
        { key: :createCue, type: :bool, label: _("Create a cuesheet"), val: @prefs.createCue },
        { key: :image, type: :bool, label: _("Rip to single file (Image)"), val: @prefs.image },
        { key: :ripHiddenAudio, type: :bool, label: _("Rip hidden audio sectors"), val: @prefs.ripHiddenAudio },
        { key: :minLengthHiddenTrack, type: :int, label: _("Min seconds to be hidden track"), val: @prefs.minLengthHiddenTrack },
        { key: :preGaps, type: :select, choices: ['append', 'prepend'], label: _("Append or prepend audio"), val: @prefs.preGaps },
        { key: :preEmphasis, type: :select, choices: ['cue', 'sox'], label: _("Pre-emphasis handling"), val: @prefs.preEmphasis }
      ]
    when :codecs
      [
        { key: :flac, type: :bool, label: _("FLAC"), val: @prefs.flac },
        { key: :settingsFlac, type: :string, label: _("FLAC options"), val: @prefs.settingsFlac },
        { key: :vorbis, type: :bool, label: _("Vorbis"), val: @prefs.vorbis },
        { key: :settingsVorbis, type: :string, label: _("Oggenc options"), val: @prefs.settingsVorbis },
        { key: :mp3, type: :bool, label: _("LAME MP3"), val: @prefs.mp3 },
        { key: :settingsMp3, type: :string, label: _("LAME options"), val: @prefs.settingsMp3 },
        { key: :nero, type: :bool, label: _("Nero AAC"), val: @prefs.nero },
        { key: :settingsNero, type: :string, label: _("Nero options"), val: @prefs.settingsNero },
        { key: :fraunhofer, type: :bool, label: _("Fraunhofer AAC"), val: @prefs.fraunhofer },
        { key: :settingsFraunhofer, type: :string, label: _("Fraunhofer options"), val: @prefs.settingsFraunhofer },
        { key: :wavpack, type: :bool, label: _("WavPack"), val: @prefs.wavpack },
        { key: :settingsWavpack, type: :string, label: _("WavPack options"), val: @prefs.settingsWavpack },
        { key: :opus, type: :bool, label: _("Opus"), val: @prefs.opus },
        { key: :settingsOpus, type: :string, label: _("Opus options"), val: @prefs.settingsOpus },
        { key: :wav, type: :bool, label: _("WAVE"), val: @prefs.wav },
        { key: :other, type: :bool, label: _("Other codec"), val: @prefs.other },
        { key: :settingsOther, type: :string, label: _("Commandline passed"), val: @prefs.settingsOther },
        { key: :playlist, type: :bool, label: _("Playlist support"), val: @prefs.playlist },
        { key: :maxThreads, type: :int, label: _("Max extra encoding threads"), val: @prefs.maxThreads },
        { key: :normalizer, type: :select, choices: ['none', 'replaygain', 'normalize'], label: _("Normalize program"), val: @prefs.normalizer },
        { key: :gain, type: :select, choices: ['album', 'track'], label: _("Normalize modus"), val: @prefs.gain }
      ]
    when :metadata
      [
        { key: :metadataProvider, type: :select, choices: ['none', 'gnudb', 'musicbrainz'], label: _("Metadata provider"), val: @prefs.metadataProvider },
        { key: :firstHit, type: :bool, label: _("Gnudb use first hit"), val: @prefs.firstHit },
        { key: :site, type: :string, label: _("Gnudb server"), val: @prefs.site },
        { key: :username, type: :string, label: _("Gnudb username"), val: @prefs.username },
        { key: :hostname, type: :string, label: _("Gnudb hostname"), val: @prefs.hostname },
        { key: :preferMusicBrainzCountries, type: :string, label: _("MusicBrainz preferred countries"), val: @prefs.preferMusicBrainzCountries },
        { key: :preferMusicBrainzDate, type: :select, choices: ['earlier', 'later', 'no'], label: _("MusicBrainz preferred date"), val: @prefs.preferMusicBrainzDate },
        { key: :useEarliestDate, type: :bool, label: _("MusicBrainz use earliest date"), val: @prefs.useEarliestDate }
      ]
    when :other
      [
        { key: :basedir, type: :string, label: _("Base directory"), val: @prefs.basedir },
        { key: :namingNormal, type: :string, label: _("Normal files scheme"), val: @prefs.namingNormal },
        { key: :namingVarious, type: :string, label: _("Various files scheme"), val: @prefs.namingVarious },
        { key: :namingImage, type: :string, label: _("Image files scheme"), val: @prefs.namingImage },
        { key: :noSpaces, type: :bool, label: _("Replace spaces with underscores"), val: @prefs.noSpaces },
        { key: :noCapitals, type: :bool, label: _("Downsize all capital letters"), val: @prefs.noCapitals },
        { key: :editor, type: :string, label: _("Log file viewer"), val: @prefs.editor },
        { key: :filemanager, type: :string, label: _("File manager"), val: @prefs.filemanager },
        { key: :uiType, type: :select, choices: ['tui', 'cli'], label: _("User Interface Type"), val: @prefs.uiType },
        { key: :verbose, type: :bool, label: _("Verbose mode"), val: @prefs.verbose },
        { key: :debug, type: :bool, label: _("Debug mode"), val: @prefs.debug }
      ]
    end
  end

  def draw
    TUIHelpers.clear_screen
    TUIHelpers.draw_header

    # Tab bar rendering
    tab_strs = TABS.map do |tab|
      label = TAB_LABELS[tab]
      if tab == @current_tab
        if @focus == :tabs
          TUIHelpers.pastel.inverse.bold.cyan(" [ #{label} ] ")
        else
          TUIHelpers.pastel.bold.cyan(" [ #{label} ] ")
        end
      else
        "   #{label}   "
      end
    end.join("")

    # Preferences items rendering
    items = current_items
    items_strs = items.map.with_index do |item, idx|
      cursor = (idx == @selected_item_idx && @focus == :items) ? TUIHelpers.color(:highlight, "> ") : "  "
      
      val_str = case item[:type]
                when :bool
                  item[:val] ? TUIHelpers.pastel.green("[*]") : "[ ]"
                when :select
                  TUIHelpers.pastel.yellow("[ #{item[:val]} ]")
                else
                  TUIHelpers.pastel.yellow("[ #{item[:val]} ]")
                end
      
      "#{cursor}#{item[:label]}: #{val_str}"
    end

    box_content = tab_strs + "\n\n" + items_strs.join("\n")
    
    box_height = [20, 10 + items.size].max
    box = TTY::Box.frame(
      width: 80,
      height: box_height,
      padding: [1, 2],
      title: { top_left: TUIHelpers.color(:title, _(" Preferences ")) },
      style: {
        border: {
          fg: :cyan
        }
      }
    ) { box_content }
    puts box

    footer_actions = [
      { key: "←/→", label: _("Change Tab") },
      { key: "↑/↓", label: _("Select Item") },
      { key: "Enter", label: _("Edit/Toggle") },
      { key: "s", label: _("Save Settings") },
      { key: "F10", label: _("Back to Disc Info") }
    ]
    TUIHelpers.draw_footer(footer_actions)
  end

  # Handle key events on preferences screen
  # Returns true if we should exit the preferences screen
  def handle_key(key)
    case key
    when :f10, :escape
      return true
    when :left
      if @focus == :tabs
        curr_idx = TABS.index(@current_tab)
        @current_tab = TABS[(curr_idx - 1) % TABS.size]
      end
    when :right
      if @focus == :tabs
        curr_idx = TABS.index(@current_tab)
        @current_tab = TABS[(curr_idx + 1) % TABS.size]
      end
    when :up
      if @focus == :items
        if @selected_item_idx > 0
          @selected_item_idx -= 1
        else
          @focus = :tabs
        end
      end
    when :down
      if @focus == :tabs
        @focus = :items
        @selected_item_idx = 0
      elsif @focus == :items
        items_count = current_items.size
        if @selected_item_idx < items_count - 1
          @selected_item_idx += 1
        end
      end
    when :enter
      if @focus == :tabs
        @focus = :items
        @selected_item_idx = 0
      elsif @focus == :items
        edit_selected_item
      end
    when 's', 'S'
      # Validate and save preferences
      if @prefs.reqMatchesAll > @prefs.reqMatchesErrors
        TUIHelpers.clear_screen
        puts TUIHelpers.color(:error, _("Validation Error: 'Match all chunks' count must be less than or equal to 'Match erroneous chunks' count!"))
        sleep(2)
      else
        @prefs.save
        TUIHelpers.clear_screen
        puts TUIHelpers.color(:success, _("Preferences saved successfully."))
        sleep(1.5)
      end
    end
    false
  end

  # Prompt the user to edit the selected preference item
  def edit_selected_item
    item = current_items[@selected_item_idx]
    case item[:type]
    when :bool
      new_val = !item[:val]
      @prefs.send("#{item[:key]}=", new_val)
    when :select
      new_val = @prompt.select(item[:label] + ":", item[:choices], default: item[:val])
      @prefs.send("#{item[:key]}=", new_val)
    when :int
      new_val = @prompt.ask(item[:label] + ":", default: item[:val], convert: :int)
      @prefs.send("#{item[:key]}=", new_val) if new_val
    when :string
      new_val = @prompt.ask(item[:label] + ":", default: item[:val].to_s)
      @prefs.send("#{item[:key]}=", new_val) if new_val
    end
  end
end
