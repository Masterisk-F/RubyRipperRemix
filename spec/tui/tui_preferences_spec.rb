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
require 'rubyripper/tui/tuiPreferences'
require 'rubyripper/tui/tuiKeyHandler'

describe TUIPreferences do
  let(:gui) { instance_double('TUIApp').as_null_object }
  let(:prefs) { double('Preferences::Main').as_null_object }
  subject(:tui_prefs) { TUIPreferences.new(gui) }

  before(:each) do
    allow(Preferences::Main).to receive(:instance).and_return(prefs)
    allow(prefs).to receive(:reqMatchesAll).and_return(2)
    allow(prefs).to receive(:reqMatchesErrors).and_return(3)
    allow(prefs).to receive(:eject).and_return(false)
    allow(prefs).to receive(:uiType).and_return('tui')
    allow(prefs).to receive(:preGaps).and_return('append')
    allow(prefs).to receive(:normalizer).and_return('none')
    allow(prefs).to receive(:gain).and_return('album')
    allow(prefs).to receive(:metadataProvider).and_return('gnudb')
    allow(prefs).to receive(:preferMusicBrainzDate).and_return('earlier')
    allow($stdout).to receive(:write)
  end

  describe '#initialize' do
    it 'starts on secure tab' do
      expect(tui_prefs.instance_variable_get(:@current_tab)).to eq(:secure)
    end

    it 'starts with focus on tabs' do
      expect(tui_prefs.instance_variable_get(:@focus)).to eq(:tabs)
    end

    it 'starts with selected item index 0' do
      expect(tui_prefs.instance_variable_get(:@selected_item_idx)).to eq(0)
    end
  end

  describe '#start' do
    it 'exits on F10' do
      key_handler = class_spy('TUIKeyHandler').as_stubbed_const
      allow(key_handler).to receive(:read_key).and_return([:f10, nil])
      tui_prefs.start
    end

    it 'exits on Escape' do
      key_handler = class_spy('TUIKeyHandler').as_stubbed_const
      allow(key_handler).to receive(:read_key).and_return([:escape, nil])
      tui_prefs.start
    end
  end

  describe 'tab navigation' do
    it 'cycles tabs forward with right key' do
      expect(tui_prefs.instance_variable_get(:@current_tab)).to eq(:secure)
      tui_prefs.send(:handle_key, :right)
      expect(tui_prefs.instance_variable_get(:@current_tab)).to eq(:toc)
      tui_prefs.send(:handle_key, :right)
      expect(tui_prefs.instance_variable_get(:@current_tab)).to eq(:codecs)
    end

    it 'cycles tabs backward with left key' do
      tui_prefs.instance_variable_set(:@current_tab, :codecs)
      tui_prefs.send(:handle_key, :left)
      expect(tui_prefs.instance_variable_get(:@current_tab)).to eq(:toc)
    end

    it 'wraps around when moving past the last tab' do
      tui_prefs.instance_variable_set(:@current_tab, :other)
      tui_prefs.send(:handle_key, :right)
      expect(tui_prefs.instance_variable_get(:@current_tab)).to eq(:secure)
    end
  end

  describe 'focus navigation' do
    it 'moves focus from tabs to items with down key' do
      tui_prefs.send(:handle_key, :down)
      expect(tui_prefs.instance_variable_get(:@focus)).to eq(:items)
    end

    it 'moves focus from items to tabs with up key at top' do
      tui_prefs.instance_variable_set(:@focus, :items)
      tui_prefs.send(:handle_key, :up)
      expect(tui_prefs.instance_variable_get(:@focus)).to eq(:tabs)
    end

    it 'moves selection down within items' do
      tui_prefs.instance_variable_set(:@focus, :items)
      tui_prefs.send(:handle_key, :down)
      expect(tui_prefs.instance_variable_get(:@selected_item_idx)).to eq(1)
    end

    it 'stops at the last item' do
      tui_prefs.instance_variable_set(:@focus, :items)
      tui_prefs.instance_variable_set(:@selected_item_idx, 10)
      tui_prefs.send(:handle_key, :down)
    end

    it 'enter key on tabs moves focus to items' do
      tui_prefs.send(:handle_key, :enter)
      expect(tui_prefs.instance_variable_get(:@focus)).to eq(:items)
    end
  end

  describe 'item editing' do
    before(:each) do
      tui_prefs.instance_variable_set(:@focus, :items)
    end

    it 'toggles boolean values' do
      allow(prefs).to receive(:eject).and_return(false)
      expect(prefs).to receive(:eject=).with(true)
      tui_prefs.instance_variable_set(:@selected_item_idx, 10)
      tui_prefs.send(:edit_selected_item)
    end

    it 'prompts for select-type items' do
      prompt = tui_prefs.instance_variable_get(:@prompt)
      allow(prompt).to receive(:select).and_return('append')
      tui_prefs.instance_variable_set(:@current_tab, :toc)
      tui_prefs.instance_variable_set(:@selected_item_idx, 4)
      expect(prompt).to receive(:select).with(include("Append"), anything, anything)
      tui_prefs.send(:edit_selected_item)
    end

    it 'prompts for int-type items' do
      prompt = tui_prefs.instance_variable_get(:@prompt)
      allow(prompt).to receive(:ask).and_return(42)
      tui_prefs.instance_variable_set(:@selected_item_idx, 1)
      expect(prompt).to receive(:ask).with(include("Offset"), hash_including(:convert))
      tui_prefs.send(:edit_selected_item)
    end

    it 'prompts for string-type items' do
      prompt = tui_prefs.instance_variable_get(:@prompt)
      allow(prompt).to receive(:ask).and_return('/dev/sr0')
      tui_prefs.instance_variable_set(:@selected_item_idx, 0)
      expect(prompt).to receive(:ask).with(include("CD-ROM"), anything)
      tui_prefs.send(:edit_selected_item)
    end
  end

  describe 'save' do
    it 'saves and shows success message when validation passes' do
      allow(prefs).to receive(:reqMatchesAll).and_return(2)
      allow(prefs).to receive(:reqMatchesErrors).and_return(3)
      expect(prefs).to receive(:save)
      tui_prefs.send(:handle_key, 's')
    end

    it 'shows validation error when reqMatchesAll > reqMatchesErrors' do
      allow(prefs).to receive(:reqMatchesAll).and_return(5)
      allow(prefs).to receive(:reqMatchesErrors).and_return(3)
      expect(prefs).not_to receive(:save)
      expect { tui_prefs.send(:handle_key, 's') }.to output(/Validation Error/).to_stdout
    end
  end

  describe 'uiType item' do
    it 'presents uiType in the other tab' do
      items = tui_prefs.send(:current_items)
      allow(tui_prefs).to receive(:current_items).and_call_original
      tui_prefs.instance_variable_set(:@current_tab, :other)
      other_items = tui_prefs.send(:current_items)
      ui_item = other_items.find { |i| i[:key] == :uiType }
      expect(ui_item).not_to be_nil
      expect(ui_item[:type]).to eq(:select)
      expect(ui_item[:choices]).to eq(['tui', 'cli'])
    end
  end

  describe '#draw' do
    before(:each) do
      allow(TTY::Screen).to receive(:width).and_return(80)
      allow(TTY::Screen).to receive(:height).and_return(24)
    end

    it 'outputs content including tab labels' do
      s = StringIO.new
      old = $stdout
      $stdout = s
      tui_prefs.send(:draw)
      s.rewind
      output = s.read
      expect(output).to include('Secure Ripping')
    ensure
      $stdout = old
    end
  end
end
