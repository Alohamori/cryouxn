module Cryouxn
  alias Byte = UInt8
  struct Byte
    def hi; self >> 4 end
    def lo; self & 0xf end
    def [](b) self & 1 << b > 0 end
  end

  alias Short = UInt16
  struct Short
    def hi; 0u8 | self >> 8 end
    def lo; 0u8 | self & 0xff end
  end

  alias Listener = Byte, VM -> Nil
  alias Reporter = VM -> Byte

  class Stack
    property :buf, :ptr, :keep

    def initialize
      @buf = [@ptr = @keep = 0u8] * 0x100
    end

    def push(v : Byte)
      @buf[@ptr] = v
      @ptr &+= 1
    end

    def push(v : Short)
      push v.hi, v.lo
    end

    def push(*vs)
      vs.each { |v| push v }
    end

    def pop8(keep)
      @buf[keep ? (@keep &-= 1) : (@ptr &-= 1)]
    end

    def pop16(keep)
      pop8(keep).to_u16 | pop8(keep).to_u16 << 8
    end

    def show
      9.times.map { |i|
        p = @ptr &- 4 &+ i
        fmt = p == 0 ? "[%02x]" : i == 4 ? "<%02x>" : " %02x "
        fmt % @buf[p &- 1]
      }.join
    end
  end
end
