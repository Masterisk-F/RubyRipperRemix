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

require 'rubyripper/disc/scanDiscCdinfo'

describe ScanDiscCdinfo do

  let(:prefs) {double('Preferences').as_null_object}
  let(:exec) {double('Execute').as_null_object}
  let(:scan) {ScanDiscCdinfo.new(exec, prefs)}

  before(:each) do
    expect(prefs).to receive(:cdrom).at_least(:once).and_return('/dev/cdrom')
  end

  def setQueryReply(answer)
    expect(exec).to receive(:launch).with('cd-info -C /dev/cdrom -A --no-cddb').and_return(answer)
  end

  def setStandardQueryReply
    setQueryReply([" 15: 36:34:45  164445 audio  false  no    2        no",
                   " 16: 39:55:60  179535 audio  false  no    2        no",
                   "170: 43:33:30  195855 leadout"])
  end
  
  context "When a queryresult is not a valid response" do
    it "should detect if cd-info is not installed" do
      setQueryReply(nil)
      scan.scan()
      expect(scan.status).to eq('notInstalled')
    end

    it "should detect if the drive is not valid" do
      setQueryReply(['++ WARN: Can\'t get file status for'])
      scan.scan()
      expect(scan.status).to eq('unknownDrive')
    end

    it "should detect a problem with parameters" do
      setQueryReply(['Usage: cd'])
      scan.scan()
      expect(scan.status).to eq('wrongParameters')
    end

    it "should detect if there is no disc inserted" do
      setQueryReply(['++ WARN: error in ioctl CDROMREADTOCHDR: No medium found'])
      scan.scan()
      expect(scan.status).to eq('noDiscInDrive')
    end
  end

  context "When a query is a valid response" do
    it "should detect the cd-info version" do
      setQueryReply(["cd-info version 0.82 i686-pc-linux-gnu"])
      scan.scan()
      expect(scan.status).to eq('ok')
      expect(scan.version).to eq('cd-info version 0.82 i686-pc-linux-gnu')
    end

    it "should detect the discmode of the drive" do
      setQueryReply(['Disc mode is listed as: CD-DA'])
      scan.scan()
      expect(scan.discMode).to eq('CD-DA')
    end

    it "should detect the devicename for the drive" do
      setQueryReply(["Vendor                      : HL-DT-ST",
                     "Model                      : DVDRAM GH22NS40",
                     "Revision                    : NL01"])
      scan.scan()
      expect(scan.deviceName).to eq('HL-DT-ST DVDRAM GH22NS40 NL01')
    end

    it "should detect the startsector for each track" do
      setStandardQueryReply()
      scan.scan()
      expect(scan.getStartSector(14)).to eq(nil)
      expect(scan.getStartSector(15)).to eq(164445)
      expect(scan.getStartSector(16)).to eq(179535)
      expect(scan.getStartSector(17)).to eq(nil)
    end

    it "should detect the length in sectors for each track" do
      setStandardQueryReply()
      scan.scan()
      expect(scan.getLengthSector(14)).to eq(nil)
      expect(scan.getLengthSector(15)).to eq(15090)
      expect(scan.getLengthSector(16)).to eq(16320)
      expect(scan.getLengthSector(17)).to eq(nil)
    end

    it "should detect the length in mm:ss for each track" do
      setStandardQueryReply()
      scan.scan()
      expect(scan.getLengthText(14)).to eq(nil)
      expect(scan.getLengthText(15)).to eq('03:21:15')
      expect(scan.getLengthText(16)).to eq('03:37:45')
      expect(scan.getLengthText(17)).to eq(nil)
    end

    it "should detect the total amount of sectors for the disc" do
      setQueryReply(["170: 43:33:30  195855 leadout"])
      scan.scan()
      expect(scan.totalSectors).to eq(195855)
    end

    it "should detect the playtime in mm:ss for the disc" do
      setQueryReply(["170: 43:33:30  195855 leadout"])
      scan.scan()
      expect(scan.playtime).to eq('43:31') #minus 2 seconds offset, without frames
    end

    it "should detect the amount of audiotracks" do
      setStandardQueryReply()
      scan.scan()
      expect(scan.audiotracks).to eq(2)
    end

    it "should detect the first audio track" do
      setStandardQueryReply()
      scan.scan()
      expect(scan.firstAudioTrack).to eq(15)
    end

    it "should detect if there are no data tracks on the disc" do
      setStandardQueryReply()
      scan.scan()
      expect(scan.audiotracks).to eq(2)
      expect(scan.dataTracks).to eq([])
      expect(scan.tracks).to eq(2)
    end

    it "should detect the data tracks on the disc" do
      setQueryReply([" 13: 61:11:22  275197 data   false  no",
                     "170: 73:47:31  331906 leadout (744 MB raw, 744 MB formatted)"])
      scan.scan()
      expect(scan.audiotracks).to eq(0)
      expect(scan.dataTracks).to eq([13])
      expect(scan.tracks).to eq(1)
    end
  end


end
