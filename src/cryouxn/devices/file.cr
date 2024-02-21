module Cryouxn
  class Filesystem
    property! vm : VM
    getter files : Tuple(Phial, Phial)

    def initialize
      @files = { Phial.new, Phial.new }
      @files.each { |f| f.fs = self }
    end
  end

  class Phial
    enum State
      Idle; Read; Write; Dir
    end

    property! fs : Filesystem
    property addr = 0u16, len = 0u16
    property waddr = 0u16, raddr = 0u16, append = 0u8
    property state = State::Idle, file : File?, dir : Pointer(LibC::DIR)?

    def init
      @path = String.new fs.vm.ram.to_unsafe + addr
      reset
    end

    def reset
      @file.try &.close
      @file = nil
      @state = State::Idle
    end

    def write(len)
      if (p = @path) && !@state.write?
        reset
        @file = File.open p, append > 0 ? "ab" : "wb"
        @state = State::Write
      end

      if (f = @file) && @state.write?
        f.write Bytes.new fs.vm.ram.to_unsafe + @addr, len
      end
    end

    def read(len)
      if !(@state.read? || @state.dir?)
        reset
        if (p = @path) && File.directory? p
          @dir = Crystal::System::Dir.open p
          @state = State::Dir
        elsif (p = @path) && File.exists? p
          @file = File.open p, "rb"
          @state = State::Read
        end
      end

      if (f = @file) && @state.read?
        f.read Bytes.new fs.vm.ram.to_unsafe + addr, len
      end
    end

    def delete
      if f = @file
        f.delete
      end
    end
  end

  Cryouxn::Device.new :filesystem do |d|
    2.times do |id|
      d.listen 0xa6 + id * 0x10 { |b, vm| vm.fs.files[id].delete }
      d.listen 0xa7 + id * 0x10 { |b, vm| vm.fs.files[id].append = b }
      d.listen 0xa8 + id * 0x10 { |b, vm| set_hi vm.fs.files[id].addr, b }
      d.listen 0xa9 + id * 0x10 { |b, vm|
        set_lo vm.fs.files[id].addr, b
        vm.fs.files[id].init
      }

      d.listen 0xaa + id * 0x10 { |b, vm| set_hi vm.fs.files[id].len, b }
      d.listen 0xab + id * 0x10 { |b, vm| set_lo vm.fs.files[id].len, b }

      d.listen 0xac + id * 0x10 { |b, vm| set_hi vm.fs.files[id].raddr, b }
      d.listen 0xad + id * 0x10 { |b, vm|
        set_lo vm.fs.files[id].raddr, b
        addr = vm.fs.files[id].raddr
        len = vm.fs.files[id].len
        vm.fs.files[id].read [0x10000 - addr, len].min
      }

      d.listen 0xae + id * 0x10 { |b, vm| set_hi vm.fs.files[id].waddr, b }
      d.listen 0xaf + id * 0x10 { |b, vm|
        set_lo vm.fs.files[id].waddr, b
        addr = vm.fs.files[id].waddr
        len = vm.fs.files[id].len
        vm.fs.files[id].write [0x10000 - addr, len].min
      }
    end
  end
end
