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
require 'rubyripper/preferences/data'
require 'rubyripper/preferences/setDefaults'

describe Preferences::Data do
  let(:data) { Preferences::Data.new }

  context 'when accessing preference properties' do
    it 'should have the uiType accessor' do
      data.uiType = 'tui'
      expect(data.uiType).to eq('tui')
    end

    it 'should have the uiType accessor default to nil before SetDefaults' do
      expect(data.uiType).to be_nil
    end
  end
end

describe Preferences::SetDefaults do
  let(:prefs) { double('Preferences::Main').as_null_object }
  let(:pref_data) { Preferences::Data.new }
  let(:deps) { double('Dependency').as_null_object }

  before(:each) do
    expect(prefs).to receive(:data).at_least(:once).and_return pref_data
  end

  context 'when setting default values' do
    it 'should set uiType default to tui' do
      Preferences::SetDefaults.new(deps, prefs)
      expect(pref_data.uiType).to eq('tui')
    end
  end
end
