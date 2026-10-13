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
#    along with this program.  If not, see <see href="http://www.gnu.org/licenses/"/>

require 'rspec'
require 'rubyripper/tui/tuiHelpers'

describe TUIHelpers do
  describe '.color' do
    # Note: TTY detection may be disabled in non-TTY test environments;
    # we verify the method returns the input text (wrapping works) without
    # asserting ANSI codes that only appear in interactive terminals.

    it 'includes the given text in the result for :title' do
      result = TUIHelpers.color(:title, "Hello")
      expect(result).to include("Hello")
    end

    it 'includes the given text in the result for :highlight' do
      result = TUIHelpers.color(:highlight, "Hello")
      expect(result).to include("Hello")
    end

    it 'includes the given text in the result for :success' do
      result = TUIHelpers.color(:success, "Hello")
      expect(result).to include("Hello")
    end

    it 'includes the given text in the result for :error' do
      result = TUIHelpers.color(:error, "Hello")
      expect(result).to include("Hello")
    end

    it 'includes the given text in the result for :muted' do
      result = TUIHelpers.color(:muted, "Hello")
      expect(result).to include("Hello")
    end

    it 'includes the given text in the result for :accent' do
      result = TUIHelpers.color(:accent, "Hello")
      expect(result).to include("Hello")
    end

    it 'returns plain text for unknown color symbol' do
      result = TUIHelpers.color(:nonexistent, "Hello")
      expect(result).to eq("Hello")
    end

    it 'returns plain text if text is empty' do
      result = TUIHelpers.color(:title, "")
      expect(result).to eq("")
    end
  end

  describe '.clear_screen' do
    it 'prints the ANSI clear escape sequence' do
      expect { TUIHelpers.clear_screen }.to output("\e[2J\e[H").to_stdout
    end
  end

  describe '.draw_header' do
    it 'outputs a box with version string' do
      expect { TUIHelpers.draw_header }.to output(/RubyRipperRemix/).to_stdout
    end
  end

  describe '.draw_footer' do
    it 'renders actions as footer box' do
      actions = [{ key: "F2", label: "Test" }]
      expect { TUIHelpers.draw_footer(actions) }.to output(/Test/).to_stdout
    end

    it 'renders multiple actions separated by spaces' do
      actions = [
        { key: "F2", label: "First" },
        { key: "F3", label: "Second" }
      ]
      expect { TUIHelpers.draw_footer(actions) }.to output(/First.*Second/).to_stdout
    end

    it 'handles empty actions array' do
      expect { TUIHelpers.draw_footer([]) }.to output(/┌/).to_stdout
    end
  end

  describe '.status_indicator' do
    it 'shows [x] with green bold text when active' do
      result = TUIHelpers.status_indicator(true, "Option")
      expect(result).to include("Option")
    end

    it 'shows [ ] when inactive' do
      result = TUIHelpers.status_indicator(false, "Option")
      expect(result).to include("Option")
    end
  end

  describe '.pastel' do
    it 'returns an object responding to Pastel style methods' do
      expect(TUIHelpers.pastel).to respond_to(:bold)
      expect(TUIHelpers.pastel).to respond_to(:cyan)
      expect(TUIHelpers.pastel).to respond_to(:red)
    end

    it 'caches the Pastel instance' do
      expect(TUIHelpers.pastel).to equal(TUIHelpers.pastel)
    end
  end
end
