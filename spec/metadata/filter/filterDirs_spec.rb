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
require 'rubyripper/metadata/filter/filterDirs'

describe Metadata::FilterDirs do
  
  let(:data) {Metadata::Data.new()}
  let(:prefs) {double('Preferences').as_null_object}
  let(:filter) {Metadata::FilterDirs.new(data, prefs)}
  
  before(:each) do
    allow(prefs).to receive(:noSpaces).and_return(false)
    allow(prefs).to receive(:noCapitals).and_return(false)
  end
  
  context "When determining the dirname it should be valid in a FAT filesystem" do
    it "should replace the dollar sign $" do
      data.artist = 'I like CA$H'
      expect(filter.artist).to eq('I like CASH')
    end
    
    it "should remove colons :" do
      data.artist = 'Hello: world'
      expect(filter.artist).to eq("Hello world")
    end
    
    it "should remove asterixes *" do
      data.artist = 'Hello* world'
      expect(filter.artist).to eq("Hello world")
    end
    
    it "should remove question marks ?" do
      data.artist = 'Hello? world'
      expect(filter.artist).to eq("Hello world")
    end
    
    it "should remove smaller than signs <" do
      data.artist = 'Hello< world'
      expect(filter.artist).to eq("Hello world")
    end
    
    it "should remove bigger than signs >" do
      data.artist = 'Hello> world'
      expect(filter.artist).to eq("Hello world")
    end
    
    it "should remove the pipe character |" do
      data.artist = 'Hello| world'
      expect(filter.artist).to eq("Hello world")
    end
    
    it "should remove backslashes \\" do
      data.artist = 'Hello\\ world'
      expect(filter.artist).to eq("Hello world")
    end
    
    it "should remove double quotes \"" do
      data.artist = 'Hello" world'
      expect(filter.artist).to eq("Hello world")
    end
    
    it "should be able to combine all logic for filterDirs + filterAll" do
      data.tracklist = {1=>"  \"\\Don`t won\342\200\230t know ?? ** >< | "}
      expect(filter.trackname(1)).to eq("Don't won't know")
    end
  end
  
  context "Replace any characters that are not wished by the user" do
    it "should replace all spaces to underscores if wished for" do
      data.artist = 'Hello world'
      allow(prefs).to receive(:noSpaces).and_return(true)
      expect(filter.artist).to eq("Hello_world")
    end
    
    it "should not replace spaces to underscores if not wished for" do
      data.artist = 'Hello world'
      allow(prefs).to receive(:noSpaces).and_return(false)
      expect(filter.artist).to eq("Hello world")
    end

    it "should not replace underscores with spaces if noSpaces setting  == false" do
      data.artist = 'Hello_world'
      allow(prefs).to receive(:noSpaces).and_return(false)
      expect(filter.artist).to eq("Hello_world")
    end

    it "should downsize all letters if wished for" do
      data.artist = 'hELLo WoRLD'
      allow(prefs).to receive(:noCapitals).and_return(true)
      expect(filter.artist).to eq('hello world')
    end

    it "should not downsize all letters if not wished for" do
      data.artist = 'hELLo WoRLD'
      allow(prefs).to receive(:noCapitals).and_return(false)
      expect(filter.artist).to eq('hELLo WoRLD')
    end

  end
end
