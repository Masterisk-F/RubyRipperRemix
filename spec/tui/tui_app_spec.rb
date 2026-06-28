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
require 'rubyripper/tui/tuiApp'

describe TUIApp do
  let(:prefs) { double('Preferences::Main').as_null_object }
  let(:messages) { double('TUIMessages').as_null_object }
  let(:deps) { double('Dependency').as_null_object }
  let(:disc) { double('TUIDisc').as_null_object }

  before(:each) do
    allow(Preferences::Main).to receive(:instance).and_return(prefs)
  end

  describe '#initialize' do
    subject(:app) { TUIApp.new(prefs, messages, deps) }

    it 'stores the prefs instance' do
      expect(app.prefs).to eq(prefs)
    end

    it 'creates an update queue' do
      expect(app.update_queue).to be_a(Queue)
    end

    it 'starts with messages view' do
      expect(app.instance_variable_get(:@current_view)).to eq(:messages)
    end

    it 'creates a TUIDisc instance' do
      expect(app.instance_variable_get(:@disc)).to be_a(TUIDisc)
    end

    it 'creates a TUIPreferences instance' do
      expect(app.instance_variable_get(:@preferences)).to be_a(TUIPreferences)
    end

    it 'creates a TUIRipStatus instance' do
      expect(app.instance_variable_get(:@rip_status)).to be_a(TUIRipStatus)
    end
  end

  describe '#update' do
    subject(:app) { TUIApp.new(prefs, messages, deps) }

    it 'adds a message to the update queue' do
      app.send(:update, 'test_event', 'value')
      expect(app.update_queue.size).to eq(1)
      expect(app.update_queue.pop).to eq(['test_event', 'value'])
    end
  end

  describe 'key handlers' do
    subject(:app) { TUIApp.new(prefs, messages, deps) }

    before(:each) do
      allow(app.instance_variable_get(:@disc)).to receive(:edit_metadata)
      allow(app.instance_variable_get(:@disc)).to receive(:select_tracks)
      allow(app.instance_variable_get(:@preferences)).to receive(:start)
    end

    describe '#handle_messages_key' do
      it 'calls refreshDisc on F2' do
        expect(app).to receive(:refreshDisc)
        app.send(:handle_messages_key, :f2)
      end

      it 'calls handleTray on F3' do
        expect(app).to receive(:handleTray)
        app.send(:handle_messages_key, :f3)
      end

      it 'opens preferences on F4' do
        expect(app.instance_variable_get(:@preferences)).to receive(:start)
        app.send(:handle_messages_key, :f4)
      end

      it 'exits on F10' do
        expect(app).to receive(:exit_app)
        app.send(:handle_messages_key, :f10)
      end
    end

    describe '#handle_disc_key' do
      it 'calls edit_metadata on F2' do
        expect(app.instance_variable_get(:@disc)).to receive(:edit_metadata)
        app.send(:handle_disc_key, :f2)
      end

      it 'calls select_tracks on F3' do
        expect(app.instance_variable_get(:@disc)).to receive(:select_tracks)
        app.send(:handle_disc_key, :f3)
      end

      it 'opens preferences on F4' do
        expect(app.instance_variable_get(:@preferences)).to receive(:start)
        app.send(:handle_disc_key, :f4)
      end

      it 'starts rip on F5' do
        expect(app).to receive(:startRip)
        app.send(:handle_disc_key, :f5)
      end

      it 'exits on F10' do
        expect(app).to receive(:exit_app)
        app.send(:handle_disc_key, :f10)
      end
    end
  end

  describe '#process_queue' do
    subject(:app) { TUIApp.new(prefs, messages, deps) }

    it 'displays error message on error event' do
      expect(app).to receive(:displayErrorMessage).with('error text')
      app.send(:update, 'error', 'error text')
      app.send(:process_queue)
    end

    it 'switches to disc view on error_msg_end' do
      app.send(:update, 'error_msg_end')
      app.send(:process_queue)
      expect(app.instance_variable_get(:@current_view)).to eq(:disc)
    end

    it 'calls scanDiscResults on scan_disc_finished' do
      expect(app).to receive(:scanDiscResults)
      app.send(:update, 'scan_disc_finished')
      app.send(:process_queue)
    end

    it 'calls showMultipleRecordsSelection on scan_disc_metadata_multiple_records' do
      expect(app).to receive(:showMultipleRecordsSelection)
      app.send(:update, 'scan_disc_metadata_multiple_records')
      app.send(:process_queue)
    end
  end

  describe '#displayErrorMessage' do
    subject(:app) { TUIApp.new(prefs, messages, deps) }

    it 'shows message on the messages screen' do
      expect(messages).to receive(:showMessage).with('Error occurred')
      app.send(:displayErrorMessage, 'Error occurred')
    end

    it 'switches current view to messages' do
      app.send(:displayErrorMessage, 'test')
      expect(app.instance_variable_get(:@current_view)).to eq(:messages)
    end
  end
end
