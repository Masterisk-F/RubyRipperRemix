#!/usr/bin/env ruby
#    RubyRipperRemix - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
#    Copyright (C) 2016 BleskoDev (bleskodev@gmail.com)
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

require 'rubyripper/metadata/freedb/freedbRecordParser'

describe FreedbRecordParser do

  let(:parser) {FreedbRecordParser.new()}

  context "Before parsing the disc" do
    it "should set some default values" do
      expect(parser.md.artist).to eq('Unknown')
      expect(parser.md.album).to eq('Unknown')
      expect(parser.md.genre).to eq('Unknown')
      expect(parser.md.year).to eq('0')
      expect(parser.md.extraDiscInfo).to eq('')
      expect(parser.md.discid).to eq('')
      expect(parser.md.trackname(12)).to eq('Track 12')
      expect(parser.md.getVarArtist(12)).to eq('Unknown')
    end
  end

  context "When the string is not an UTF-8 encoded string" do
    it "should detect if it has no valid encoding and abort" do
      nonUTF8 = "hello red \xE8".force_encoding("UTF-8")
      parser.parse(nonUTF8)

      expect(parser.status).to eq('noValidEncoding')
    end

    it "should detect if the encoding is not UTF-8 and abort" do
      latin1 = "some_crazy_text".encode('ISO-8859-1')
      parser.parse(latin1)

      expect(parser.status).to eq('noUTF8Encoding')
    end
  end

  context "When parsing a valid freedb metadata file" do
    it "should ignore the commented lines" do
      record = "DGENRE=Gothic\n#DISCID=98113b0e\nDYEAR=1993".encode('UTF-8')
      parser.parse(record)

      expect(parser.status).to eq('ok')
      expect(parser.md.genre).to eq('Gothic')
      expect(parser.md.discid).to eq('')
      expect(parser.md.year).to eq('1993')
    end

    it "should parse all standard info" do
      record = "DISCID=98113b0e\nDTITLE=Type O Negative / Bloody \
Kisses\nDYEAR=1993\nDGENRE=Gothic\nTTITLE0=Machine Screw\n\
TTITLE1=Christian Woman".encode('UTF-8')
      parser.parse(record)

      expect(parser.status).to eq('ok')
      expect(parser.md.discid).to eq('98113b0e')
      expect(parser.md.artist).to eq('Type O Negative')
      expect(parser.md.album).to eq('Bloody Kisses')
      expect(parser.md.genre).to eq('Gothic')
      expect(parser.md.trackname(1)).to eq('Machine Screw')
      expect(parser.md.trackname(2)).to eq('Christian Woman')
    end

    it "should parse extra disc info" do
      record = "EXTD=What a wonderfull show!".encode('UTF-8')
      parser.parse(record)

      expect(parser.status).to eq('ok')
      expect(parser.md.extraDiscInfo).to eq('What a wonderfull show!')
    end

    it "should recognize a trackname of two lines and correctly concatenate them" do
      record = "TTITLE9=Part1\nTTITLE9=Part2".encode('UTF-8')
      parser.parse(record)

      expect(parser.status).to eq('ok')
      expect(parser.md.trackname(10)).to eq('Part1Part2')
    end

    it "should recognize the album if the title has two lines" do
      record = "DTITLE=Artist / Album wi\nDTITLE=th a longer name".encode('UTF-8')
      parser.parse(record)

      expect(parser.status).to eq('ok')
      expect(parser.md.artist).to eq('Artist')
      expect(parser.md.album).to eq('Album with a longer name')
    end

    it "should recognize the artist if it spins two lines as well" do
      record = "DTITLE=Artist wi\nDTITLE=th a long name / Album".encode('UTF-8')
      parser.parse(record)

      expect(parser.status).to eq('ok')
      expect(parser.md.artist).to eq('Artist with a long name')
      expect(parser.md.album).to eq('Album')
    end

    it "should parse revision value" do
      record = "# Disc length: \n#\n# Revision: 12\n# Submitted via: \n".encode('UTF-8')
      parser.parse(record)

      expect(parser.status).to eq('ok')
      expect(parser.revision).to eq(12)
    end

    it "should ignore invalid revision value" do
      record = "# Revision: \n".encode('UTF-8')
      parser.parse(record)

      expect(parser.status).to eq('ok')
      expect(parser.revision).to eq(0)
    end

    it "should ignore non number revision value" do
      record = "# Revision: jojo\n".encode('UTF-8')
      parser.parse(record)

      expect(parser.status).to eq('ok')
      expect(parser.revision).to eq(0)
    end

    context "When a various artist disc is expected" do
      it "should recognize a various artist disc separated by a '/'" do
        record = "TTITLE2=MUNGO JERRY / In The Summertime\nTTITLE3=THE \
EASYBEATS / Friday on my Mind".encode('UTF-8')
        parser.parse(record)

        expect(parser.status).to eq('ok')
        expect(parser.md.getVarArtist(3)).to eq('MUNGO JERRY')
        expect(parser.md.getVarArtist(4)).to eq('THE EASYBEATS')
        expect(parser.md.trackname(3)).to eq('In The Summertime')
        expect(parser.md.trackname(4)).to eq('Friday on my Mind')
      end

      it "should recognize a various artist disc separated by a '-'" do
        record = "TTITLE2=MUNGO JERRY - In The Summertime\nTTITLE3=THE \
EASYBEATS - Friday on my Mind".encode('UTF-8')
        parser.parse(record)

        expect(parser.status).to eq('ok')
        expect(parser.md.getVarArtist(3)).to eq('MUNGO JERRY')
        expect(parser.md.getVarArtist(4)).to eq('THE EASYBEATS')
        expect(parser.md.trackname(3)).to eq('In The Summertime')
        expect(parser.md.trackname(4)).to eq('Friday on my Mind')
      end

      it "should recognize a various artist disc separated by a ':'" do
        record = "TTITLE2=MUNGO JERRY: In The Summertime\nTTITLE3=THE \
EASYBEATS : Friday on my Mind".encode('UTF-8')
        parser.parse(record)

        expect(parser.status).to eq('ok')
        expect(parser.md.getVarArtist(3)).to eq('MUNGO JERRY')
        expect(parser.md.getVarArtist(4)).to eq('THE EASYBEATS')
        expect(parser.md.trackname(3)).to eq('In The Summertime')
        expect(parser.md.trackname(4)).to eq('Friday on my Mind')
      end

      it "should recognize a various artist disc separated by different splitters" do
        record = "TTITLE2=MUNGO JERRY : In The Summertime\nTTITLE3=THE \
EASYBEATS - Friday on my Mind\nTTITLE4=THE EASYBEATS / Friday on my Mind".encode('UTF-8')
        parser.parse(record)

        expect(parser.status).to eq('ok')
        expect(parser.md.getVarArtist(3)).to eq('MUNGO JERRY')
        expect(parser.md.getVarArtist(4)).to eq('THE EASYBEATS')
        expect(parser.md.getVarArtist(5)).to eq('THE EASYBEATS')
        expect(parser.md.trackname(3)).to eq('In The Summertime')
        expect(parser.md.trackname(4)).to eq('Friday on my Mind')
        expect(parser.md.trackname(5)).to eq('Friday on my Mind')
      end

      it "should allow to revert to the old tracknames before splitting" do
        record = "TTITLE2=MUNGO JERRY / In The Summertime\nTTITLE3=THE \
EASYBEATS / Friday on my Mind".encode('UTF-8')
        parser.parse(record)
        parser.undoVarArtist()

        expect(parser.md.trackname(3)).to eq('MUNGO JERRY / In The Summertime')
        expect(parser.md.trackname(4)).to eq('THE EASYBEATS / Friday on my Mind')
      end

      it "should allow to redo the various artist splitting" do
        record = "TTITLE2=MUNGO JERRY / In The Summertime\nTTITLE3=THE \
EASYBEATS / Friday on my Mind".encode('UTF-8')
        parser.parse(record)
        parser.undoVarArtist()
        parser.redoVarArtist()
        parser.undoVarArtist()
        parser.redoVarArtist()

        expect(parser.md.getVarArtist(3)).to eq('MUNGO JERRY')
        expect(parser.md.getVarArtist(4)).to eq('THE EASYBEATS')
        expect(parser.md.trackname(3)).to eq('In The Summertime')
        expect(parser.md.trackname(4)).to eq('Friday on my Mind')
      end
    end
  end
end
