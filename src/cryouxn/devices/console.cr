module Cryouxn
  class Console
    enum Type
      NoQ; Input; Arg; Spacer; End
    end

    property! vm : VM
    property vector = 0u16, read = 0u8, type = 0u8
    property stdin : IO = STDIN, stdout : IO = STDOUT, stderr : IO = STDERR

    def init
      ARGV.shift # discard ROM path
      while arg = ARGV.shift?
        arg.each_byte { |c| input c, Type::Arg }
        input 1u8, ARGV.empty? ? Type::End : Type::Spacer
      end

      while c = stdin.read_byte
        input c, Type::Input
      end
    end

    def input(c, type)
      @read, @type = c, type.to_u8
      vm.uxn.run @vector
    end
  end

  Device.new :console do |d|
    d.listen 0x10 { |b, vm| set_hi vm.console.vector, b }
    d.listen 0x11 { |b, vm| set_lo vm.console.vector, b }

    d.listen 0x18 { |b, vm| vm.console.stdout << b.chr }
    d.listen 0x19 { |b, vm| vm.console.stderr << b.chr }

    d.report 0x12 { |vm| vm.console.read }
    d.report 0x17 { |vm| vm.console.type }
  end
end
