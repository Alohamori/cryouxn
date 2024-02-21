module Cryouxn
  class VM
    getter uxn = Uxn.new
    getter console = Console.new
    getter controller = Controller.new
    getter mouse = Mouse.new
    property screen = Screen.new
    getter fs = Filesystem.new
    getter dev = [0u8] * 0x100
    getter ram = [0u8] * 0x10000
    getter deis = Hash(Byte, Reporter).new
    getter deos = Hash(Byte, Listener).new
    property metadata = 0u16

    def initialize(devices = nil)
      own @uxn, @console, @controller, @mouse, @screen, @fs

      (devices || Device.all).each do |d|
        Device[d].listeners.each do |addr, listener|
          @deos[addr] = listener
        end
        Device[d].reporters.each do |addr, reporter|
          @deis[addr] = reporter
        end
      end
    end

    def load(path, at = 0x100u16)
      if path.split('.').last == "tal"
        rom = `uxnasm #{path} -`
      else
        rom = File.read path
      end

      @ram[at, rom.bytesize] = rom.bytes
      self
    end

    def run(pc = 0x100u16)
      @uxn.run pc

      @console.init if @console.vector > 0
      @controller.init if @controller.vector > 0
      @mouse.init if @mouse.vector > 0
      @screen.init if @screen.vector > 0
      print "\n\e[999B" if @screen.used
    end

    def deo(port, value : Byte)
      @dev[port] = value

      if listener = @deos[port]?
        listener.call value, self
      end
    end

    def deo(port, value : Short)
      deo port, value.hi
      deo port &+ 1, value.lo
    end

    def dei(port)
      if reporter = @deis[port]?
        reporter.call self
      else
        @dev[port]
      end
    end

    def own(*devices)
      devices.each &.vm = self
    end
  end
end
