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

        ; Example of calling NPV function
        JSR calculate_npv
        ; Example of calling LOOKUP function
        JSR lookup_value
        ; Example of calling ABS function
        JSR abs_value
        ; Example of calling INT function
        JSR int_value
        ; Example of calling EXP function
        JSR exp_value
        ; Example of calling LN function
        JSR ln_value
        ; Example of calling SIN function
        JSR sin_value

        JSR update_display       ; Update the display
        
    UNTIL check_exit_condition

    JMP MAIN_LOOP

check_exit_condition:
    ; Placeholder for condition check, always returning 0 for now
    LDA #0
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
    CMP #'C'         ; Check for Clear cell command
    BEQ clear_cell
    CMP #'R'         ; Check for Recalculate command
    BEQ recalculate
    CMP #'B'         ; Clear cell command /B
    BEQ clear_cell
    CMP #'D'         ; Delete row/column command /D
    BEQ delete_row_column
    CMP #'F'         ; Set display format command /F
    BEQ set_display_format
    CMP #'G'         ; Set column width /G
    BEQ set_column_width
    CMP #'S'         ; Save/Load command /S
    BEQ save_load
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

clear_cell:
    ; Clear the current cell
    LDX cursor_row
    LDY cursor_col
    ; Compute the address to clear data in cell_data
    LDA cursor_row
    ASL
    TAX
    LDA cursor_col
    ADC temp_pointer
    STA temp_pointer
    STA temp_pointer+1
    ; Clear the data in the specified cell
    LDA #0
    STA (temp_pointer,X)
    RTS

recalculate:
    ; Recalculate the entire sheet
    LDX #0
recalculate_loop:
    LDA cell_data,X
    CMP #TOKEN_SUM
    BEQ sum_function
    CMP #TOKEN_NUMBER
    BEQ evaluate_formula
    ; Add logic for other formula tokens
    INX
    CPX #$FF
    BNE recalculate_loop
    RTS

delete_row_column:
    ; Logic to delete row or column
    LDX cursor_row
    LDY cursor_col
    ; Clear the entire row or column starting from the current cell
delete_loop:
    LDA #0
    STA (current_node),Y
    INX
    CPX MAX_COLS
    BNE delete_loop
    RTS

set_display_format:
    ; Logic to set display format
    LDX cursor_row
    LDY cursor_col
    ; Set the display format for the cell
    ; Format code (1: General, 2: Integer, 3: Float, 4: Dollars)
    LDA #$01
    STA (current_node),Y
    RTS

set_column_width:
    ; Logic to set column width
    LDA cursor_col
    ASL
    TAX
    ; Column width setting
    LDA #10
    STA cell_data,X
    RTS

save_load:
    ; Logic for saving and loading
    JSR save_data
    JSR load_data
    RTS

save_data:
    ; Save data logic
    LDX #0
save_loop:
    LDA cell_data,X
    STA save_buffer,X
    INX
    CPX #$FF
    BNE save_loop
    RTS

load_data:
    ; Load data logic
    LDX #0
load_loop:
    LDA save_buffer,X
    STA cell_data,X
    INX
    CPX #$FF
    BNE load_loop
    RTS

handle_data_entry:
    ; Handle data entry into cells
    LDX cursor_row
    LDY cursor_col
    ; Compute the address to store data in cell_data
    LDA cursor_row
    ASL
    TAX
    LDA cursor_col
    ADC temp_pointer
    STA temp_pointer
    STA temp_pointer+1
    ; Store data from the keyboard buffer to the cell data
    LDA KBD
    STA (temp_pointer,X)
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
    LDA #0
    STA temp_pointer+1
    LDY #8
multiply_loop:
    LSR temp_pointer
    ROR temp_pointer+1
    LDA value_stack-1,Y
    BCC multiply_skip
    CLC
    ADC temp_pointer
    STA value_stack-1,Y
multiply_skip:
    DEY
    BNE multiply_loop
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
    LDA #0
    STA temp_pointer+1
    LDY #8
divide_loop:
    LSR temp_pointer
    ROR temp_pointer+1
    LDA value_stack-1,Y
    BCC divide_skip
    SEC
    SBC temp_pointer
    STA value_stack-1,Y
divide_skip:
    DEY
    BNE divide_loop
    RTS

init_screen:
    ; Clear the screen and set up initial display
    ; Apple II screen clear routine
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
    LDY #0
update_loop:
    LDA cell_data,Y
    JSR print_value
    INY
    CPY #$FF
    BNE update_loop
    RTS

print_value:
    ; Print a value from cell_data to the screen buffer
    LDA #0           ; Column index
    TAX
print_char:
    LDA cell_data,X
    BEQ print_done
    STA $0400,X      ; Example screen memory location
    INX
    JMP print_char

print_done:
    RTS

sum_function:
    ; Calculate the sum of a range of cells
    LDX cursor_row
    LDY cursor_col
    ; Iterate through the range and sum values
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
    ; Iterate through the range and sum values
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
    ; Iterate through the range and find minimum
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
    ; Iterate through the range and find maximum
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

; Function to calculate Net Present Value (NPV)
calculate_npv:
    LDA #0
    STA npv_result        ; Initialize NPV result to 0
    LDY #0
    STY cash_flow_index   ; Initialize index to 0
    LDX discount_rate     ; Load discount rate
    
npv_loop:
    LDA cash_flows,Y      ; Load cash flow
    BEQ npv_done          ; If zero, done
    CLC
    ADC discount_rate     ; Add discount rate
    STA discount_rate
    LDA cash_flows,Y
    SEC
    SBC discount_rate     ; Apply discount rate
    CLC
    ADC npv_result        ; Add to NPV result
    STA npv_result
    INY                   ; Increment index
    JMP npv_loop          ; Loop
    
npv_done:
    RTS

; Data for NPV function
npv_result: .byte 0
cash_flow_index: .byte 0
discount_rate: .byte 0
cash_flows: .res 32  ; Space for 32 cash flow entries

; Function to perform LOOKUP
lookup_value:
    LDA #0
    STA lookup_result     ; Initialize lookup result to 0
    LDY #0
    STY lookup_index      ; Initialize index to 0
    
lookup_loop:
    LDA lookup_range,Y    ; Load value from range
    CMP search_value      ; Compare with search value
    BEQ lookup_found      ; If equal, found
    INY                   ; Increment index
    BNE lookup_loop       ; Loop until zero
    
lookup_found:
    LDA lookup_range,Y    ; Load matched value
    STA lookup_result     ; Store in result
    RTS

; Data for LOOKUP function
lookup_result: .byte 0
lookup_index: .byte 0
search_value: .byte 0      ; Space for search value
lookup_range: .res 64  ; Space for lookup range

; Function to calculate absolute value (ABS)
abs_value:
    LDA abs_input
    BPL abs_done          ; If positive, done
    EOR #$FF
    ADC #1
abs_done:
    STA abs_result
    RTS

; Data for ABS function
abs_input: .byte 0      ; Space for input value
abs_result: .byte 0

; Function to calculate integer part (INT)
int_value:
    LDA int_input
    AND #$F0              ; Mask out the fractional part
    STA int_result
    RTS

; Data for INT function
int_input: .byte 0        ; Space for input value
int_result: .byte 0

; Function to calculate exponential (EXP)
exp_value:
    ; Simplified EXP function calculation
    LDA exp_input
    LDX #10
exp_loop:
    SEC
    SBC #1
    BNE exp_loop
    STA exp_result
    RTS

; Data for EXP function
exp_input: .byte 0         ; Space for input value
exp_result: .byte 0

; Function to calculate natural logarithm (LN)
ln_value:
    ; Simplified LN function calculation
    LDA ln_input
    LDX #10
ln_loop:
    CLC
    ADC #1
    BNE ln_loop
    STA ln_result
    RTS

; Data for LN function
ln_input: .byte 0          ; Space for input value
ln_result: .byte 0

; Function to calculate sine (SIN)
sin_value:
    ; Simplified SIN function calculation
    LDA sin_input
    LDX #10
sin_loop:
    CLC
    ADC #1
    BNE sin_loop
    STA sin_result
    RTS

; Data for SIN function
sin_input: .byte 0         ; Space for input value
sin_result: .byte 0
