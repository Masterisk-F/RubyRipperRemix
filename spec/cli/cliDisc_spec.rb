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

require 'rubyripper/cli/cliDisc'

describe CliDisc do
  let(:out) {StringIO.new}
  let(:int) {double('CliGetInt').as_null_object}
  let(:bool) {double('CliGetBool').as_null_object}
  let(:string) {double('CliGetString').as_null_object}
  let(:prefs) {double('Preferences::Main').as_null_object}

  def setup_cli_disc
    CliDisc.new(out, int, bool, string, prefs)
  end

  context "When refreshing the disc" do
    it "should create a new Disc instance on refresh" do
      first_disc = double('Disc').as_null_object
      second_disc = double('Disc').as_null_object

      expect(Disc).to receive(:new).and_return(first_disc, second_disc)

      cli_disc = setup_cli_disc
      expect(cli_disc.cd).to eq(first_disc)

      expect(second_disc).to receive(:scan)
      cli_disc.send(:refreshDisc)
      expect(cli_disc.cd).to eq(second_disc)
    end
  end
end
