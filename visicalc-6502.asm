; VisiCalc 6502 Full Recreation

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
MAX_ROWS         = 254  ; VisiCalc's actual row limit
MAX_COLS         = 63   ; VisiCalc's actual column limit (A-BK)
CELL_SIZE        = 16   ; Size of each cell record in bytes
MAX_FORMULA_LEN  = 128

TOKEN_NUMBER     = $01
TOKEN_PLUS       = $02
TOKEN_MINUS      = $03
TOKEN_MULTIPLY   = $04
TOKEN_DIVIDE     = $05
TOKEN_CELL_REF   = $06
TOKEN_SUM        = $07
TOKEN_LEFT_PAREN = $08
TOKEN_RIGHT_PAREN = $09

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
    LDA #<MAX_ROWS
    STA sheet_row_count
    LDA #>MAX_ROWS
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
        
        ; Check if we've reached the bottom of the sheet
        LDA (current_node),Y
        CMP sheet_row_count
        BCS larger_or_equal      ; If current row >= sheet row count, exit loop
    UNTIL larger_or_equal
    JMP MAIN_LOOP

larger_or_equal:
    ; Handle completion of the loop
    RTS

poll_keyboard:
    LDA KBDSTRB      ; Read keyboard strobe
    BPL no_key       ; If no key pressed, branch
    LDA KBD          ; Get key code
    JSR process_key  ; Process key code
no_key:
    RTS

process_key:
    CMP #$1B         ; Check for ESC key
    BEQ exit_program
    CMP #$0D         ; Check for Enter key
    BEQ process_enter
    CMP #$1C         ; Check for Up Arrow
    BEQ move_cursor_up
    CMP #$1D         ; Check for Down Arrow
    BEQ move_cursor_down
    CMP #$1E         ; Check for Left Arrow
    BEQ move_cursor_left
    CMP #$1F         ; Check for Right Arrow
    BEQ move_cursor_right
    ; Handle other data entry
    JSR handle_data_entry
    RTS

process_enter:
    ; Handle Enter key press
    JSR evaluate_formula
    RTS

exit_program:
    JMP $FFFC        ; Jump to reset vector

move_cursor_up:
    DEC cursor_row
    JSR update_cursor_display
    RTS

move_cursor_down:
    INC cursor_row
    JSR update_cursor_display
    RTS

move_cursor_left:
    DEC cursor_col
    JSR update_cursor_display
    RTS

move_cursor_right:
    INC cursor_col
    JSR update_cursor_display
    RTS

handle_data_entry:
    ; Handle data entry into cells
    LDX cursor_row
    LDY cursor_col
    ; Compute the address to store data in cell_data
    LDA cursor_row
    ASL
    TAY
    LDA cursor_col
    ADC Y
    STA temp_pointer
    STA temp_pointer+1
    ; Store data from the keyboard buffer to the cell data
    LDA KBD
    STA (temp_pointer),Y
    RTS

evaluate_formula:
    ; Evaluate the formula in the current cell
    ; Convert infix notation to Reverse Polish Notation (RPN)
    ; Evaluate the RPN expression
    JSR parse_formula
    JSR compute_rpn
    RTS

parse_formula:
    ; Convert infix notation to RPN and store in rpn_buffer
    LDX #0
parse_loop:
    LDA formula_buffer,X
    CMP #'+'
    BEQ add_token_plus
    CMP #'-'
    BEQ add_token_minus
    CMP #'*'
    BEQ add_token_multiply
    CMP #'/'
    BEQ add_token_divide
    CMP #'0'
    BCS store_number
    INX
    CPX #MAX_FORMULA_LEN
    BNE parse_loop
    RTS

store_number:
    LDA #TOKEN_NUMBER
    STA rpn_buffer,X
    INX
    LDA formula_buffer,X
    STA rpn_buffer,X
    INX
    JMP parse_loop

add_token_plus:
    LDA #TOKEN_PLUS
    STA rpn_buffer,X
    INX
    JMP parse_loop

add_token_minus:
    LDA #TOKEN_MINUS
    STA rpn_buffer,X
    INX
    JMP parse_loop

add_token_multiply:
    LDA #TOKEN_MULTIPLY
    STA rpn_buffer,X
    INX
    JMP parse_loop

add_token_divide:
    LDA #TOKEN_DIVIDE
    STA rpn_buffer,X
    INX
    JMP parse_loop

compute_rpn:
    ; Compute the value of the RPN expression stored in rpn_buffer
    LDX #0
    LDY #0
compute_loop:
    LDA rpn_buffer,X
    CMP #TOKEN_NUMBER
    BEQ push_number
    CMP #TOKEN_PLUS
    BEQ perform_add
    CMP #TOKEN_MINUS
    BEQ perform_subtract
    CMP #TOKEN_MULTIPLY
    BEQ perform_multiply
    CMP #TOKEN_DIVIDE
    BEQ perform_divide
    INX
    CPX #MAX_FORMULA_LEN
    BNE compute_loop
    RTS

push_number:
    ; Push number onto the value stack
    LDA rpn_buffer,X
    STA value_stack,Y
    INY
    INX
    JMP compute_loop

perform_add:
    ; Perform addition
    DEY
    LDA value_stack,Y
    CLC
    ADC value_stack-1,Y
    STA value_stack-1,Y
    INX
    JMP compute_loop

perform_subtract:
    ; Perform subtraction
    DEY
    LDA value_stack,Y
    SEC
    SBC value_stack-1,Y
    STA value_stack-1,Y
    INX
    JMP compute_loop

perform_multiply:
    ; Perform multiplication
    DEY
    LDA value_stack,Y
    STA temp_pointer
    DEY
    LDA value_stack,Y
    JSR multiply
    STA value_stack,Y
    INX
    JMP compute_loop

multiply:
    ; Simple multiplication routine
    LDY #0
multiply_loop:
    LDA value_stack,Y
    CLC
    ADC temp_pointer
    TAY
    DEX
    BNE multiply_loop
    STA temp_pointer
    RTS

perform_divide:
    ; Perform division
    DEY
    LDA value_stack,Y
    STA temp_pointer
    DEY
    LDA value_stack,Y
    JSR divide
    STA value_stack,Y
    INX
    JMP compute_loop

divide:
    ; Simple division routine
    LDY #0
divide_loop:
    LDA value_stack,Y
    SEC
    SBC temp_pointer
    TAY
    DEX
    BNE divide_loop
    STA temp_pointer
    RTS

init_screen:
    ; Clear the screen and set up initial display
    ; Apple II screen clear routine (example)
    LDA #$0
    STA $C054        ; Clear screen memory
    STA $C057        ; Set text mode
    RTS

clear_cell_data:
    ; Clear memory allocated for cell data
    LDX #$00
clear_loop:
    STX cell_data,X
    INX
    CPX #$FF
    BNE clear_loop
    RTS

zero_ptr_current_node:
    ; Initialize the current node pointer to the top left of the sheet
    LDA #<cell_data
    STA current_node
    LDA #>cell_data
    STA current_node+1
    RTS

copy_pointer_to_wid:
    ; Copy the current node pointer to the display buffer
    LDY #0
copy_loop:
    LDA (current_node),Y
    STA display_buffer,Y
    INY
    CPY #CELL_SIZE
    BNE copy_loop
    RTS

update_display:
    ; Update the screen with the current worksheet data
    ; Copy display_buffer to screen memory
    LDY #0
update_loop:
    LDA display_buffer,Y
    STA $0400,Y     ; Example screen memory location
    INY
    CPY #$FF
    BNE update_loop
    RTS

update_cursor_display:
    ; Update the screen to show the cursor at the current position
    ; Example cursor display logic
    LDA cursor_row
    STA $D000        ; Example cursor row memory location
    LDA cursor_col
    STA $D001        ; Example cursor column memory location
    RTS

sum_function:
    ; Calculate the sum of a range of cells
    LDX cursor_row
    LDY cursor_col
    ; Simplified example assuming single row range for illustration
    LDA cursor_row
    ASL
    TAX
    LDA #0
    STA temp_pointer
    STA temp_pointer+1
sum_loop:
    LDA cell_data,X
    CLC
    ADC temp_pointer
    STA temp_pointer
    INX
    CPX cursor_col
    BNE sum_loop
    ; Store the sum in the current cell
    LDA temp_pointer
    STA cell_data,X
    RTS

avg_function:
    ; Calculate the average of a range of cells
    LDX cursor_row
    LDY cursor_col
    ; Simplified example assuming single row range for illustration
    LDA cursor_row
    ASL
    TAX
    LDA #0
    STA temp_pointer
    STA temp_pointer+1
    LDA #0
    STA value_stack
    LDA #1
    STA value_stack+1
avg_loop:
    LDA cell_data,X
    CLC
    ADC temp_pointer
    STA temp_pointer
    INX
    CPX cursor_col
    BNE avg_loop
    ; Calculate the average
    LDA temp_pointer
    SEC
    SBC value_stack
    STA temp_pointer
    ; Store the average in the current cell
    LDA temp_pointer
    STA cell_data,X
    RTS

min_function:
    ; Calculate the minimum of a range of cells
    LDX cursor_row
    LDY cursor_col
    ; Simplified example assuming single row range for illustration
    LDA cursor_row
    ASL
    TAX
    LDA cell_data,X
    STA temp_pointer
    INX
min_loop:
    LDA cell_data,X
    CMP temp_pointer
    BCS skip_min
    LDA cell_data,X
    STA temp_pointer
skip_min:
    INX
    CPX cursor_col
    BNE min_loop
    ; Store the minimum in the current cell
    LDA temp_pointer
    STA cell_data,X
    RTS

max_function:
    ; Calculate the maximum of a range of cells
    LDX cursor_row
    LDY cursor_col
    ; Simplified example assuming single row range for illustration
    LDA cursor_row
    ASL
    TAX
    LDA cell_data,X
    STA temp_pointer
    INX
max_loop:
    LDA cell_data,X
    CMP temp_pointer
    BCC skip_max
    LDA cell_data,X
    STA temp_pointer
skip_max:
    INX
    CPX cursor_col
    BNE max_loop
    ; Store the maximum in the current cell
    LDA temp_pointer
    STA cell_data,X
    RTS
