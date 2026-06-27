#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
#    Copyright (C) 2016 BleskoDev (bleskodev@gmail.com)
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

require 'rubyripper/metadata/data'
require 'rubyripper/disc/disc'

# generates freedb record from data in Disc and Metadata::Data
class FreedbRecordGenerator

  def initialize
  end

  def generate(disc, revision=1)
    # currently handle only standard discs (no varius artists)
    md = disc.metadata
    track_count = disc.audiotracks

    # file format signature
    result =  "# xmcd\n"
    result << "#\n"
    # Track frame offsets
    result << "# Track frame offsets:\n" 
    (1..track_count).each do |track|
      result << "#        #{disc.getStartSector(track) + 150}\n"
    end
    result << "#\n"
    # disc length
    disc_length = (disc.getStartSector(track_count) + 150 + \
      disc.getLengthSector(track_count)) / 75
    result << "# Disc length: #{disc_length} seconds\n" 
    result << "#\n"
    # revision and client 
    result << "# Revision: #{revision}\n"
    result << "# Submitted via: RubyRipperRemix v0.7\n"
    result << "#\n"
    # disc info
    result << "DISCID=#{disc.freedbDiscid}\n"
    result << "DTITLE=#{md.artist} / #{md.album}\n"
    result << "DYEAR=#{md.year}\n"
    result << "DGENRE=#{md.genre}\n"
    # audio tracks info
    (1..disc.audiotracks).each do |track|
      unless md.various?
        result << "TTITLE#{track-1}=#{md.trackname(track)}\n"
      else
        result << 
          "TTITLE#{track-1}=#{md.getVarArtist(track)} / #{md.trackname(track)}\n"
      end
    end
    # extended data
    result << "EXTD=\n"
    (1..disc.audiotracks).each do |track|
      result << "EXTT#{track-1}=\n"
    end
    result << "PLAYORDER=\n"
    return result 
  end
end

