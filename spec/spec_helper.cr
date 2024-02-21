require "spec"
require "../src/cryouxn/types"
require "../src/cryouxn/**"

def files_for(prog, skip = nil)
   by_ext = Dir["#{__DIR__}/fixtures/#{prog}/*"]
     .reject(&.match skip || /$./)
     .group_by(&.split('.').last)
     .transform_values(&.first)

   # Prefer to execute the rom if it's there, but get both
   # out of the way before we actually start reading files.
   exe = by_ext.delete("tal")
   exe = by_ext.delete("rom") || exe

   {exe.not_nil!, by_ext.transform_values &->File.read(String)}
end

def capture_output(prog)
  vm = Cryouxn::VM.new
  vm.console.stdout = sout = IO::Memory.new
  vm.console.stderr = serr = IO::Memory.new
  vm.load(prog).run

  {sout.to_s, serr.to_s}
end

class DummyScreen < Cryouxn::Screen
  def initialize(@width, @height)
    if vm = @vm = Cryouxn::VM.new
      vm.screen = self
    end

    super()
  end

  def update(x, y)
    @vector = 0 # run for one frame
    @used = false # disable scrolloff retention
  end

  def canvas
    @height.times.map { |y|
      @width.times.map { |x|
        (fg = @fg[{x, y}]) == 0 ? @bg[{x, y}] : fg
      }
    }
  end
end
