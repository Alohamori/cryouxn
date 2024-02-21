require "./spec_helper"

macro pixel_test(name, width, height, trans, cut)
  dir = "#{__DIR__}/fixtures/" + {{name}}
  expected = if magick
               `magick #{dir}.png txt: | tail -n +2 | cut -d '#' -f 2 |
                cut -b #{{{cut}}} | paste -sd '' | fold -w #{{{width}}}`
             else
               File.read "#{dir}/#{{{name}}}.out"
             end

  ds = DummyScreen.new {{width}}, {{height}}
  ds.vm.load("#{dir}/#{{{name}}}.rom").run

  ds.canvas.zip expected.lines do |have, want|
    have.map { |c| {{trans}}[c] }.join.should eq want
  end
end

describe Cryouxn do
  magick = {{ flag? :tbv }} && Process.find_executable "magick"

  it "should pixel-perfectly match the first frame of screen.rom" do
    pixel_test "screen", 256u16, 176u16, "wbsr", 9
  end
  
  it "should render screen.blending.rom with 100% accuracy" do
    pixel_test "screen.blending", 256u16, 268u16, "F0B2", 6
  end

  it "should shoot 5-for-5 on screen.auto.rom" do
    pixel_test "screen.auto", 160u16, 32u16, "097F", 6
  end
end
