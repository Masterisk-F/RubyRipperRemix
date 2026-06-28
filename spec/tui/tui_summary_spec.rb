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
require 'rubyripper/tui/tuiSummary'
require 'rubyripper/tui/tuiHelpers'

describe TUISummary do
  let(:gui) { instance_double('TUIApp').as_null_object }
  let(:scheme) { double('FileScheme').as_null_object }
  subject(:summary) { TUISummary.new(gui, scheme, 'Summary text', true) }

  before(:each) do
    allow(Preferences::Main).to receive(:instance).and_return(double('Preferences::Main').as_null_object)
    allow($stdout).to receive(:write)
    allow(TTY::Screen).to receive(:width).and_return(80)
    allow(TTY::Screen).to receive(:height).and_return(24)
  end

  describe '#initialize' do
    it 'stores success status' do
      expect(summary.instance_variable_get(:@success)).to be true
    end

    it 'stores summary text' do
      expect(summary.instance_variable_get(:@summary_text)).to eq('Summary text')
    end
  end

  describe '#draw' do
    context 'when successful' do
      it 'shows success message' do
        s = StringIO.new
        old = $stdout
        $stdout = s
        summary.draw
        s.rewind
        expect(s.read).to include('successfully')
      ensure
        $stdout = old
      end
    end

    context 'when failed' do
      subject(:failed_summary) { TUISummary.new(gui, scheme, 'Error summary', false) }

      it 'shows error message' do
        s = StringIO.new
        old = $stdout
        $stdout = s
        failed_summary.draw
        s.rewind
        expect(s.read).to include('problems')
      ensure
        $stdout = old
      end
    end
  end

  describe '#start' do
    it 'returns to main menu when back chosen' do
      prompt = summary.instance_variable_get(:@prompt)
      allow(prompt).to receive(:select).and_return(:back)
      expect { summary.start }.not_to raise_error
    end

    it 'opens log file when chosen' do
      allow(scheme).to receive(:getDir).and_return('/tmp')
      allow(File).to receive(:exist?).and_return(true)
      prompt = summary.instance_variable_get(:@prompt)
      allow(prompt).to receive(:select).and_return(:open_log, :back)
      allow(summary).to receive(:system).and_return(true)
      summary.start
    end

    it 'shows error when log file missing' do
      allow(scheme).to receive(:getDir).and_return('/tmp')
      allow(File).to receive(:exist?).and_return(false)
      prompt = summary.instance_variable_get(:@prompt)
      allow(prompt).to receive(:select).and_return(:open_log, :back)
      expect { summary.start }.to output(/Log file not found/).to_stdout
    end

    it 'opens destination directory when chosen' do
      allow(scheme).to receive(:getDir).and_return('/tmp')
      allow(Dir).to receive(:exist?).and_return(true)
      prompt = summary.instance_variable_get(:@prompt)
      allow(prompt).to receive(:select).and_return(:open_dir, :back)
      allow(summary).to receive(:system).and_return(true)
      summary.start
    end
  end
end
