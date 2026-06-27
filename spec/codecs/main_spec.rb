#!/usr/bin/env ruby
#    RubyRipperRemix - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2012 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/codecs/main'

# stub any method, also provide the double quotes
class TagFilterStub
  private
  def method_missing(name, *args)
    args.empty? ? "\"#{name.to_s}\"" : "\"#{name.to_s} #{args[0]}\""
  end
end

describe Codecs::Main do

  let(:disc) {double('Disc').as_null_object}
  let(:scheme) {double('FileScheme').as_null_object}
  let(:tags) {TagFilterStub.new()}
  let(:prefs) {double('Preferences').as_null_object}
  let(:md) {double('Metadata').as_null_object}
  let(:file) {double('FileAndDir').as_null_object}

  context "Given mp3 is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('mp3', disc, scheme, tags, prefs, md, file)
    end

    it "should return the command to replaygain a track" do
      expect(scheme).to receive(:getFile).with('mp3', 1).and_return 'output.mp3'
      expect(@codec.replaygain(1)).to eq('mp3gain -c -r "output.mp3"')
    end

    it "should return the command to replaygain an album" do
      expect(scheme).to receive(:getDir).with('mp3').and_return '/home/mp3'
      expect(@codec.replaygainAlbum()).to eq('mp3gain -c -a "/home/mp3"/*.mp3')
    end

    # all conditional logic is only tested for mp3 since it's generic
    context "When calculating the command for encoding a track" do
      before(:each) do
        expect(prefs).to receive(:settingsMp3).and_return '-V 2'
        allow(prefs).to receive(:image).and_return false
        expect(scheme).to receive(:getTempFile).with(1).and_return 'input_1.wav'
        expect(scheme).to receive(:getFile).with('mp3', 1).and_return '/home/mp3/1-test.mp3'
        expect(disc).to receive(:audiotracks).and_return 99
      end

      it "should be able to generate the basic command" do
        expect(md).to receive(:various?).and_return nil
        expect(md).to receive(:discNumber).and_return nil
        expect(disc).to receive(:freedbDiscid).and_return nil
        expect(disc).to receive(:musicbrainzDiscid).and_return nil

        expect(@codec.command(1)).to eq('lame -V 2 --ta "trackArtist 1" --tl "album" '\
            '--tv TCON="genre" --ty "year" --tv TENC="RubyRipperRemix test" --tt "trackname 1" '\
            '--tn 1/99 "input_1.wav" "/home/mp3/1-test.mp3"')
        expect(@codec.setTagsAfterEncoding(1)).to eq('')
      end

      it "should add the various artist tag if relevant" do
        expect(md).to receive(:various?).and_return true
        expect(md).to receive(:discNumber).and_return nil
        expect(disc).to receive(:freedbDiscid).and_return nil
        expect(disc).to receive(:musicbrainzDiscid).and_return nil

        expect(@codec.command(1)).to eq('lame -V 2 --ta "trackArtist 1" --tl "album" '\
            '--tv TCON="genre" --ty "year" --tv TPE2="artist" --tv TENC="RubyRipperRemix test" '\
            '--tt "trackname 1" --tn 1/99 "input_1.wav" "/home/mp3/1-test.mp3"')
      end

      it "should add the discid if available" do
        expect(md).to receive(:various?).and_return nil
        expect(md).to receive(:discNumber).and_return nil
        expect(disc).to receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
        expect(disc).to receive(:musicbrainzDiscid).twice.and_return 'yQnNM8eSkwrJ.9m9cLM07cRxmwg-'

        expect(@codec.command(1)).to eq('lame -V 2 --ta "trackArtist 1" --tl "album" '\
            '--tv TCON="genre" --ty "year" --tv TENC="RubyRipperRemix test" --tv "TXXX=DISCID=ABCDEFGH" '\
            '--tv "TXXX=MusicBrainz Disc Id=yQnNM8eSkwrJ.9m9cLM07cRxmwg-" '\
            '--tt "trackname 1" --tn 1/99 "input_1.wav" "/home/mp3/1-test.mp3"')
      end

      it "should add the discnumber if available" do
        expect(md).to receive(:various?).and_return nil
        expect(md).to receive(:discNumber).twice.and_return 1
        expect(disc).to receive(:freedbDiscid).and_return nil
        expect(disc).to receive(:musicbrainzDiscid).and_return nil

        expect(@codec.command(1)).to eq('lame -V 2 --ta "trackArtist 1" --tl "album" '\
            '--tv TCON="genre" --ty "year" --tv TPOS=1 --tv TENC="RubyRipperRemix test" --tt '\
            '"trackname 1" --tn 1/99 "input_1.wav" "/home/mp3/1-test.mp3"')
      end
    end
  end

  context "Given vorbis is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('vorbis', disc, scheme, tags, prefs, md, file)
    end

    it "should return the command to replaygain a track" do
      expect(scheme).to receive(:getFile).with('vorbis', 1).and_return 'output.ogg'
      expect(@codec.replaygain(1)).to eq('vorbisgain "output.ogg"')
    end

    it "should return the command to replaygain an album" do
      expect(scheme).to receive(:getDir).with('vorbis').and_return '/home/vorbis'
      expect(@codec.replaygainAlbum).to eq('vorbisgain -a "/home/vorbis"/*.ogg')
    end

    it "should calculate the command for encoding" do
      expect(prefs).to receive(:settingsVorbis).and_return '-q 6'
      allow(prefs).to receive(:image).and_return false
      expect(scheme).to receive(:getTempFile).with(1).and_return 'input_1.wav'
      expect(scheme).to receive(:getFile).with('vorbis', 1).and_return '/home/vorbis/1-test.ogg'
      expect(disc).to receive(:audiotracks).and_return 99
      expect(md).to receive(:various?).and_return true
      expect(md).to receive(:discNumber).twice.and_return 1
      expect(disc).to receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
      expect(disc).to receive(:musicbrainzDiscid).twice.and_return 'yQnNM8eSkwrJ.9m9cLM07cRxmwg-'

      expect(@codec.command(1)).to eq('oggenc -o "/home/vorbis/1-test.ogg" -q 6 -c '\
          'ARTIST="trackArtist 1" -c ALBUM="album" -c GENRE="genre" -c DATE="year" -c '\
          '"ALBUM ARTIST"="artist" -c DISCNUMBER=1 -c ENCODER="RubyRipperRemix test" -c '\
          'DISCID="ABCDEFGH" -c MUSICBRAINZ_DISCID="yQnNM8eSkwrJ.9m9cLM07cRxmwg-" '\
          '-c TITLE="trackname 1" -c TRACKNUMBER=1 -c TRACKTOTAL=99 "input_1.wav"')
      expect(@codec.setTagsAfterEncoding(1)).to eq('')
    end
  end

  context "Given flac is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('flac', disc, scheme, tags, prefs, md, file)
    end

    it "should return the command to replaygain a track" do
      expect(scheme).to receive(:getFile).with('flac', 1).and_return 'output.flac'
      expect(@codec.replaygain(1)).to eq('metaflac --add-replay-gain "output.flac"')
    end

    it "should return the command to replaygain an album" do
      expect(scheme).to receive(:getDir).with('flac').and_return '/home/flac'
      expect(@codec.replaygainAlbum).to eq('metaflac --add-replay-gain "/home/flac"/*.flac')
    end

    it "should calculate the command for encoding a track" do
      expect(prefs).to receive(:settingsFlac).and_return '-q 6'
      allow(prefs).to receive(:image).and_return false
      expect(scheme).to receive(:getTempFile).with(1).and_return 'input_1.wav'
      expect(scheme).to receive(:getFile).with('flac', 1).and_return '/home/flac/1-test.flac'
      expect(disc).to receive(:audiotracks).and_return 99
      expect(md).to receive(:various?).and_return true
      expect(md).to receive(:discNumber).twice.and_return 1
      expect(disc).to receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
      expect(disc).to receive(:musicbrainzDiscid).twice.and_return 'yQnNM8eSkwrJ.9m9cLM07cRxmwg-'

      expect(@codec.command(1)).to eq('flac -o "/home/flac/1-test.flac" -q 6 --tag '\
          'ARTIST="trackArtist 1" --tag ALBUM="album" --tag GENRE="genre" --tag DATE="year" '\
          '--tag "ALBUM ARTIST"="artist" --tag DISCNUMBER=1 --tag ENCODER="RubyRipperRemix test" '\
          '--tag DISCID="ABCDEFGH" --tag MUSICBRAINZ_DISCID="yQnNM8eSkwrJ.9m9cLM07cRxmwg-" '\
          '--tag TITLE="trackname 1" --tag TRACKNUMBER=1 --tag TRACKTOTAL=99 "input_1.wav"')
      expect(@codec.setTagsAfterEncoding(1)).to eq('')
    end

    it "should save the cuesheet file if available for image rips" do
      expect(prefs).to receive(:settingsFlac).and_return '-q 6'
      allow(prefs).to receive(:image).and_return true
      expect(prefs).to receive(:createCue).and_return true
      expect(scheme).to receive(:getCueFile).and_return '/home/flac/test.cue'
      expect(file).to receive(:exist?).with('/home/flac/test.cue').and_return true
      expect(scheme).to receive(:getTempFile).with(1).and_return 'input_1.wav'
      expect(scheme).to receive(:getFile).with('flac', 1).and_return '/home/flac/1-test.flac'
      expect(disc).to receive(:audiotracks).and_return 99
      expect(md).to receive(:various?).and_return true
      expect(md).to receive(:discNumber).twice.and_return 1
      expect(disc).to receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
      expect(disc).to receive(:musicbrainzDiscid).twice.and_return 'yQnNM8eSkwrJ.9m9cLM07cRxmwg-'

      expect(@codec.command(1)).to eq('flac -o "/home/flac/1-test.flac" -q 6 --tag '\
          'ARTIST="trackArtist 1" --tag ALBUM="album" --tag GENRE="genre" --tag DATE="year" '\
          '--tag "ALBUM ARTIST"="artist" --tag DISCNUMBER=1 --tag ENCODER="RubyRipperRemix test" '\
          '--tag DISCID="ABCDEFGH" --tag MUSICBRAINZ_DISCID="yQnNM8eSkwrJ.9m9cLM07cRxmwg-" '\
          '--tag TRACKTOTAL=99 --cuesheet="/home/flac/test.cue" "input_1.wav"')
    end
  end

  context "Given wav is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('wav', disc, scheme, tags, prefs, md, file)
    end

    it "should return the command to replaygain a track" do
      expect(scheme).to receive(:getFile).with('wav', 1).and_return 'output.wav'
      expect(@codec.replaygain(1)).to eq('wavegain "output.wav"')
    end

    it "should return the command to replaygain an album" do
      expect(scheme).to receive(:getDir).with('wav').and_return '/home/wav'
      expect(@codec.replaygainAlbum).to eq('wavegain -a "/home/wav"/*.wav')
    end

    it "should calculate the command for encoding" do
      expect(scheme).to receive(:getTempFile).with(1).and_return 'input_1.wav'
      expect(scheme).to receive(:getFile).with('wav', 1).and_return '/home/wav/1-test.wav'
      expect(@codec.command(1)).to eq('cp "input_1.wav" "/home/wav/1-test.wav"')
      expect(@codec.setTagsAfterEncoding(1)).to eq('')
    end
  end

  context "Given Nero aac is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('nero', disc, scheme, tags, prefs, md, file)
    end

    it "should return the command to replaygain a track" do
      expect(scheme).to receive(:getFile).with('nero', 1).and_return 'output.m4a'
      expect(@codec.replaygain(1)).to eq('aacgain -c -r "output.m4a"')
    end

    it "should return the command to replaygain an album" do
      expect(scheme).to receive(:getDir).with('nero').and_return '/home/nero'
      expect(@codec.replaygainAlbum()).to eq('aacgain -c -a "/home/nero"/*.m4a')
    end

    it "should calculate the command for encoding and tagging" do
      expect(prefs).to receive(:settingsNero).and_return '-q 1'
      allow(prefs).to receive(:image).and_return false
      expect(scheme).to receive(:getTempFile).with(1).and_return 'input_1.wav'
      expect(scheme).to receive(:getFile).with('nero', 1).twice.and_return '/home/nero/1-test.m4a'
      expect(disc).to receive(:audiotracks).and_return 99
      expect(md).to receive(:various?).and_return true
      expect(md).to receive(:discNumber).twice.and_return 1
      expect(disc).to receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
      expect(disc).to receive(:musicbrainzDiscid).twice.and_return 'yQnNM8eSkwrJ.9m9cLM07cRxmwg-'

      expect(@codec.command(1)).to eq('neroAacEnc -q 1 -if "input_1.wav" -of "/home/nero/1-test.m4a"')
      expect(@codec.setTagsAfterEncoding(1)).to eq('neroAacTag "/home/nero/1-test.m4a" '\
          '-meta:artist="trackArtist 1" -meta:album="album" -meta:genre="genre" -meta:year="year" '\
          '-meta-user:"ALBUM ARTIST"="artist" -meta:disc=1 -meta-user:ENCODER="RubyRipperRemix test" '\
          '-meta-user:DISCID="ABCDEFGH" -meta-user:MUSICBRAINZ_DISCID="yQnNM8eSkwrJ.9m9cLM07cRxmwg-" '\
          '-meta:title="trackname 1" -meta:track=1 -meta:totaltracks=99')
    end
  end

  context "Given wavpack is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('wavpack', disc, scheme, tags, prefs, md, file)
    end

    it "should return the command  the replaygain a track" do
      expect(scheme).to receive(:getFile).with('wavpack', 1).and_return 'output.wv'
      expect(@codec.replaygain(1)).to eq('wvgain "output.wv"')
    end

    it "should return the command to replaygain an album" do
      expect(scheme).to receive(:getDir).with('wavpack').and_return '/home/wavpack'
      expect(@codec.replaygainAlbum).to eq('wvgain -a "/home/wavpack"/*.wv')
    end

    it "should calculate the command for encoding an image rip" do
      expect(prefs).to receive(:settingsWavpack).and_return ''
      allow(prefs).to receive(:image).and_return true
      expect(prefs).to receive(:createCue).and_return true
      expect(scheme).to receive(:getCueFile).and_return '/home/wavpack/test.cue'
      expect(file).to receive(:exist?).with('/home/wavpack/test.cue').and_return true
      expect(scheme).to receive(:getTempFile).with(1).and_return 'input_1.wav'
      expect(scheme).to receive(:getFile).with('wavpack', 1).and_return '/home/wavpack/1-test.wv'
      expect(disc).to receive(:audiotracks).and_return 99
      expect(md).to receive(:various?).and_return true
      expect(md).to receive(:discNumber).twice.and_return 1
      expect(disc).to receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
      expect(disc).to receive(:musicbrainzDiscid).twice.and_return 'yQnNM8eSkwrJ.9m9cLM07cRxmwg-'

      expect(@codec.command(1)).to eq('wavpack -w ARTIST="trackArtist 1" -w ALBUM="album" '\
          '-w GENRE="genre" -w DATE="year" -w "ALBUM ARTIST"="artist" -w DISCNUMBER=1 -w '\
          'ENCODER="RubyRipperRemix test" -w DISCID="ABCDEFGH" -w MUSICBRAINZ_DISCID="yQnNM8eSkwrJ.9m9cLM07cRxmwg-" -w '\
          'TRACKTOTAL=99 -w CUESHEET="/home/wavpack/test.cue" "input_1.wav" -o "/home/wavpack/1-test.wv"')
      expect(@codec.setTagsAfterEncoding(1)).to eq('')
    end
  end

  context "Given opus is chosen as preferred codec" do
    before(:each) do
      @codec = Codecs::Main.new('opus', disc, scheme, tags, prefs, md, file)
    end

    it "should calculate the command for encoding" do
      expect(prefs).to receive(:settingsOpus).and_return '--bitrate 160'
      allow(prefs).to receive(:image).and_return false
      expect(scheme).to receive(:getTempFile).with(1).and_return 'input_1.wav'
      expect(scheme).to receive(:getFile).with('opus', 1).and_return '/home/opus/1-test.opus'
      expect(disc).to receive(:audiotracks).and_return 99
      expect(md).to receive(:various?).and_return true
      expect(md).to receive(:discNumber).twice.and_return 1
      expect(disc).to receive(:freedbDiscid).twice.and_return 'ABCDEFGH'
      expect(disc).to receive(:musicbrainzDiscid).twice.and_return 'yQnNM8eSkwrJ.9m9cLM07cRxmwg-'

      expect(@codec.command(1)).to eq('opusenc --bitrate 160 --artist "trackArtist 1" --comment ALBUM="album" '\
          '--comment GENRE="genre" --comment DATE="year" --comment "ALBUM ARTIST"="artist" '\
          '--comment DISCNUMBER=1 --comment ENCODER="RubyRipperRemix test" --comment DISCID="ABCDEFGH" '\
          '--comment MUSICBRAINZ_DISCID="yQnNM8eSkwrJ.9m9cLM07cRxmwg-" --title "trackname 1" ' \
          '--comment TRACKNUMBER=1 --comment TRACKTOTAL=99 "input_1.wav" "/home/opus/1-test.opus"')
      expect(@codec.setTagsAfterEncoding(1)).to eq('')
    end
  end

  context "Given other is chosen as preferred codec" do
    let(:random_other_command) { "/my/custom/command arg#{10 + rand(90)} %i %o.bin" }

    before(:each) do
      prefs.data.settingsOther = random_other_command
      @codec = Codecs::Main.new('other', disc, scheme, tags, prefs, md, file)
    end

    it "should ignore replaygain on track" do
      expect(@codec.replaygain(1)).to eq('')
    end

    it "should ignore replaygain on album" do
      expect(@codec.replaygainAlbum).to eq('')
    end

    it "should ignore setTagsAfterEncoding" do
      expect(@codec.setTagsAfterEncoding(1)).to eq('')
    end

    it "should return the command for encoding" do
      expect(prefs).to receive(:settingsOther).and_return random_other_command
      expect(scheme).to receive(:getTempFile).with(1).and_return 'input_1.wav'
      expect(scheme).to receive(:getFile).with('other', 1).and_return '/home/test/output_1'

      parsed_other_command = random_other_command[0,25] + "\"input_1.wav\" \"/home/test/output_1\".bin"
      expect(@codec.command(1)).to eq(parsed_other_command)
    end
  end
end
