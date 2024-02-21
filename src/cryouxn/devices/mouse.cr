module Cryouxn
  class Mouse
    property! vm : VM
    property vector = 0u16, state = 0u8, x = 0u16, y = 0u16

    def init
      print "\e7\e[?1003h" # Save cursor, watch for mouse events.

      Thread.new {
        while c = STDIN.raw &.read_byte
          break if c == 3 || c == 4 # ^C + ^D
          if c == 27
            buttons, x, y, *another = STDIN.peek[2..]
            handle buttons, x, y
            unless another.empty?
              buttons, x, y = another[3, 3]
              handle buttons, x, y
            end
          end
        end
      }.join

      print "\e8\e[?1003l" # Stop watching, restore cursor.
    end

    def handle(buttons, x, y)
      @x, @y = x.to_u16 - 32, y.to_u16 - 32
      @state = 0u8
      @state |= 1 if buttons == 32 || buttons == 64
      @state |= 4 if buttons == 34 || buttons == 66
      vm.uxn.run @vector
    end
  end

  Device.new :mouse do |d|
    d.listen 0x90 { |b, vm| set_hi vm.mouse.vector, b }
    d.listen 0x91 { |b, vm| set_lo vm.mouse.vector, b }

    d.report 0x92 { |vm| vm.mouse.x.hi }
    d.report 0x93 { |vm| vm.mouse.x.lo }
    d.report 0x94 { |vm| vm.mouse.y.hi }
    d.report 0x95 { |vm| vm.mouse.y.lo }
    d.report 0x96 { |vm| vm.mouse.state }
  end
end
