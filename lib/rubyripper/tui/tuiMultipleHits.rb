require 'tty-table'
require 'tty-prompt'
require 'rubyripper/tui/tuiHelpers'

class TUIMultipleHits
  include GetText
  GetText.bindtextdomain("rubyripper")

  def initialize(metadata, main_instance)
    @metadata = metadata
    @ui = main_instance
    @prompt = TTY::Prompt.new
  end

  # Process and select the correct hit
  def start
    TUIHelpers.clear_screen
    TUIHelpers.draw_header

    choices = @metadata.getChoices
    
    # Check if the choices elements are XML (MusicBrainz) or strings (Gnudb)
    is_musicbrainz = choices.first.respond_to?(:elements)

    if is_musicbrainz
      puts TUIHelpers.color(:title, _("Multiple MusicBrainz releases found. Which one would you prefer?"))
      puts ""

      headers = ["#", _("Title"), _("Date"), _("Country"), _("Barcode")]
      rows = []
      choices.each_with_index do |release, idx|
        title = release.elements["title"] ? release.elements["title"].text : _("Unknown title")
        date = release.elements["date"] ? release.elements["date"].text : _("Unknown date")
        country = release.elements["country"] ? release.elements["country"].text : _("Unknown country")
        barcode = release.elements["barcode"] ? release.elements["barcode"].text : _("Unknown barcode")
        rows << [(idx + 1).to_s, title, date, country, barcode]
      end

      table = TTY::Table.new(headers, rows)
      puts table.render(:ascii, padding: [0, 1])
      puts ""

      # Map to selection menu
      options = {}
      choices.each_with_index do |release, idx|
        title = release.elements["title"] ? release.elements["title"].text : _("Unknown title")
        date = release.elements["date"] ? release.elements["date"].text : _("Unknown date")
        options["#{idx + 1}. #{title} (#{date})"] = idx
      end
    else
      puts TUIHelpers.color(:title, _("Multiple Gnudb hits found. Which one would you prefer?"))
      puts ""

      choices.each_with_index do |hit, idx|
        puts "#{idx + 1}. #{hit}"
      end
      puts ""

      options = {}
      choices.each_with_index do |hit, idx|
        options["#{idx + 1}. #{hit}"] = idx
      end
    end

    selected_index = @prompt.select(_("Select release:"), options)
    
    # Save selection
    @metadata.choose(selected_index)
    @ui.update('scan_disc_finished')
  end
end
