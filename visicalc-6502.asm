; VisiCalc 6502 Consolidated Recreation

; Memory locations
current_node     = $20  ; Zero page location for current node pointer
himem            = $22  ; Zero page location for high memory pointer
wsm_bottom_cell  = $24  ; Zero page location for worksheet bottom cell
sheet_row_count  = $26  ; Location for sheet row count
cursor_row       = $28
cursor_col       = $29
temp_pointer     = $2A  ; 2 bytes
value_stack_ptr  = $2C

cell_data        = $4000  ; Start of cell data in memory
display_buffer   = $6000  ; Screen buffer
formula_buffer   = $7000  ; Temporary space for formula processing
rpn_buffer       = $7100  ; Buffer for Reverse Polish Notation
value_stack      = $7200  ; Stack for values during calculation

; Constants
MAX_ROWS         = 100
MAX_COLS         = 26
CELL_SIZE        = 16    ; Size of each cell record in bytes
MAX_FORMULA_LEN  = 64

TOKEN_NUMBER     = $01
TOKEN_PLUS       = $02
TOKEN_MINUS      = $03
TOKEN_MULTIPLY   = $04
TOKEN_DIVIDE     = $05
TOKEN_CELL_REF   = $06

; Apple II specific addresses
KBD              = $C000
KBDSTRB          = $C010

; Macro definitions
.MACRO DO
.DO_LOOP:
.ENDMACRO

.MACRO UNTIL condition
    {condition}
    BCC .DO_LOOP
.ENDMACRO

    .ORG $1000  ; Start address

MAIN:
    JSR init_system
    JMP MAIN_LOOP

init_system:
    JSR init_screen
    JSR clear_cell_data
    LDA #0
    STA cursor_row
    STA cursor_col
    LDA #MAX_ROWS
    STA sheet_row_count
    LDA #0
    STA sheet_row_count+1
    RTS

MAIN_LOOP:
    JSR zero_ptr_current_node    ; start in upper left
    JSR copy_pointer_to_wid      ; start out with this

    DO
        JSR poll_keyboard        ; not to lose keystrokes...

        ; Update current.node.row
        LDY #1                   ; Offset for row in node structure
        LDA (current_node),Y
        CLC
        ADC #1
        STA (current_node),Y
        BCC no_carry
        INY
        LDA (current_node),Y
        ADC #0
        STA (current_node),Y
    no_carry:

        JSR update_display
        JSR calculate_formulas

        ; Compare current.node.row with sheet_row_count
        LDA (current_node),Y
        CMP sheet_row_count
        LDA (current_node),Y
        SBC sheet_row_count+1
    UNTIL larger_or_equal

    JMP MAIN_LOOP

zero_ptr_current_node:
    LDA #0
    STA current_node
    STA current_node+1
    RTS

copy_pointer_to_wid:
    LDA himem
    STA wsm_bottom_cell
    LDA himem+1
    STA wsm_bottom_cell+1
    RTS

poll_keyboard:
    LDA KBD
    BPL no_key
    STA last_key
    BIT KBDSTRB
    JSR process_key
no_key:
    RTS

process_key:
    LDA last_key
    CMP #$1B        ; ESC key
    BEQ .handle_escape
    CMP #$0D        ; Enter key
    BEQ .handle_enter
    CMP #'='        ; Start of formula
    BEQ .start_formula
    JSR input_to_cell
    RTS

.handle_escape:
    ; Handle escape (e.g., cancel input)
    RTS

.handle_enter:
    JSR move_cursor_down
    RTS

.start_formula:
    JSR enter_formula_mode
    RTS

input_to_cell:
    JSR get_current_cell
    LDY #0
    LDA last_key
    STA (temp_pointer),Y
    JSR update_display
    RTS

get_current_cell:
    LDA cursor_row
    STA temp_pointer
    LDA cursor_col
    STA temp_pointer+1
    JSR calculate_cell_address
    RTS

calculate_cell_address:
    LDA cursor_row
    LDX #0
    LDY #CELL_SIZE
.mul_loop:
    CLC
    ADC temp_pointer
    BCC .no_carry
    INX
.no_carry:
    DEY
    BNE .mul_loop
    
    CLC
    ADC cursor_col
    STA temp_pointer
    TXA
    ADC #>cell_data
    STA temp_pointer+1
    RTS

move_cursor_down:
    INC cursor_row
    LDA cursor_row
    CMP #MAX_ROWS
    BCC .cursor_ok
    LDA #0
    STA cursor_row
.cursor_ok:
    JSR update_display
    RTS

enter_formula_mode:
    LDA #'='
    JSR input_to_cell
    RTS

update_display:
    JSR clear_display_buffer
    JSR draw_grid
    JSR display_cell_contents
    JSR highlight_current_cell
    JSR blit_to_screen
    RTS

clear_display_buffer:
    LDX #0
    LDA #' '
.clear_loop:
    STA display_buffer,X
    INX
    BNE .clear_loop
    RTS

draw_grid:
    LDX #0
.draw_loop:
    LDA #'+'
    STA display_buffer,X
    INX
    CPX #40
    BNE .draw_loop
    RTS

display_cell_contents:
    LDA #0
    STA cursor_row
.row_loop:
    LDA #0
    STA cursor_col
.col_loop:
    JSR get_current_cell
    JSR display_single_cell
    INC cursor_col
    LDA cursor_col
    CMP #MAX_COLS
    BCC .col_loop
    INC cursor_row
    LDA cursor_row
    CMP #MAX_ROWS
    BCC .row_loop
    RTS

display_single_cell:
    LDY #0
    LDA (temp_pointer),Y
    BEQ .empty_cell
    ; Calculate position in display buffer and store the cell content
    ; ... (implementation details)
.empty_cell:
    RTS

highlight_current_cell:
    ; Highlight the cell at cursor position in the display buffer
    ; ... (implementation details)
    RTS

blit_to_screen:
    ; Copy display_buffer to Apple II screen memory
    ; ... (implementation details)
    RTS

calculate_formulas:
    LDA #0
    STA cursor_row
.row_loop:
    LDA #0
    STA cursor_col
.col_loop:
    JSR get_current_cell
    JSR evaluate_cell
    INC cursor_col
    LDA cursor_col
    CMP #MAX_COLS
    BCC .col_loop
    INC cursor_row
    LDA cursor_row
    CMP #MAX_ROWS
    BCC .row_loop
    RTS

evaluate_cell:
    LDY #0
    LDA (temp_pointer),Y
    CMP #'='
    BNE .not_formula
    JSR parse_formula
    JSR evaluate_rpn
    JSR store_result
    RTS
.not_formula:
    RTS

parse_formula:
    LDY #1
    STY formula_index
    LDX #0
.parse_loop:
    LDA (temp_pointer),Y
    BEQ .end_formula
    JSR tokenize_char
    INY
    CPY #MAX_FORMULA_LEN
    BCC .parse_loop
.end_formula:
    LDA #0
    STA rpn_buffer,X
    RTS

tokenize_char:
    CMP #'+'
    BEQ .token_plus
    CMP #'-'
    BEQ .token_minus
    CMP #'*'
    BEQ .token_multiply
    CMP #'/'
    BEQ .token_divide
    CMP #'A'
    BCS .possible_cell_ref
    JMP .token_number

.token_plus:
    LDA #TOKEN_PLUS
    JMP .store_token
.token_minus:
    LDA #TOKEN_MINUS
    JMP .store_token
.token_multiply:
    LDA #TOKEN_MULTIPLY
    JMP .store_token
.token_divide:
    LDA #TOKEN_DIVIDE
    JMP .store_token

.possible_cell_ref:
    CMP #'Z'+1
    BCS .invalid_token
    JSR parse_cell_reference
    LDA #TOKEN_CELL_REF
    JMP .store_token

.token_number:
    JSR parse_number
    LDA #TOKEN_NUMBER
.store_token:
    STA rpn_buffer,X
    INX
    RTS

.invalid_token:
    RTS

parse_cell_reference:
    ; Convert A1 style reference to row/column numbers
    ; ... (implementation details)
    RTS

parse_number:
    ; Parse multi-digit number
    ; ... (implementation details)
    RTS

evaluate_rpn:
    LDX #0
    STX value_stack_ptr
.eval_loop:
    LDA rpn_buffer,X
    BEQ .eval_done
    CMP #TOKEN_NUMBER
    BEQ .push_number
    CMP #TOKEN_CELL_REF
    BEQ .push_cell_value
    JSR perform_operation
    INX
    JMP .eval_loop

.push_number:
    INX
    LDA rpn_buffer,X
    PHA
    INX
    LDA rpn_buffer,X
    LDY value_stack_ptr
    STA value_stack,Y
    INY
    PLA
    STA value_stack,Y
    INY
    STY value_stack_ptr
    INX
    JMP .eval_loop

.push_cell_value:
    INX
    LDA rpn_buffer,X
    STA temp_pointer
    INX
    LDA rpn_buffer,X
    STA temp_pointer+1
    JSR get_cell_value
    LDY value_stack_ptr
    STA value_stack,Y
    INY
    STY value_stack_ptr
    INX
    JMP .eval_loop

.eval_done:
    RTS

perform_operation:
    CMP #TOKEN_PLUS
    BEQ .do_add
    CMP #TOKEN_MINUS
    BEQ .do_subtract
    CMP #TOKEN_MULTIPLY
    BEQ .do_multiply
    CMP #TOKEN_DIVIDE
    BEQ .do_divide
    RTS

.do_add:
    JSR pop_two_values
    CLC
    LDA value1
    ADC value2
    TAY
    LDA value1+1
    ADC value2+1
    JMP push_result

.do_subtract:
    JSR pop_two_values
    SEC
    LDA value1
    SBC value2
    TAY
    LDA value1+1
    SBC value2+1
    JMP push_result

.do_multiply:
    JSR pop_two_values
    ; 16-bit multiplication routine
    ; ... (implementation details)
    JMP push_result

.do_divide:
    JSR pop_two_values
    ; 16-bit division routine
    ; ... (implementation details)
    JMP push_result

pop_two_values:
    LDY value_stack_ptr
    DEY
    LDA value_stack,Y
    STA value2+1
    DEY
    LDA value_stack,Y
    STA value2
    DEY
    LDA value_stack,Y
    STA value1+1
    DEY
    LDA value_stack,Y
    STA value1
    STY value_stack_ptr
    RTS

push_result:
    LDY value_stack_ptr
    STA value_stack,Y
    INY
    TYA
    STA value_stack,Y
    INY
    STY value_stack_ptr
    RTS

get_cell_value:
    ; Retrieve value from cell at temp_pointer
    ; ... (implementation details)
    RTS

store_result:
    ; Store result back in current cell
    ; ... (implementation details)
    RTS

clear_cell_data:
    LDX #0
    LDA #0
.clear_loop:
    STA cell_data,X
    INX
    BNE .clear_loop
    RTS

init_screen:
    ; Initialize Apple II screen
    ; ... (implementation details)
    RTS

larger_or_equal:
    ; This is implicitly handled by the UNTIL macro
    RTS

; Data section
last_key:        .BYTE 0
formula_mode:    .BYTE 0  ; 0 = normal mode, 1 = formula entry mode
value1:          .WORD 0
value2:          .WORD 0
formula_index:   .BYTE 0

