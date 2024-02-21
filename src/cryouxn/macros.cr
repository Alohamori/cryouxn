module Cryouxn
  macro set_hi(s, b)
    {{s}} = {{s}} & 0xff | {{b}}.to_u16 << 8
  end

  macro set_lo(s, b)
    {{s}} = {{s}} & 0xff00 | {{b}}
  end

  class Uxn
    macro fetch
      b = vm.ram[pc]
      pc &+= 1
      OPCODES[b]
    end

    macro read; b = vm.ram[pc]; pc &+= 1; b end
    macro read2; v = read.to_u16 << 8 | read; v end

    macro pop8; s.pop8 mode.keep? end
    macro pop; mode.short? ? s.pop16(mode.keep?) : pop8 end
    macro pop2(then) b, a = pop, pop; {{then}} end
    macro pop3(then) c, b, a = pop, pop, pop; {{then}} end

    macro jump(a)
      _a = {{a}}
      pc = mode.short? ? _a : pc + _a - (_a > 0x80 ? 256 : 0)
    end

    macro rel(a)
      pc + (_a = {{a}}) - (_a > 0x80 ? 256 : 0)
    end

    macro peek1(a) vm.ram[{{a}}] end
    macro peek2(a) peek1(_a = {{a}}).to_u16 << 8 | vm.ram[_a &+ 1] end
    macro peek(a) mode.short? ? peek2({{a}}) : peek1({{a}}) end

    macro poke1(a, v) vm.ram[{{a}}] = {{v}}.to_u8 end
    macro poke2(a, v)
      _a, _v = {{a}}, {{v}}
      vm.ram[_a] = _v.hi
      vm.ram[_a &+ 1] = _v.lo
    end
    macro poke(a, v) mode.short? ? poke2({{a}}, {{v}}) : poke1({{a}}, {{v}}) end

    macro push(*x) s.push {{x.splat}} end
    macro arith(op) pop2(push a {{op.id}} b) end
    macro cmp(op) pop2(push a {{op.id}} b ? 1u8 : 0u8) end
  end
end
