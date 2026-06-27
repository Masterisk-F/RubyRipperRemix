#!/usr/bin/env ruby
#    RubyRipperRemix - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2011 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/metadata/main'

describe Metadata::Main do
  
  let(:disc) {double('Disc').as_null_object}
  let(:prefs) {double('Preferences').as_null_object}
  let(:musicbrainz) {double('MusicBrainz').as_null_object}
  let(:freedb) {double('Freedb').as_null_object}
  let(:no_provider) {double('NoProvider').as_null_object}
  let(:main) {Metadata::Main.new(disc,prefs,musicbrainz,freedb,no_provider)}

  context "When the metadata for a disc is requested" do
    it "should use Musicbrainz if that is the preference" do
      allow(prefs).to receive(:metadataProvider).and_return("musicbrainz")
      expect(musicbrainz).to receive(:get)
      expect(musicbrainz).to receive(:status).and_return 'ok'
      expect(main.get).to eq(musicbrainz)
    end
  
    it "should use Gnudb if that is the preference" do
      allow(prefs).to receive(:metadataProvider).and_return("gnudb")
      expect(freedb).to receive(:get)
      expect(freedb).to receive(:status).and_return 'ok'
      expect(main.get).to eq(freedb)
    end
    
    it "should skip both providers if that is the preference" do
      allow(prefs).to receive(:metadataProvider).and_return("none")
      expect(main.get).to eq(no_provider)
    end
    
    context "Given the preference is set to musicbrainz" do
      before(:each) do
        allow(prefs).to receive(:metadataProvider).and_return("musicbrainz")
      end
      
      it "should first fall back to Gnudb if Musicbrainz fails" do
        expect(musicbrainz).to receive(:get)
        expect(musicbrainz).to receive(:status).and_return 'mayday'
        expect(freedb).to receive(:get)
        expect(freedb).to receive(:status).and_return 'ok'
        expect(main.get).to eq(freedb)
      end
      
      it "should fall back to none if Gnudb fails as well" do
        expect(musicbrainz).to receive(:get)
        expect(musicbrainz).to receive(:status).and_return 'mayday'
        expect(freedb).to receive(:get)
        expect(freedb).to receive(:status).and_return 'mayday'
        expect(main.get).to eq(no_provider)
      end
    end
    
    context "Given the preference is set to gnudb" do
      before(:each) do
        allow(prefs).to receive(:metadataProvider).and_return("gnudb")
      end

      it "should first fall back to Musicbrainz if Gnudb fails" do
        expect(freedb).to receive(:get)
        expect(freedb).to receive(:status).and_return 'mayday'
        expect(musicbrainz).to receive(:get)
        expect(musicbrainz).to receive(:status).and_return 'ok'
        expect(main.get).to eq(musicbrainz)
      end

      it "should fall back to none if Musicbrainz fails as well" do
        expect(freedb).to receive(:get)
        expect(freedb).to receive(:status).and_return 'mayday'
        expect(musicbrainz).to receive(:get)
        expect(musicbrainz).to receive(:status).and_return 'mayday'
        expect(main.get).to eq(no_provider)
      end
    end
  end

  context "When checking if MusicBrainz metadata fetching failed" do
    it "should be false if musicbrainz is the preference and it succeeds" do
      allow(prefs).to receive(:metadataProvider).and_return("musicbrainz")
      expect(musicbrainz).to receive(:get)
      expect(musicbrainz).to receive(:status).and_return 'ok'
      main.get
      expect(main.musicbrainz_failed).to eq(false)
    end

    it "should be true if musicbrainz is the preference and it returns noMatches" do
      allow(prefs).to receive(:metadataProvider).and_return("musicbrainz")
      expect(musicbrainz).to receive(:get)
      expect(musicbrainz).to receive(:status).and_return 'noMatches'
      allow(freedb).to receive(:get)
      allow(freedb).to receive(:status).and_return 'ok'
      main.get
      expect(main.musicbrainz_failed).to eq(true)
    end

    it "should be false if musicbrainz is the preference and it returns multipleRecords" do
      allow(prefs).to receive(:metadataProvider).and_return("musicbrainz")
      expect(musicbrainz).to receive(:get)
      expect(musicbrainz).to receive(:status).and_return 'multipleRecords'
      main.get
      expect(main.musicbrainz_failed).to eq(false)
    end

    it "should be true if gnudb fails and musicbrainz fallback also fails" do
      allow(prefs).to receive(:metadataProvider).and_return("gnudb")
      expect(freedb).to receive(:get)
      expect(freedb).to receive(:status).and_return 'mayday'
      expect(musicbrainz).to receive(:get)
      expect(musicbrainz).to receive(:status).and_return 'noMatches'
      main.get
      expect(main.musicbrainz_failed).to eq(true)
    end

    it "should be false if gnudb succeeds (musicbrainz never tried)" do
      allow(prefs).to receive(:metadataProvider).and_return("gnudb")
      expect(freedb).to receive(:get)
      expect(freedb).to receive(:status).and_return 'ok'
      main.get
      expect(main.musicbrainz_failed).to eq(false)
    end

    it "should be false if provider is none" do
      allow(prefs).to receive(:metadataProvider).and_return("none")
      main.get
      expect(main.musicbrainz_failed).to eq(false)
    end
  end
end
