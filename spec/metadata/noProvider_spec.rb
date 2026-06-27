#!/usr/bin/env ruby
#    RubyRipperRemix - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2011 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/metadata/noProvider'

describe NoProvider do
 
  let(:disc) {double('Disc').as_null_object}
  let(:md) {double('Metadata::Data').as_null_object}
  let(:generator) {double('FreedbRecordGenerator').as_null_object}
  let(:save) {double('SaveFreedbRecord').as_null_object}
  let(:md_empty) {Metadata::Data.new()}

  context "When the metadata for a disc is requested" do
    it "should fill metadata tracklist with default track names" do
      nb_tracks = 5
      allow(disc).to receive(:audiotracks).and_return(nb_tracks)
      no_provider = NoProvider.new(disc, nil, nil, save)
      no_provider.get()
      expect(no_provider.status).to eq('ok')
      expect(no_provider.tracklist.length).to eq(nb_tracks)
      (1..nb_tracks).each do |track|
        expect(no_provider.trackname(track)).to eq(md_empty.trackname(track))
      end
    end
  end

  context "When save is requested" do
    it "should generate freedb record and save it" do
      freedbRecord = 'fake record'
      category = 'Jazz'
      discid = 'a56b3400'
      expect(generator).to receive(:generate).with(disc).and_return(freedbRecord)
      expect(save).to receive(:save).with(freedbRecord, category, discid, true)
      expect(md).to receive(:genre).and_return(category)
      expect(disc).to receive(:freedbDiscid).and_return(discid)

      no_provider = NoProvider.new(disc, md, generator, save)
      no_provider.save()
    end
  end

end

