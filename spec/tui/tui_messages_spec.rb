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
require 'rubyripper/tui/tuiMessages'
require 'rubyripper/tui/tuiHelpers'

describe TUIMessages do
  let(:prefs) { double('Preferences::Main').as_null_object }
  subject(:messages) { TUIMessages.new(prefs) }

  describe '#initialize' do
    it 'starts with :welcome state' do
      expect(messages.state).to eq(:welcome)
    end

    it 'accepts a prefs object' do
      expect { TUIMessages.new(prefs) }.not_to raise_error
    end

    # Note: default constructor (no prefs) requires Singleton mode;
    # in spec mode ($run_specs = true) Singleton is disabled, so we
    # always inject prefs explicitly in tests.

    it 'initializes custom_message to nil' do
      expect(messages.custom_message).to be_nil
    end

    it 'initializes error to nil' do
      expect(messages.error).to be_nil
    end
  end

  describe '#welcome' do
    it 'sets state to :welcome' do
      messages.scan
      messages.welcome
      expect(messages.state).to eq(:welcome)
    end
  end

  describe '#scan' do
    it 'sets state to :scanning' do
      messages.scan
      expect(messages.state).to eq(:scanning)
    end

    it 'resets the spinner' do
      spinner = messages.instance_variable_get(:@spinner)
      expect(spinner).to receive(:reset)
      messages.scan
    end
  end

  describe '#refreshDisc' do
    it 'sets state to :scanning' do
      messages.refreshDisc
      expect(messages.state).to eq(:scanning)
    end

    it 'resets the spinner' do
      spinner = messages.instance_variable_get(:@spinner)
      expect(spinner).to receive(:reset)
      messages.refreshDisc
    end
  end

  describe '#noDiscFound' do
    it 'sets state to :no_disc' do
      messages.noDiscFound
      expect(messages.state).to eq(:no_disc)
    end
  end

  describe '#openTray' do
    it 'sets state to :open_tray' do
      messages.openTray
      expect(messages.state).to eq(:open_tray)
    end
  end

  describe '#closeTray' do
    it 'sets state to :close_tray' do
      messages.closeTray
      expect(messages.state).to eq(:close_tray)
    end
  end

  describe '#askForDisc' do
    it 'sets state to :ask_for_disc' do
      messages.askForDisc
      expect(messages.state).to eq(:ask_for_disc)
    end
  end

  describe '#noEjectFound' do
    it 'sets state to :no_eject' do
      messages.noEjectFound
      expect(messages.state).to eq(:no_eject)
    end
  end

  describe '#showError' do
    it 'sets state to :error' do
      messages.showError('test error')
      expect(messages.state).to eq(:error)
    end

    it 'stores the error message' do
      messages.showError('test error')
      expect(messages.error).to eq('test error')
    end
  end

  describe '#showMessage' do
    it 'sets state to :custom' do
      messages.showMessage('hello')
      expect(messages.state).to eq(:custom)
    end

    it 'stores the custom message' do
      messages.showMessage('hello world')
      expect(messages.custom_message).to eq('hello world')
    end
  end

  describe '#draw' do
    before(:each) do
      # Suppress prints to avoid cluttering test output
      allow(TUIMessages).to receive(:puts)
    end

    context 'in :welcome state' do
      it 'outputs content including RubyRipperRemix' do
        expect { messages.draw }.to output(/RubyRipperRemix/).to_stdout
      end

      it 'outputs content mentioning F2 key' do
        expect { messages.draw }.to output(/F2/).to_stdout
      end
    end

    context 'in :scanning state' do
      before(:each) do
        messages.scan
        spinner = messages.instance_variable_get(:@spinner)
        allow(spinner).to receive(:row).and_return('spinner line')
        allow(spinner).to receive(:spin).and_return('*')
      end

      it 'outputs scanner content' do
        expect { messages.draw }.to output(/spinner line/).to_stdout
      end
    end

    context 'in :no_disc state' do
      before(:each) { messages.noDiscFound }

      it 'outputs no disc message' do
        expect { messages.draw }.to output(/No disc found/).to_stdout
      end
    end

    context 'in :open_tray state' do
      before(:each) { messages.openTray }

      it 'outputs opening tray message' do
        expect { messages.draw }.to output(/Opening tray/).to_stdout
      end
    end

    context 'in :close_tray state' do
      before(:each) { messages.closeTray }

      it 'outputs closing tray message' do
        expect { messages.draw }.to output(/Closing tray/).to_stdout
      end
    end

    context 'in :ask_for_disc state' do
      before(:each) { messages.askForDisc }

      it 'outputs insert disc message' do
        expect { messages.draw }.to output(/Insert/).to_stdout
      end
    end

    context 'in :no_eject state' do
      before(:each) { messages.noEjectFound }

      it 'outputs eject not found message' do
        expect { messages.draw }.to output(/eject utility/).to_stdout
      end
    end

    context 'in :error state' do
      before(:each) do
        require 'rubyripper/errors'
        allow(Errors).to receive(:send).and_return('Formatted error message')
        messages.showError(['noDiscYet', 'test'])
      end

      it 'outputs error content' do
        expect { messages.draw }.to output(/Formatted error message/).to_stdout
      end
    end

    context 'in :custom state' do
      before(:each) { messages.showMessage('Custom message text') }

      it 'outputs the custom message' do
        expect { messages.draw }.to output(/Custom message text/).to_stdout
      end
    end
  end
end
