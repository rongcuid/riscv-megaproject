#ifndef __DISASM_H__
#define __DISASM_H__

inline std::string disasm(uint32_t instruction) {
  const uint32_t mask_op_6_2 = 0b1111100;
  const uint32_t mask_funct3 = 0b111000000000000;
  const uint32_t mask_a_rs1 = 0b11111 << 15;
  const uint32_t mask_a_rs2 = 0b11111 << 20;
  const uint32_t mask_funct7 = 0b1111111 << 25;
  const uint32_t mask_funct7_5 = 1 << 30;
  uint32_t op_6_2 = (instruction & mask_op_6_2) >> 2;
  uint32_t funct3 = (instruction & mask_funct3) >> 12;
  uint32_t a_rs1 = (instruction & a_rs1) >> 15;
  uint32_t a_rs2 = (instruction & a_rs2) >> 20;
  uint32_t funct7 = (instruction & mask_funct7) >> 25;
  uint32_t funct7_5 = (instruction & mask_funct7_5) >> 30;
  switch (op_6_2) {
  case 0b00000:
    return "LOAD    "; 
  case 0b00100:
    switch (funct3) {
    case 0b000: return "ADDI    ";
    case 0b001: return "SLLI    ";
    case 0b010: return "SLTI    ";
    case 0b011: return "SLTIU   ";
    case 0b100: return "XORI    ";
    case 0b101: return funct7_5 ? "SRAI    " : "SRLI    ";
    case 0b110: return "ORI     ";
    case 0b111: return "ANDI    ";
    default: return "OP-IMM  ";
    }
  case 0b00101: return "AUIPC   ";
  case 0b01000: return "STORE   ";
  case 0b01100: 
    switch (funct3) {
    case 0b000: return funct7_5 ? "SUB     " : "ADD     ";
    case 0b001: return "SLL     ";
    case 0b010: return "SLT     ";
    case 0b011: return "SLTU    ";
    case 0b100: return "XOR     ";
    case 0b101: return funct7_5 ? "SRA     " : "SRL     ";
    case 0b110: return "OR      ";
    case 0b111: return "AND     ";
    default: return "OP?     ";
    }
  case 0b01101: return "LUI     ";
  case 0b11000:
    switch (funct3) {
    case 0b000: return "BEQ     ";
    case 0b001: return "BNE     ";
    case 0b100: return "BLT     ";
    case 0b101: return "BGE     ";
    case 0b110: return "BLTU    ";
    case 0b111: return "BGEU    ";
    default: return "BRANCH  ";
    }
  case 0b11001: return "JALR    ";
  case 0b11011: return "JAL     ";
  case 0b11100:
    switch (funct3) {
    case 0b000:
      return (funct7 == 0b0011000 && a_rs1 == 0b00010 && a_rs1 == 0b00000)
	? "MRET    " : "SYSTEM   ";
    case 0b001: return "CSSRW   ";
    case 0b010: return "CSRRS   ";
    case 0b011: return "CSRRC   ";
    case 0b101: return "CSRRWI  ";
    case 0b110: return "CSRRSI  ";
    case 0b111: return "SYSTEM  ";
    }
  case 0b00011:
    switch (funct3) {
    case 0b001: return "FENCE.I ";
    default: return "MISC-MEM";
    }
  default: return "ILLEGAL ";
  }
}

#endif // __DISASM_H__
