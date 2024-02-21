module Cryouxn
  enum Op : Byte
    BRK; INC; POP; NIP; SWP; ROT; DUP; OVR; EQU; NEQ; GTH; LTH; JMP; JCN; JSR; STH
    LDZ; STZ; LDR; STR; LDA; STA; DEI; DEO; ADD; SUB; MUL; DIV; AND; ORA; EOR; SFT
    JCI; JMI; JSI; LIT;
  end

  @[Flags]
  enum Mode : Byte
    Short; Return; Keep

    def to_s(io)
      io << '2' if short?
      io << 'k' if keep?
      io << 'r' if return?
    end
  end

  record Opcode, op : Op, mode : Mode do
    def inspect(io)
      io << "#{op}#{mode}"
    end
  end

  macro opcode(op, mode)
    if {{op}} > 0
      Opcode.new Op.new({{op}}), Mode.new({{mode}})
    else
      irregular_opcode {{mode}}
    end
  end

  macro irregular_opcode(offset)
    lit, mode = {{offset}}.divmod 4
    Opcode.new case {lit, mode}
               when {1, _}; Op::LIT
               when {0, 0}; Op::BRK
               else Op.from_value mode + 31
               end, Mode.from_value mode * lit
  end

  OPCODES = {% begin %} {
              {% for byte in 0..0xff %}
                opcode({{byte & 0x1f}}, {{byte >> 5}}),
              {% end %}
          } {% end %}

end
