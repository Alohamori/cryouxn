module Cryouxn
  class Screen
    PAIR = "\e[48;2;%s;38;2;%sm▄\e[0m"
    BLENDING = {
      Byte[0, 0, 0, 0, 1, 0, 1, 1, 2, 2, 0, 2, 3, 3, 3, 0],
      Byte[0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3],
      Byte[1, 2, 3, 1, 1, 2, 3, 1, 1, 2, 3, 1, 1, 2, 3, 1],
      Byte[2, 3, 1, 2, 2, 3, 1, 2, 2, 3, 1, 2, 2, 3, 1, 2]
    }

    property! vm : VM
    property width = 0u16, height = 0u16, vector = 0u16
    property x = 0u16, y = 0u16, auto = 0u8, addr = 0u16
    getter colors, bg, fg, used = false

    def initialize
      @colors = uninitialized Byte[6]
      @palette = uninitialized String[4]
      @cache = Hash(Byte, String).new
      @bg = Hash({Short, Short}, Byte).new 0
      @fg = @bg.dup
    end

    def init
      update_size

      Thread.new {
        loop do
          vm.uxn.run @vector
          sleep 1/60
        end
      }.join
    end

    def update_size
      @width = `tput cols`.to_u16
      @height = `tput lines`.to_u16 * 2
    end

    def update_palette
      colors.flat_map { |b| [b.hi, b.lo] }.each_slice(4).
        to_a.transpose.each_with_index do |rgb, i|
          @palette[i] = rgb.map { |c| c << 4 | c }.join ';'
        end
    end

    def blank
      # We should probably blank, but I kinda like the see-through aesthetic.
      # print "\e[48;2;#{@palette[0]}m#{`clear`}"
      @used = true
    end

    def move(x, y)
      print "\e[#{y//2+1};#{x+1}H"
    end

    def put_pair(top, bot)
      print @cache[top << 2 | bot] ||= PAIR % {@palette[top], @palette[bot]}
    end

    def pixel(fg, pi)
      move @x, @y
      put_pair pi, 0
    end

    def render(layer, addr, flags, colors, x0, y0)
      8.times do |y|
        c = vm.ram[addr + y].to_u16 |
          (flags[3] ? vm.ram[addr + y + 8].to_u16 << 8 : 0)
        8.times do |x|
          ch = c >> 7 & 2 | c & 1
          yr = y0 &+ (flags[1] ? 7 - y : y)
          xr = x0 &+ (flags[0] ? x : 7 - x)
          layer[{xr, yr}] = BLENDING[ch][colors] if colors % 5 + ch > 0
          c >>= 1
        end
      end

      update x0, y0
    end

    def update(x, y)
      block = uninitialized Byte[64]
      8.times do |i|
        8.times do |j|
          bg = @bg[{x + j, y + i}]
          fg = @fg[{x + j, y + i}]
          block[i * 8 + j] = fg == 0 ? bg : fg
        end
      end

      move x, y
      block.each_slice(8).each_slice(2).with_index do |(a, b), i|
        8.times { |j| put_pair a[j], b[j] }
        print "\e[B\e[8D" # move back 8 and down 1
      end
    end

    def sprite(args)
      flags, colors = args.hi, args.lo
      dx, dy =  auto[0] ?  8 : 0,  auto[1] ?  8 : 0
      fx, fy = flags[0] ? -1 : 1, flags[1] ? -1 : 1
      a, da = addr, auto[2] ? flags[3] ? 16 : 8 : 0

      auto.hi.succ.times do |i|
        x, y = @x &+ dy * fx * i, @y &+ dx * fy * i
        render flags[2] ? @fg : @bg, a, flags, colors, x, y
        a += da
      end

      # TODO: Redraw dirty region all at once here.

      @x &+= dx * fx if auto[0]
      @y &+= dy * fy if auto[1]
      @addr = a if auto[2]
    end
  end

  Device.new :screen do |d|
    d.listen 0x20 { |b, vm| set_hi vm.screen.vector, b }
    d.listen 0x21 { |b, vm| set_lo vm.screen.vector, b }

    # Ignore resize requests for now; xdotool could be used to resize most
    # modern terminals, but dynamically adjusting font size is much trickier.
    # TODO: Maybe just make it work for Alacritty?
    # d.listen 0x22 { |b, vm| set_hi vm.screen.width, b }
    # d.listen 0x23 { |b, vm| set_lo vm.screen.width, b }
    # d.listen 0x24 { |b, vm| set_hi vm.screen.height, b }
    # d.listen 0x25 { |b, vm|
    #   set_lo vm.screen.height, b
    #   w, h = vm.screen.width, vm.screen.height
    #   `xdotool getactivewindow windowsize #{w} #{h}`
    # }

    d.listen 0x26 { |b, vm| vm.screen.auto = b }
    d.listen 0x28 { |b, vm| set_hi vm.screen.x, b }
    d.listen 0x29 { |b, vm| set_lo vm.screen.x, b }
    d.listen 0x2a { |b, vm| set_hi vm.screen.y, b }
    d.listen 0x2b { |b, vm| set_lo vm.screen.y, b }
    d.listen 0x2c { |b, vm| set_hi vm.screen.addr, b }
    d.listen 0x2d { |b, vm| set_lo vm.screen.addr, b }

    d.listen 0x2e { |b, vm| vm.screen.pixel b.hi > 0, b.lo }
    d.listen 0x2f { |b, vm| vm.screen.sprite b }

    d.report 0x22 { |vm| vm.screen.width.hi }
    d.report 0x23 { |vm| vm.screen.width.lo }
    d.report 0x24 { |vm| vm.screen.height.hi }
    d.report 0x25 { |vm| vm.screen.height.lo }

    d.report 0x28 { |vm| vm.screen.x.hi }
    d.report 0x29 { |vm| vm.screen.x.lo }
    d.report 0x2a { |vm| vm.screen.y.hi }
    d.report 0x2b { |vm| vm.screen.y.lo }
  end
end
