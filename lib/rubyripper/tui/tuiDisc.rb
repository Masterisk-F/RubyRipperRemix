require 'tty-table'
require 'tty-prompt'
require 'rubyripper/disc/disc'
require 'rubyripper/tui/tuiHelpers'

class TUIDisc
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :disc, :selection, :error, :md

  def initialize(gui)
    @ui = gui
    @disc = nil
    @md = nil
    @selection = []
    @error = nil
    @prompt = TTY::Prompt.new
  end

  def start
    refresh_disc
  end

  def refresh
    refresh_disc
  end

  def refresh_disc
    @selection = []
    @error = nil
    @disc = Disc.new
    
    # We will let the app run the scan in a background thread to match GUI architecture
    Thread.new do
      @disc.scan
      if @disc.status == 'ok'
        @md = @disc.metadata
        @selection = (1..@disc.audiotracks).to_a
        ui_update_msg = 'scan_disc_finished'
        ui_update_msg = 'scan_disc_metadata_multiple_records' if @md.status == 'multipleRecords'
      else
        @error = @disc.error
        ui_update_msg = 'scan_disc_finished'
      end
      @ui.update(ui_update_msg)
    end
  end

  # Save updates and trigger freedb/local cache write
  def save
    return unless @disc && @md
    # We update metadata directly since we edit in-place, but let's notify the disc to save
    @disc.save
  end

  # Draw the disc info screen
  def draw
    return unless @disc && @md

    TUIHelpers.clear_screen
    TUIHelpers.draw_header

    # Disc info
    disc_info = [
      TUIHelpers.color(:title, _("Disc Info")),
      "#{_('Artist:')}  #{@md.artist}",
      "#{_('Album:')}   #{@md.album}",
      "#{_('Genre:')}   #{@md.genre}       #{_('Year:')} #{@md.year}",
      "Various: [#{@md.various? ? '*' : ' '}]"
    ]
    
    # Table header
    headers = [ _("Rip"), _("Track"), _("Title") ]
    headers << _("Artist") if @md.various?
    headers << _("Length")

    rows = []
    (1..@disc.audiotracks).each do |track|
      row = [
        @selection.include?(track) ? "[x]" : "[ ]",
        track.to_s,
        @md.trackname(track)
      ]
      row << @md.getVarArtist(track) if @md.various?
      row << @disc.getLengthText(track)
      rows << row
    end

    table = TTY::Table.new(headers, rows)
    table_str = table.render(:ascii, padding: [0, 1])

    # Put it all in a frame box
    box_content = disc_info.join("\n") + "\n\n" + TUIHelpers.color(:title, _("Track List (#{@disc.audiotracks} tracks, #{@disc.playtime})")) + "\n" + table_str
    
    # Check if we should display MusicBrainz submit URL
    if @disc.musicbrainz_failed
      box_content << "\n\n" + TUIHelpers.color(:muted, _("Submit DiscID to MusicBrainz via : %s") % [@disc.musicbrainzSubmitURL])
    end

    # Determine heights dynamically based on tracks
    box_height = [18, 10 + @disc.audiotracks].max
    
    box = TTY::Box.frame(
      width: 80,
      height: box_height,
      padding: [1, 2],
      style: {
        border: {
          fg: :cyan
        }
      }
    ) { box_content }
    puts box

    # Footer actions
    footer_actions = [
      { key: "F2", label: _("Edit Metadata") },
      { key: "F3", label: _("Select Tracks") },
      { key: "F4", label: _("Preferences") },
      { key: "F5", label: _("Rip cd now!") },
      { key: "F10", label: _("Exit") }
    ]
    TUIHelpers.draw_footer(footer_actions)
  end

  # Interactive Metadata editing mode
  def edit_metadata
    loop do
      TUIHelpers.clear_screen
      TUIHelpers.draw_header
      puts TUIHelpers.color(:title, _("Edit Disc Info"))
      puts ""

      choices = {
        "1. Artist: #{@md.artist}" => :artist,
        "2. Album: #{@md.album}" => :album,
        "3. Genre: #{@md.genre}" => :genre,
        "4. Year: #{@md.year}" => :year,
        "5. Various Artists: [#{@md.various? ? '*' : ' '}]" => :various,
        "6. Edit Track Names" => :tracks,
        "99. Back" => :back
      }

      action = @prompt.select(_("Select field to edit:"), choices)
      case action
      when :artist
        @md.artist = @prompt.ask(_("Artist:"), default: @md.artist)
      when :album
        @md.album = @prompt.ask(_("Album:"), default: @md.album)
      when :genre
        @md.genre = @prompt.ask(_("Genre:"), default: @md.genre)
      when :year
        @md.year = @prompt.ask(_("Year:"), default: @md.year)
      when :various
        if @md.various?
          @md.unmarkVarArtist
        else
          @md.markVarArtist
        end
      when :tracks
        edit_track_names
      when :back
        save
        break
      end
    end
  end

  # Edit individual track names (and artists if compilation)
  def edit_track_names
    loop do
      TUIHelpers.clear_screen
      TUIHelpers.draw_header
      puts TUIHelpers.color(:title, _("Edit Track Info"))
      puts ""

      choices = {}
      (1..@disc.audiotracks).each do |track|
        label = "#{track}. #{@md.trackname(track)}"
        label << " (Artist: #{@md.getVarArtist(track)})" if @md.various?
        choices[label] = track
      end
      choices["99. Back"] = :back

      track = @prompt.select(_("Select track to edit:"), choices)
      break if track == :back

      # Ask for track name
      name = @prompt.ask(_("Track name:"), default: @md.trackname(track))
      @md.setTrackname(track, name)

      # Ask for track artist if compilation
      if @md.various?
        artist = @prompt.ask(_("Artist:"), default: @md.getVarArtist(track))
        @md.setVarArtist(track, artist)
      end
    end
  end

  # Interactive Track selection mode
  def select_tracks
    TUIHelpers.clear_screen
    TUIHelpers.draw_header
    puts TUIHelpers.color(:title, _("Select Tracks to Rip"))
    puts ""

    choices = {}
    (1..@disc.audiotracks).each do |track|
      choices["Track #{track}: #{@md.trackname(track)}"] = track
    end

    @selection = @prompt.multi_select(
      _("Use Space to toggle, Enter to confirm:"),
      choices,
      default: @selection
    )
  end
end
