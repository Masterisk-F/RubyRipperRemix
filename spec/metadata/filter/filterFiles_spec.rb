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

require 'rubyripper/metadata/data'
require 'rubyripper/metadata/filter/filterFiles'

describe Metadata::FilterFiles do
  
  let(:prefs) {double('Preferences').as_null_object}
  let(:filter) {Metadata::FilterFiles.new(nil, prefs)}
  
  before(:each) do
    allow(prefs).to receive(:noSpaces).and_return(false)
    allow(prefs).to receive(:noCapitals).and_return(false)
  end
  
  context "When determining the filename it has to be valid" do
    it "should replace the slash sign /" do
      expect(filter.filter('01 AC/DC - Jailbreak.mp3')).to eq('01 ACDC - Jailbreak.mp3')
    end
    
    it "should remove starting dots from filenames ." do
      expect(filter.filter('.Who knows - Someone.flac')).to eq('Who knows - Someone.flac')
      expect(filter.filter('...Who knows - Someone.flac')).to eq('Who knows - Someone.flac')
    end
    
    it "should keep other dots however ." do
      expect(filter.filter('.Who. knows - Someone.flac')).to eq('Who. knows - Someone.flac')
      expect(filter.filter('Who. knows - Someone.flac')).to eq('Who. knows - Someone.flac')
    end
    
    it "should be able to combine all logic for filterFiles + filterDirs + filterAll" do
      expect(filter.filter(" AC/DC \"\\Don`t won\342\200\230t know ?? ** >< | ")).to eq("ACDC Don't won't know")
    end
  end
end
