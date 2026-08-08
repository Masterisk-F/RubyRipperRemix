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
require 'rubyripper/tui/tuiKeyHandler'

describe TUIKeyHandler do
  let(:reader) { instance_double('TTY::Reader').as_null_object }

  before(:each) do
    allow(TTY::Reader).to receive(:new).and_return(reader)
    # Reset the cached reader between tests
    TUIKeyHandler.instance_variable_set(:@reader, nil)
  end

  def stub_keypress(key_name: nil, value: nil)
    event = double('TTY::Reader::Event')
    key = double('TTY::Key')
    allow(key).to receive(:name).and_return(key_name)
    allow(event).to receive(:key).and_return(key)
    allow(event).to receive(:value).and_return(value)
    allow(reader).to receive(:read_keypress).and_return(event)
  end

  describe '.reader' do
    it 'creates a TTY::Reader instance' do
      expect(TTY::Reader).to receive(:new).and_return(reader)
      TUIKeyHandler.reader
    end

    it 'caches the reader instance' do
      first = TUIKeyHandler.reader
      second = TUIKeyHandler.reader
      expect(first).to equal(second)
    end
  end

  describe '.read_key' do
    context 'with arrow keys' do
      it 'maps :up key to :up' do
        stub_keypress(key_name: :up)
        expect(TUIKeyHandler.read_key[0]).to eq(:up)
      end

      it 'maps :down key to :down' do
        stub_keypress(key_name: :down)
        expect(TUIKeyHandler.read_key[0]).to eq(:down)
      end

      it 'maps :left key to :left' do
        stub_keypress(key_name: :left)
        expect(TUIKeyHandler.read_key[0]).to eq(:left)
      end

      it 'maps :right key to :right' do
        stub_keypress(key_name: :right)
        expect(TUIKeyHandler.read_key[0]).to eq(:right)
      end
    end

    context 'with vim-style keys' do
      it 'maps k to :up' do
        stub_keypress(key_name: :k)
        expect(TUIKeyHandler.read_key[0]).to eq(:up)
      end

      it 'maps j to :down' do
        stub_keypress(key_name: :j)
        expect(TUIKeyHandler.read_key[0]).to eq(:down)
      end

      it 'maps h to :left' do
        stub_keypress(key_name: :h)
        expect(TUIKeyHandler.read_key[0]).to eq(:left)
      end

      it 'maps l to :right' do
        stub_keypress(key_name: :l)
        expect(TUIKeyHandler.read_key[0]).to eq(:right)
      end
    end

    context 'with function keys' do
      it 'maps :f1 to :f1' do
        stub_keypress(key_name: :f1)
        expect(TUIKeyHandler.read_key[0]).to eq(:f1)
      end

      it 'maps :f2 to :f2' do
        stub_keypress(key_name: :f2)
        expect(TUIKeyHandler.read_key[0]).to eq(:f2)
      end

      it 'maps :f3 to :f3' do
        stub_keypress(key_name: :f3)
        expect(TUIKeyHandler.read_key[0]).to eq(:f3)
      end

      it 'maps :f4 to :f4' do
        stub_keypress(key_name: :f4)
        expect(TUIKeyHandler.read_key[0]).to eq(:f4)
      end

      it 'maps :f5 to :f5' do
        stub_keypress(key_name: :f5)
        expect(TUIKeyHandler.read_key[0]).to eq(:f5)
      end

      it 'maps :f10 to :f10' do
        stub_keypress(key_name: :f10)
        expect(TUIKeyHandler.read_key[0]).to eq(:f10)
      end
    end

    context 'with control keys' do
      it 'maps :escape to :escape' do
        stub_keypress(key_name: :escape)
        expect(TUIKeyHandler.read_key[0]).to eq(:escape)
      end

      it 'maps :enter to :enter' do
        stub_keypress(key_name: :enter)
        expect(TUIKeyHandler.read_key[0]).to eq(:enter)
      end

      it 'maps :return to :enter' do
        stub_keypress(key_name: :return)
        expect(TUIKeyHandler.read_key[0]).to eq(:enter)
      end

      it 'maps :space to :space' do
        stub_keypress(key_name: :space)
        expect(TUIKeyHandler.read_key[0]).to eq(:space)
      end
    end

    context 'with regular characters' do
      it 'returns the character value for a letter' do
        stub_keypress(value: 'a')
        expect(TUIKeyHandler.read_key[0]).to eq('a')
      end

      it 'returns the character value for a number' do
        stub_keypress(value: '5')
        expect(TUIKeyHandler.read_key[0]).to eq('5')
      end

      it 'returns the character value for uppercase letters' do
        stub_keypress(value: 'Q')
        expect(TUIKeyHandler.read_key[0]).to eq('Q')
      end
    end
  end
end
