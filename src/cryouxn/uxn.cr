module Cryouxn
  class Uxn
    property! vm : VM
    property status = 0
    getter wst = Stack.new, rst = Stack.new

    def run(pc = 0x100u16)
      while insn = fetch
        op, mode = insn.op, insn.mode
        s, d = @wst, @rst
        s, d = d, s if mode.return?
        s.keep, d.keep = s.ptr, d.ptr if mode.keep?

        case op
        when .brk?; break
        when .lit?; push mode.short? ? read2 : read

        when .add?; arith :&+ when .sub?; arith :&- when .mul?; arith :&*
        when .and?; arith :&  when .ora?; arith :|  when .eor?; arith :^
        when .div?; pop2(push b > 0 ? a // b : a.class.zero)
        when .sft?; a = pop8; push pop >> a.lo << a.hi

        when .equ?; cmp :== when .gth?; cmp :>
        when .neq?; cmp :!= when .lth?; cmp :<

        when .pop?; pop
        when .inc?; push pop &+ 1
        when .dup?; a = pop; push a, a
        when .nip?; pop2(push b)
        when .swp?; pop2(push b, a)
        when .ovr?; pop2(push a, b, a)
        when .rot?; pop3(push b, c, a)

        when .deo?; vm.deo pop8, pop
        when .dei?; push vm.dei a = pop8; push vm.dei a &+ 1 if mode.short?

        when .sth?; d.push pop
        when .jsr?; d.push pc; jump pop
        when .jmp?; jump pop
        when .jmi?; pc &+= read2
        when .jsi?; @rst.push pc &+ 2; pc &+= read2
        when .jci?; pc &+= s.pop8(false) > 0 ? read2 : 2
        when .jcn?; a = pop; jump a if pop8 != 0

        when .sta?; poke s.pop16(mode.keep?), pop
        when .str?; poke rel(pop8), pop
        when .stz?; poke pop8, pop
        when .lda?; push peek s.pop16 mode.keep?
        when .ldr?; push peek rel(pop8)
        when .ldz?; push peek pop8
        end
      end

      return status & 0x7f
    end

    def show_stacks
      vm.console.stderr.puts "wst #{@wst.show}"
      vm.console.stderr.puts "rst #{@rst.show}"
    end
  end
end
