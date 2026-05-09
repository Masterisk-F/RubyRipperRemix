#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2011 Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
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

require 'rubyripper/disc/disc'

describe Disc do
  
  let(:cdpar) {double('ScanDiscCdparanoia').as_null_object}
  let(:freedb) {double('FreedbString').as_null_object}
  let(:musicbrainz) {double('CalcMusicbrainzID').as_null_object}
  let(:deps) {double('Dependency').as_null_object}
  let(:prefs) {double('Preferences').as_null_object}
  let(:metadata) {double('Freedb').as_null_object}
  let(:disc) {Disc.new(cdpar, freedb, musicbrainz, deps, prefs)}
  
  context "When a disc is requested to be scanned" do
    before(:each) do
      expect(cdpar).to receive(:scan).once().and_return true
    end
    
    it "should send the scan command to cdparanoia" do
      expect(cdpar).to receive(:status).once().and_return false
      disc.scan()
    end
    
    it "should trigger the metadata class if a disc is found" do
      expect(cdpar).to receive(:status).once().and_return 'ok'
      expect(metadata).to receive(:get).once().and_return 1
      expect(prefs).to receive(:createCue).once().and_return false
      disc.scan(metadata)
      expect(disc.metadata).to eq(1)
    end
    
    it "should not trigger the metadata if no disc is found" do
      expect(cdpar).to receive(:status).once().and_return false
      expect(metadata).not_to receive(:get)
      disc.scan(nil)
      expect(disc.metadata).to eq(nil)
    end
  end
  
  context "When a toc analyzer is requested for calculating the disc id" do
    it "should first refer to the cd-info scanner if it is installed" do
      expect(deps).to receive(:installed?).with('cd-info').and_return true
      expect(disc.advancedTocScanner(cdinfo='a', cdcontrol='b')).to eq('a')
    end
    
    it "should then refer to the cdcontrol scanner if it is installed" do
      expect(deps).to receive(:installed?).with('cd-info').and_return false
      expect(deps).to receive(:installed?).with('cdcontrol').and_return true
      expect(disc.advancedTocScanner(cdinfo='a', cdcontrol='b')).to eq('b')
    end
    
    it "should fall back to cdparanoia if nothing better is available" do
      expect(deps).to receive(:installed?).with('cd-info').and_return false
      expect(deps).to receive(:installed?).with('cdcontrol').and_return false
      expect(disc.advancedTocScanner(cdinfo='a', cdcontrol='b')).to eq(cdpar)
    end
  end
  
  context "When methods need to be forwarded" do
    it "should forward the freedbstring method to the calcFreedbID object" do
      expect(freedb).to receive(:freedbString).once.and_return true
      disc.freedbString()
    end
    
    it "should forward the freedb discid method to the calcFreedbID object" do
      expect(freedb).to receive(:discid).once.and_return true
      disc.freedbDiscid()
    end
    
    it "should forward the musicbrainzlookuppath method to the calcMusicbrainzID object" do
      expect(musicbrainz).to receive(:musicbrainzLookupPath).once.and_return true
      disc.musicbrainzLookupPath()
    end
    
    it "should forward the musicbrainzdiscid method to the calcMusicbrainzID object" do
      expect(musicbrainz).to receive(:discid).once.and_return true
      disc.musicbrainzDiscid()
    end

    it "should forward the musicbrainzSubmitURL method to the calcMusicbrainzID object" do
      expect(musicbrainz).to receive(:musicbrainzSubmitURL).once.and_return 'https://musicbrainz.org/cdtoc/attach?toc=...'
      expect(disc.musicbrainzSubmitURL()).to eq('https://musicbrainz.org/cdtoc/attach?toc=...')
    end
    
    # all unknown commands should be redirected to cdparanoia
    it "should pass any other command to cdparanoia" do
      expect(cdpar).to receive(:any_other_command).and_return true
      disc.any_other_command()
    end
  end

  context "When metadata fetching fails for MusicBrainz" do
    let(:main_double) {double('Metadata::Main')}

    it "should capture musicbrainz_failed from the metadata main class" do
      expect(main_double).to receive(:get).once.and_return true
      expect(main_double).to receive(:musicbrainz_failed).once.and_return true
      disc.send(:setMetadata, main_double)
      expect(disc.musicbrainz_failed).to eq(true)
    end

    it "should capture musicbrainz_failed as false when metadata succeeds" do
      expect(main_double).to receive(:get).once.and_return true
      expect(main_double).to receive(:musicbrainz_failed).once.and_return false
      disc.send(:setMetadata, main_double)
      expect(disc.musicbrainz_failed).to eq(false)
    end
  end
end
