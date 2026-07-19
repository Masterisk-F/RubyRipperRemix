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

require 'rubyripper/base'
require 'rubyripper/errors'
require 'rubyripper/cli/cliArguments'
require 'rubyripper/cli/cliDisc'
require 'rubyripper/cli/cliTracklist'

# CommandLineInterface is defined in bin/rubyripper_cli,
# which is not in the lib load path. Load it by explicit path.
# Load by absolute path: require/require_relative cannot resolve files without .rb extension.
load File.expand_path('../../bin/rubyripper_cli', File.dirname(__FILE__))

describe CommandLineInterface do
  let(:out) {StringIO.new}
  let(:int) {double('CliGetInt').as_null_object}
  let(:cli_disc) {double('CliDisc').as_null_object}
  let(:cli_prefs) {double('CliPreferences').as_null_object}

  before do
    # CliTracklist.new (called during option 2 at line 133) resolves
    # Preferences::Main.instance when prefs is not injected.
    # In spec mode ($run_specs = true), Singleton is excluded, so define instance here.
    prefs_instance = double('PreferencesMain').as_null_object
    allow(prefs_instance).to receive(:image).and_return(false)
    allow(Preferences::Main).to receive(:instance).and_return(prefs_instance)
  end

  def setup_cli(cli_disc: nil, int: nil, prefs: nil)
    CommandLineInterface.new(nil, out, prefs || cli_prefs, cli_disc || self.cli_disc, int || self.int)
  end

  context "When option 2 (rescan) is selected with a scan error" do
    it "should display the scan error" do
      # Stub @int to return 2 (rescan) then 99 (exit main menu)
      expect(int).to receive(:get).with("Please type the number of your choice", 99)
        .and_return(2, 99)

      # CliDisc with non-nil error (simulating a failed scan)
      allow(cli_disc).to receive(:error).and_return([:noDiscYet, '3'])
      allow(cli_disc).to receive(:tracks).and_return({1 => 'Track 1'})
      allow(cli_disc).to receive(:cd).and_return(double('Disc').as_null_object)

      cli = setup_cli(cli_disc: cli_disc, int: int)

      expect { cli.send(:loopMainMenu) }.to output(/Error/).to_stdout
    end
  end
end
