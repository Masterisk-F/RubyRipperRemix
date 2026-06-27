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

require 'rubyripper/metadata/freedb/freedbRecordGenerator'

describe FreedbRecordGenerator do

  let(:disc) {double('Disc').as_null_object}
  let(:md) {double('Metadata::Data').as_null_object}
  let(:generator) {FreedbRecordGenerator.new()}

  context "When freedb record generation is requested" do
    before(:each) do 
      # number of audio tracks
      allow(disc).to receive(:audiotracks).and_return(8)
    
      # Responses for 'Track frame offsets' 
      allow(disc).to receive(:getStartSector).with(1).and_return(182-150)
      allow(disc).to receive(:getStartSector).with(2).and_return(34382-150)
      allow(disc).to receive(:getStartSector).with(3).and_return(57195-150)
      allow(disc).to receive(:getStartSector).with(4).and_return(74167-150)
      allow(disc).to receive(:getStartSector).with(5).and_return(97852-150)
      allow(disc).to receive(:getStartSector).with(6).and_return(126040-150)
      allow(disc).to receive(:getStartSector).with(7).and_return(145605-150)
      allow(disc).to receive(:getStartSector).with(8).and_return(165730-150)
      allow(disc).to receive(:getLengthSector).with(8).and_return(24822)

      # DISCID, DTITLE, DYEAR, DGENRE
      expect(disc).to receive(:freedbDiscid).and_return('6e09ea08')
      expect(disc).to receive(:metadata).and_return md
      expect(md).to receive(:album).and_return('Zyryab')
      expect(md).to receive(:year).and_return('1990')
      expect(md).to receive(:genre).and_return('Folk')

      # audio tracks
      expect(md).to receive(:trackname).with(1).and_return('Soniquete (Bulerias)')
      expect(md).to receive(:trackname).with(2).and_return('Tio Sabas (Tarantas)')
      expect(md).to receive(:trackname).with(3).and_return('Chick')
      expect(md).to receive(:trackname).with(4).and_return('Compadres (Bulerias)')
      expect(md).to receive(:trackname).with(5).and_return('Zyryab')
      expect(md).to receive(:trackname).with(6).and_return('Cancion de Amor')
      expect(md).to receive(:trackname).with(7).and_return('Playa del Carmen (Rumba)')
      expect(md).to receive(:trackname).with(8).and_return('Almonte (Fandangos)')
    end

    it "should generate correct freedb record" do

      # expected freedb record
      expected_record = "\
# xmcd\n\
#\n\
# Track frame offsets:\n\
#        182\n\
#        34382\n\
#        57195\n\
#        74167\n\
#        97852\n\
#        126040\n\
#        145605\n\
#        165730\n\
#\n\
# Disc length: 2540 seconds\n\
#\n\
# Revision: 5\n\
# Submitted via: rubyripper v0.7\n\
#\n\
DISCID=6e09ea08\n\
DTITLE=Paco de Lucia / Zyryab\n\
DYEAR=1990\n\
DGENRE=Folk\n\
TTITLE0=Soniquete (Bulerias)\n\
TTITLE1=Tio Sabas (Tarantas)\n\
TTITLE2=Chick\n\
TTITLE3=Compadres (Bulerias)\n\
TTITLE4=Zyryab\n\
TTITLE5=Cancion de Amor\n\
TTITLE6=Playa del Carmen (Rumba)\n\
TTITLE7=Almonte (Fandangos)\n\
EXTD=\n\
EXTT0=\n\
EXTT1=\n\
EXTT2=\n\
EXTT3=\n\
EXTT4=\n\
EXTT5=\n\
EXTT6=\n\
EXTT7=\n\
PLAYORDER=\n".encode('UTF-8')

      # Artist
      expect(md).to receive(:artist).and_return('Paco de Lucia')
      expect(md).to receive(:various?).exactly(8).times.and_return(false)

      expect(generator.generate(disc, 5)).to eq(expected_record)
    end


    it "should generate correct freedb record for various artists album" do

      # expected freedb record
      expected_record = "\
# xmcd\n\
#\n\
# Track frame offsets:\n\
#        182\n\
#        34382\n\
#        57195\n\
#        74167\n\
#        97852\n\
#        126040\n\
#        145605\n\
#        165730\n\
#\n\
# Disc length: 2540 seconds\n\
#\n\
# Revision: 1\n\
# Submitted via: rubyripper v0.7\n\
#\n\
DISCID=6e09ea08\n\
DTITLE=Various Artists / Zyryab\n\
DYEAR=1990\n\
DGENRE=Folk\n\
TTITLE0=Paco de Lucia / Soniquete (Bulerias)\n\
TTITLE1=Paco / Tio Sabas (Tarantas)\n\
TTITLE2=Pacode Lucia / Chick\n\
TTITLE3=Paco deLucia / Compadres (Bulerias)\n\
TTITLE4=Paco Lucia / Zyryab\n\
TTITLE5=Paco de / Cancion de Amor\n\
TTITLE6=deLucia / Playa del Carmen (Rumba)\n\
TTITLE7=PacodeLucia / Almonte (Fandangos)\n\
EXTD=\n\
EXTT0=\n\
EXTT1=\n\
EXTT2=\n\
EXTT3=\n\
EXTT4=\n\
EXTT5=\n\
EXTT6=\n\
EXTT7=\n\
PLAYORDER=\n".encode('UTF-8')

      # artist
      expect(md).to receive(:artist).and_return('Various Artists')
      expect(md).to receive(:various?).exactly(8).times.and_return(true)

      # artist names
      expect(md).to receive(:getVarArtist).with(1).and_return('Paco de Lucia')
      expect(md).to receive(:getVarArtist).with(2).and_return('Paco')
      expect(md).to receive(:getVarArtist).with(3).and_return('Pacode Lucia')
      expect(md).to receive(:getVarArtist).with(4).and_return('Paco deLucia')
      expect(md).to receive(:getVarArtist).with(5).and_return('Paco Lucia')
      expect(md).to receive(:getVarArtist).with(6).and_return('Paco de')
      expect(md).to receive(:getVarArtist).with(7).and_return('deLucia')
      expect(md).to receive(:getVarArtist).with(8).and_return('PacodeLucia')

      expect(generator.generate(disc)).to eq(expected_record)
    end
  end
end
