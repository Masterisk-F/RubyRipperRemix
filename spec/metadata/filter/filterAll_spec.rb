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
require 'rubyripper/metadata/filter/filterAll'

describe Metadata::FilterAll do
  
  let(:data) {Metadata::Data.new()}
  let(:prefs) {double('Preferences').as_null_object}
  let(:filter) {Metadata::FilterAll.new(data, prefs)}
 
  context "The filter should return all values of metadata" do  
    it "should remove a backquote and replace it with a single quote" do
      data.artist = 'No ` allowed'
      expect(filter.artist).to eq("No ' allowed")
    end
    
    it "should replace UTF-8 single quote with ASCII single quote" do
      data.artist = "single quote \342\200\230 1"
      data.album = "single quote \342\200\231 2"
      expect(filter.artist).to eq("single quote ' 1")
      expect(filter.album).to eq("single quote ' 2")
    end
    
    it "should replace UTF-8 double quote with ASCII double quote" do
      data.artist = "double quote \342\200\234 1"
      data.album = "double quote \342\200\235 2"
      expect(filter.artist).to eq('double quote " 1')
      expect(filter.album).to eq('double quote " 2')
    end
    
    it "should strip extra spaces" do
      data.artist = '  Random artist   '
      expect(filter.artist).to eq('Random artist')
    end
    
    it "should be able to combine this logic" do
      data.tracklist = {1=>"  Don`t won\342\200\230t know  "}
      expect(filter.trackname(1)).to eq("Don't won't know")
    end
  end
end
