#!/usr/bin/env ruby
#    RubyRipperRemix - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Masterisk-F
#
#    This file is part of RubyRipperRemix. RubyRipperRemix is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

require 'rubyripper/cli/cliTracklist'

describe CliTracklist do
  let(:out) {StringIO.new}
  let(:int) {double('CliGetInt').as_null_object}
  let(:prefs) {double('Preferences::Main').as_null_object}

  context "When selection is requested without prior user interaction" do
    it "should return all tracks from the disc" do
      cli_disc = double('CliDisc').as_null_object
      expect(cli_disc).to receive(:tracks).and_return({1 => 'Track 1', 2 => 'Track 2', 3 => 'Track 3'})
      tracklist = CliTracklist.new(cli_disc, out, int, prefs)
      expect(tracklist.selection).to eq([1, 2, 3])
    end

    it "should lazily cache the selection after first access" do
      cli_disc = double('CliDisc').as_null_object
      expect(cli_disc).to receive(:tracks).once.and_return({1 => 'a', 2 => 'b'})
      tracklist = CliTracklist.new(cli_disc, out, int, prefs)
      expect(tracklist.selection).to eq([1, 2])
      # second call should use cache, not call tracks again
      expect(tracklist.selection).to eq([1, 2])
    end
  end

  context "When the disc is rescanned" do
    it "should get fresh track selection from the new disc when CliTracklist is recreated" do
      cli_disc = double('CliDisc').as_null_object
      
      # First disc has 5 tracks
      expect(cli_disc).to receive(:tracks).once.and_return({1 => 'Song A', 2 => 'Song B', 3 => 'Song C', 4 => 'Song D', 5 => 'Song E'})
      first_tracklist = CliTracklist.new(cli_disc, out, int, prefs)
      expect(first_tracklist.selection).to eq([1, 2, 3, 4, 5])

      # Simulate a rescan: CliDisc.tracks returns only 3 tracks now
      expect(cli_disc).to receive(:tracks).once.and_return({1 => 'New A', 2 => 'New B', 3 => 'New C'})
      second_tracklist = CliTracklist.new(cli_disc, out, int, prefs)
      
      # The new instance should start fresh with all tracks from the new disc
      expect(second_tracklist.selection).to eq([1, 2, 3])
    end
  end
end
