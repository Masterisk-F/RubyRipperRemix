#!/usr/bin/env ruby
#    RubyRipperRemix - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/disc/scanDiscCdrdao'

describe ScanDiscCdrdao do

  let(:prefs) {double('Preferences').as_null_object}
  let(:exec) {double('Execute').as_null_object}
  let(:file) {double('FileAndDir').as_null_object}
  let(:log) {double('Log').as_null_object}
  let(:cdrdao) {ScanDiscCdrdao.new(exec, prefs, file)}
  
  before(:each){allow(prefs).to receive(:cdrom).and_return('/dev/cdrom')}

  context "In case cdrdao exits with an error" do
    it "should detect cdrdao is not installed" do
      allow(exec).to receive(:launch).and_return(nil)
      expect(log).to receive(:<<).with('Error: cdrdao is required, but not detected on your system!')
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
    end
    
    it "should detect if there is no disc in the drive" do
      allow(exec).to receive(:launch).and_return('ERROR: Unit not ready, giving up.')
      expect(log).to receive(:<<).with('Error: There is no audio disc ready in drive /dev/cdrom.')
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
    end
    
    it "should detect if there is a parameter problem" do
      allow(exec).to receive(:launch).and_return('Usage: cdrdao')
      expect(log).to receive(:<<).with('Error: cdrdao does not recognize the parameters used.')
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
    end
    
    it "should detect if the drive is not recognized" do
      allow(exec).to receive(:launch).and_return('ERROR: Cannot setup device')
      expect(log).to receive(:<<).with('Error: The device /dev/cdrom doesn\'t exist on your system!')
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
    end
    
    it "should not give a warning with correct results" do
      allow(exec).to receive(:launch).and_return('ok')
      expect(log).to receive(:<<).with("\nADVANCED TOC ANALYSIS (with cdrdao)\n")
      expect(log).to receive(:<<).with("...please be patient, this may take a while\n\n")
      expect(log).to receive(:<<).with("No pregap, silence, pre-emphasis or data track detected\n\n")
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      cdrdao.error.nil? == true
    end
  end
  
  context "When parsing the file" do
    before(:each){allow(exec).to receive(:launch).and_return('ok')}

    # notice there are 75 sectors in a second
    it "should detect if the disc starts with a silence" do
      expect(file).to receive(:read).and_return('SILENCE 00:01:20')
      expect(log).to receive(:<<).with("Silence detected for disc : 95 sectors\n")
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      expect(cdrdao.getSilenceSectors).to eq(95)
    end
    
    it "should detect if a track has a pregap" do
      expect(file).to receive(:read).and_return(%Q{// Track 3\n// Track 4\nSTART 00:00:35\n// Track 5})
      expect(log).to receive(:<<).with("Pregap detected for track 4 : 35 sectors\n")
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      expect(cdrdao.getPregapSectors(track=3)).to eq(0)
      expect(cdrdao.getPregapSectors(track=4)).to eq(35)
      expect(cdrdao.getPregapSectors(track=5)).to eq(0)
    end
    
    it "should detect if a track has pre-emphasis" do
      expect(file).to receive(:read).and_return(%Q{// Track 3\n// Track 4\nPRE_EMPHASIS\n// Track 5})
      expect(log).to receive(:<<).with("Pre_emphasis detected for track 4\n")
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      expect(cdrdao.preEmph?(3)).to eq(false)
      expect(cdrdao.preEmph?(4)).to eq(true)
      expect(cdrdao.preEmph?(5)).to eq(false)
    end

    it "should detect if a track has a ISRC code" do
      expect(file).to receive(:read).and_return(%Q{// Track 3\n// Track 4\nISRC "USSM10007452"\n// Track 5})
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      expect(cdrdao.getIsrcForTrack(3)).to eq('')
      expect(cdrdao.getIsrcForTrack(4)).to eq('USSM10007452')
      expect(cdrdao.getIsrcForTrack(5)).to eq('')
    end
    
    it "should detect data tracks" do
      expect(file).to receive(:read).and_return(%Q{// Track 3\n// Track 4\nTRACK DATA\n// Track 5\nTRACK DATA})
      expect(log).to receive(:<<).with("Track 4 is marked as a DATA track\n")
      expect(log).to receive(:<<).with("Track 5 is marked as a DATA track\n")
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      expect(cdrdao.dataTracks).to eq([4,5])
    end
    
    it "should detect the type of the disc" do
      expect(file).to receive(:read).and_return('CD_DA')
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      expect(cdrdao.discType).to eq('CD_DA')
    end
    
    it "should detect the highest track number" do
      expect(file).to receive(:read).and_return(%Q{// Track 3\n// Track 4\nTRACK DATA\n// Track 5\nTRACK DATA})
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      expect(cdrdao.tracks).to eq(5)
    end
  end
  
  context "When there is cd-text on the disc" do
    before(:each){allow(exec).to receive(:launch).and_return('ok')}
    
    it "should detect the artist and album" do
      expect(file).to receive(:read).and_return(%Q[CD_TEXT {\n  LANGUAGE 0 {\n    TITLE "SYSTEM OF A DOWN   STEAL THIS ALBUM!"])
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      expect(cdrdao.artist).to eq("SYSTEM OF A DOWN")
      expect(cdrdao.album).to eq("STEAL THIS ALBUM!")
    end
    
    it "should detect the tracknames" do
      expect(file).to receive(:read).and_return(%Q[// Track 3\nCD_TEXT {\n  LANGUAGE 0 {\n    TITLE "BUBBLES"\n    PERFORMER ""\n  }\n}])
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      expect(cdrdao.getTrackname(track=2)).to eq("")
      expect(cdrdao.getTrackname(track=3)).to eq("BUBBLES")
      expect(cdrdao.getTrackname(track=4)).to eq("")
    end
    
    it "should detect the various artists" do
      expect(file).to receive(:read).and_return(%Q[// Track 3\nCD_TEXT {\n  LANGUAGE 0 {\n    TITLE "BUBBLES"\n    PERFORMER "ABCDE"\n  }\n}])
      cdrdao.scanInBackground()
      cdrdao.joinWithMainThread(log)
      expect(cdrdao.getVarArtist(track=2)).to eq("")
      expect(cdrdao.getVarArtist(track=3)).to eq("ABCDE")
      expect(cdrdao.getVarArtist(track=4)).to eq("")
    end    
  end
end

