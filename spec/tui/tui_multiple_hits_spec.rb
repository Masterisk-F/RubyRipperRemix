#!/usr/bin/env ruby
#    RubyRipperRemix - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2025  Masterisk-F
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
#

require 'rspec'
require 'rubyripper/tui/tuiMultipleHits'
require 'rubyripper/tui/tuiHelpers'

describe TUIMultipleHits do
  let(:metadata) { double('Metadata').as_null_object }
  let(:gui) { double('TUIApp').as_null_object }
  subject(:multiple_hits) { TUIMultipleHits.new(metadata, gui) }

  before(:each) do
    allow($stdout).to receive(:write)
  end

  context 'with Gnudb-style choices (strings)' do
    before(:each) do
      allow(metadata).to receive(:getChoices).and_return(['Hit One', 'Hit Two', 'Hit Three'])
    end

    it 'displays choices and calls choose with selection' do
      prompt = multiple_hits.instance_variable_get(:@prompt)
      allow(prompt).to receive(:select).and_return(1)
      expect(metadata).to receive(:choose).with(1)
      expect(gui).to receive(:update).with('scan_disc_finished')
      multiple_hits.start
    end
  end

  context 'with MusicBrainz-style choices (XML elements)' do
    let(:release) { double('REXML::Element') }
    let(:elements) { { 'title' => double('title'), 'date' => double('date'), 'country' => double('country'), 'barcode' => double('barcode') } }

    before(:each) do
      allow(release).to receive(:elements).and_return(elements)
      allow(elements['title']).to receive(:text).and_return('Test Release')
      allow(elements['date']).to receive(:text).and_return('2024')
      allow(elements['country']).to receive(:text).and_return('US')
      allow(elements['barcode']).to receive(:text).and_return('1234567890')
      allow(metadata).to receive(:getChoices).and_return([release])
    end

    it 'displays a table and calls choose' do
      prompt = multiple_hits.instance_variable_get(:@prompt)
      allow(prompt).to receive(:select).and_return(0)
      expect(metadata).to receive(:choose).with(0)
      expect(gui).to receive(:update).with('scan_disc_finished')
      multiple_hits.start
    end
  end
end
