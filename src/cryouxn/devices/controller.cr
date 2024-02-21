module Cryouxn
  class Controller
    MAPPING = {"A"  => 0x10, "B" => 0x20,  "C"   => 0x40,  "D"   => 0x80,
               "5~" => 0x01, "6~"=> 0x02, "5;2~" => 0x04, "6;2~" => 0x08}
    property! vm : VM
    property vector = 0u16, button = 0u8

    def init
      Thread.new {
        while c = STDIN.raw &.read_byte
          break if c == 3 || c == 4 # ^C + ^D
          if c != 27
            key c
          elsif button = MAPPING[String.new STDIN.peek[1..]]?
            down button
          end
        end
      }.join
    end

    def key(c)
      vm.dev[0x83] = c
      vm.uxn.run @vector
      vm.dev[0x83] = 0u8
    end

    def down(mask)
      vm.dev[0x82] |= mask
      vm.uxn.run @vector
      vm.dev[0x82] &= ~mask
    end

    def up
      # TODO: Figure out the best way to handle this, ideally without polling.
    end
  end

  Device.new :controller do |d|
    d.listen 0x80 { |b, vm| set_hi vm.controller.vector, b }
    d.listen 0x81 { |b, vm| set_lo vm.controller.vector, b }

    d.report 0x82 { |vm| vm.controller.button }
  end
end
