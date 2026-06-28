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
require 'rubyripper/tui/tuiRipStatus'
require 'rubyripper/tui/tuiKeyHandler'

describe TUIRipStatus do
  let(:gui) { instance_double('TUIApp').as_null_object }
  subject(:rip_status) { TUIRipStatus.new(gui) }

  describe '#reset' do
    it 'clears logs' do
      rip_status.instance_variable_set(:@logs, ['some log'])
      rip_status.reset
      expect(rip_status.logs).to eq([])
    end

    it 'resets ripping progress to 0' do
      rip_status.instance_variable_set(:@ripping_progress, 0.5)
      rip_status.reset
      expect(rip_status.ripping_progress).to eq(0.0)
    end

    it 'resets encoding progress to 0' do
      rip_status.instance_variable_set(:@encoding_progress, 0.8)
      rip_status.reset
      expect(rip_status.encoding_progress).to eq(0.0)
    end

    it 'resets finished to false' do
      rip_status.instance_variable_set(:@finished, true)
      rip_status.reset
      expect(rip_status.finished).to be false
    end

    it 'resets success to nil' do
      rip_status.instance_variable_set(:@success, true)
      rip_status.reset
      expect(rip_status.success).to be_nil
    end
  end

  describe '#updateProgress' do
    it 'updates ripping progress' do
      rip_status.updateProgress('ripping', 0.5)
      expect(rip_status.ripping_progress).to eq(0.5)
    end

    it 'updates encoding progress' do
      rip_status.updateProgress('encoding', 0.75)
      expect(rip_status.encoding_progress).to eq(0.75)
    end
  end

  describe '#logChange' do
    it 'appends log lines' do
      rip_status.logChange("line1\nline2")
      expect(rip_status.logs.size).to eq(2)
      expect(rip_status.logs[0]).to eq('line1')
      expect(rip_status.logs[1]).to eq('line2')
    end

    it 'skips empty lines' do
      rip_status.logChange("a\n\n\nb")
      expect(rip_status.logs).to eq(['a', 'b'])
    end

    it 'strips trailing whitespace' do
      rip_status.logChange("hello   \n")
      expect(rip_status.logs).to eq(['hello'])
    end
  end

  describe '#cancel_rip' do
    let(:rubyripper) { double('Rubyripper') }

    before(:each) do
      rip_status.instance_variable_set(:@rubyripper, rubyripper)
    end

    it 'sets cancelled to true' do
      allow(rubyripper).to receive(:cancelRip)
      rip_status.send(:cancel_rip)
      expect(rip_status.instance_variable_get(:@cancelled)).to be true
    end

    it 'calls cancelRip on the rubyripper instance' do
      expect(rubyripper).to receive(:cancelRip)
      rip_status.send(:cancel_rip)
    end
  end

  describe '#handle_dir_exists' do
    let(:rubyripper) { double('Rubyripper').as_null_object }

    before(:each) do
      rip_status.instance_variable_set(:@rubyripper, rubyripper)
    end

    it 'prompts and cancels on cancel choice' do
      prompt = rip_status.instance_variable_get(:@prompt)
      allow(prompt).to receive(:select).and_return(:cancel)
      expect(rubyripper).not_to receive(:overwriteDir)
      expect(rubyripper).not_to receive(:postfixDir)
      rip_status.handle_dir_exists('/tmp/test')
    end

    it 'overwrites when chosen' do
      prompt = rip_status.instance_variable_get(:@prompt)
      allow(prompt).to receive(:select).and_return(:overwrite)
      expect(rubyripper).to receive(:overwriteDir)
      expect(gui).to receive(:continueRip)
      rip_status.handle_dir_exists('/tmp/test')
    end

    it 'renames when chosen' do
      prompt = rip_status.instance_variable_get(:@prompt)
      allow(prompt).to receive(:select).and_return(:rename)
      expect(rubyripper).to receive(:postfixDir)
      expect(gui).to receive(:continueRip)
      rip_status.handle_dir_exists('/tmp/test')
    end
  end

  describe '#draw' do
    before(:each) do
      allow(TTY::Screen).to receive(:width).and_return(80)
      allow(TTY::Screen).to receive(:height).and_return(24)
    end

    it 'outputs ripping status header' do
      s = StringIO.new
      old = $stdout
      $stdout = s
      rip_status.draw
      s.rewind
      expect(s.read).to include('Ripping Status')
    ensure
      $stdout = old
    end
  end
end
