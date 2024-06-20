=begin
    GridKid Project Runner (Milestone 3)
    Author: Ethan Baldwin
    Date: April 24, 2023
=end

require 'curses'
include Curses
require_relative 'expressions'
require_relative 'grid'
require_relative 'lexer'
require_relative 'parser'
require_relative 'error'

# Initial curses setup
Curses.init_screen
Curses.start_color
Curses.noecho

# Initialize constants
ROW_HEIGHT = 2      # includes bottom border
COL_WIDTH = 11      # includes right border
NUM_ROWS = ((Curses.lines - 5) / ROW_HEIGHT) - 1
NUM_COLS = ((Curses.cols - 1) / COL_WIDTH) - 1
GRID_HEIGHT = (ROW_HEIGHT * (NUM_ROWS + 1)) + 1
GRID_WIDTH = (COL_WIDTH * (NUM_COLS + 1)) + 1

class GridKid
    def initialize
        # Initialize globals
        grid = Grid.new
        @env = Environment.new(grid)
        @c_row = 1      # current row
        @c_col = 1      # current column
        @raw_grid = Hash.new
        @lexer = Lexer.new
        @parser = Parser.new

        # Initial grid setup
        @win_full = Curses::Window.new(0, 0, 0, 0)
        @win_editor = @win_full.subwin(3, GRID_WIDTH, 0, 0)
        @win_display = @win_full.subwin(1, GRID_WIDTH, 3, 0)
        @win_grid = @win_full.subwin(GRID_HEIGHT, GRID_WIDTH, 4, 0)
        @win_grid.keypad(true)
    end

    def execute
        # Actual execution
        grid_setup
        update_selected
        key = @win_grid.getch
        while key != 'q'
            case key
            when KEY_LEFT
                if @c_col > 1
                    unhighlight
                    @c_col -= 1
                end
            when KEY_RIGHT
                if @c_col < NUM_COLS
                    unhighlight
                    @c_col += 1
                end
            when KEY_UP
                if @c_row > 1
                    unhighlight
                    @c_row -= 1
                end
            when KEY_DOWN
                if @c_row < NUM_ROWS
                    unhighlight
                    @c_row += 1
                end
            when 10     # ENTER
                editor_mode
            end
            update_selected
            key = @win_grid.getch
        end
    end

    def grid_setup
        # Editor window setup
        @win_editor.box("|", "=")
        @win_editor.setpos(2, 0)
        @win_editor.addch('|')
        @win_editor.setpos(2, GRID_WIDTH - 1)
        @win_editor.addch('|')
    
        # Display window setup
        @win_display.setpos(0, 0)
        @win_display.addch('|')
        @win_display.setpos(0, GRID_WIDTH - 1)
        @win_display.addch('|')
    
        # Grid window setup
        @win_grid.box("|", "=")
        @win_grid.setpos(0, 0)
        @win_grid.addch('|')
        @win_grid.setpos(0, GRID_WIDTH - 1)
        @win_grid.addch('|')
    
        # Columns setup
        (1...(GRID_HEIGHT - 1)).each do |i|
            (1..NUM_COLS).each do |j|
                @win_grid.setpos(i, j * COL_WIDTH)
                @win_grid.addch('|')
            end
        end
    
        # Rows setup
        (1..NUM_ROWS).each do |i|
            @win_grid.setpos(i * ROW_HEIGHT, 1)
            @win_grid.addstr((('-' * (COL_WIDTH - 1)) + '+') * NUM_COLS)
            @win_grid.addstr('-' * (COL_WIDTH - 1))
        end
    
        # Column numbers setup
        (1..NUM_COLS).each do |j|
            @win_grid.setpos(ROW_HEIGHT / 2, (j * COL_WIDTH) + (COL_WIDTH / 2))
            @win_grid.addstr(j.to_s)
        end
    
        # Row numbers setup
        (1..NUM_ROWS).each do |i|
            @win_grid.setpos((i * ROW_HEIGHT) + (ROW_HEIGHT / 2), COL_WIDTH / 2)
            @win_grid.addstr(i.to_s)
        end
    
        @win_full.refresh
    end
    
    def set_actual_pos
        @win_grid.setpos((@c_row * ROW_HEIGHT) + 1, (@c_col * COL_WIDTH) + 1)
    end
    
    def highlight
        # Highlight top
        @win_grid.setpos(@c_row * ROW_HEIGHT, @c_col * COL_WIDTH)
        @win_grid.addstr('X' * (COL_WIDTH + 1))
    
        # Highlight bottom
        @win_grid.setpos((@c_row + 1) * ROW_HEIGHT, @c_col * COL_WIDTH)
        @win_grid.addstr('X' * (COL_WIDTH + 1))
    
        # Highlight left
        (1...ROW_HEIGHT).each do |i|
            @win_grid.setpos((@c_row * ROW_HEIGHT) + i, @c_col * COL_WIDTH)
            @win_grid.addch('X')
        end
    
        # Highlight right
        (1...ROW_HEIGHT).each do |i|
            @win_grid.setpos((@c_row * ROW_HEIGHT) + i, (@c_col + 1) * COL_WIDTH)
            @win_grid.addch('X')
        end
    
        set_actual_pos
    end
    
    def unhighlight
        # Unhighlight top
        @win_grid.setpos(@c_row * ROW_HEIGHT, @c_col * COL_WIDTH)
        @win_grid.addstr('+' + ('-' * (COL_WIDTH - 1)) + '+')
    
        # Unhighlight bottom
        @win_grid.setpos((@c_row + 1) * ROW_HEIGHT, @c_col * COL_WIDTH)
        if (@c_row >= NUM_ROWS)
            @win_grid.addstr('=' * (COL_WIDTH + 1))
        else
            @win_grid.addstr('+' + ('-' * (COL_WIDTH - 1)) + '+')
        end
    
        # Unhighlight left
        (1...ROW_HEIGHT).each do |i|
            @win_grid.setpos((@c_row * ROW_HEIGHT) + i, @c_col * COL_WIDTH)
            @win_grid.addch('|')
        end
    
        # Unhighlight right
        if (@c_col >= NUM_COLS)
            (0..ROW_HEIGHT).each do |i|
                @win_grid.setpos((@c_row * ROW_HEIGHT) + i, (@c_col + 1) * COL_WIDTH)
                @win_grid.addch('|')
            end
            if (@c_row >= NUM_ROWS)
                @win_grid.setpos((@c_row + 1) * ROW_HEIGHT, (@c_col + 1) * COL_WIDTH)
                @win_grid.addch('┘')
            end
        else
            (1...ROW_HEIGHT).each do |i|
                @win_grid.setpos((@c_row * ROW_HEIGHT) + i, (@c_col + 1) * COL_WIDTH)
                @win_grid.addch('|')
            end
        end
    
        set_actual_pos
    end
    
    def update_selected
        set_actual_pos
        highlight
    
        # Update editor window
        @win_editor.setpos(1, 2)
        if @raw_grid.key?([@c_row, @c_col])
            target_raw = @raw_grid.fetch([@c_row, @c_col])
            @win_editor.addstr(target_raw + (' ' * (GRID_WIDTH - target_raw.length - 3)))
        else
            @win_editor.addstr(' ' * (GRID_WIDTH - 3))
        end
        @win_editor.refresh
    
        # Update display window
        @env.reset_vars
        @win_display.setpos(0, 2)
        target_tree = @env.grid.get(@c_row, @c_col)
        if target_tree != nil
            target_evaluated = target_tree.evaluate(@env)
            if target_evaluated.class != String
                target_evaluated = target_tree.evaluate(@env).val.to_s
            end
            @win_display.addstr(target_evaluated + (' ' * (GRID_WIDTH - target_evaluated.length - 3)))
        else
            @win_display.addstr(' ' * (GRID_WIDTH - 3))
        end
        @win_display.refresh
    
        # Update grid
        update_grid(@c_row, @c_col)
        @win_grid.refresh
    end
    
    def update_grid(row, col)
        @env.reset_vars
        @win_grid.setpos((row * ROW_HEIGHT) + 1, (col * COL_WIDTH) + 1)
        target_tree = @env.grid.get(row, col)
        if target_tree != nil
            target_evaluated = target_tree.evaluate(@env)
            if target_evaluated.class != String
                target_on_grid = target_evaluated.val.to_s
                if target_on_grid.length >= COL_WIDTH
                    target_on_grid = target_on_grid[0, COL_WIDTH - 4] + "..."
                else
                    target_on_grid = target_on_grid[0, COL_WIDTH - 1]
                end
                @win_grid.addstr(target_on_grid + (' ' * (COL_WIDTH - target_on_grid.length - 1)))
            else
                @win_grid.addstr("error     ")
            end
        else
            @win_grid.addstr(' ' * (COL_WIDTH - 1))
        end
        set_actual_pos
    end
    
    def editor_mode
        # On entrance
        @env.reset_vars
        @win_editor.box("X", "X")
        ed_string = ""
        if @raw_grid.key?([@c_row, @c_col])
            ed_string = @raw_grid.fetch([@c_row, @c_col])
        end
        @win_editor.setpos(1, 2 + ed_string.length)
    
        # Main loop
        key = @win_editor.getch
        while key != 10     # ENTER
            if key == 8 && ed_string.length != 0
                @win_editor.addstr("\b \b")
                ed_string.slice!(ed_string.length - 1)
            elsif key != 8
                @win_editor.addch(key)
                ed_string << key
            end
            key = @win_editor.getch
        end
    
        # On exit
        if ed_string.length == 0
            @raw_grid.delete([@c_row, @c_col])
            @env.grid.delete(@c_row, @c_col)
        elsif ed_string[0] == '='
            @raw_grid.store([@c_row, @c_col], ed_string)
            tree = @parser.parse(@lexer.lex(ed_string[1, ed_string.length - 1]))
            @env.grid.set(@c_row, @c_col, tree)
        else
            @raw_grid.store([@c_row, @c_col], ed_string)
            lex_test = @lexer.lex(ed_string)
            if lex_test.class == Error || lex_test.length != 1 || lex_test[0][:type] == Variable
                @env.grid.set(@c_row, @c_col, StringPrimitive.new(ed_string, 0, ed_string.length - 1))
            else
                parse_test = @parser.parse(lex_test)
                if parse_test.class == Error
                    @env.grid.set(@c_row, @c_col, StringPrimitive.new(ed_string, 0, ed_string.length - 1))
                else
                    @env.grid.set(@c_row, @c_col, parse_test)
                end
            end
        end
        
        # Update all grid cells
        (1..NUM_ROWS).each do |i|
            (1..NUM_COLS).each do |j|
                update_grid(i, j)
            end
        end
    
        # Reformat
        @win_editor.box("|", "=")
        @win_editor.setpos(2, 0)
        @win_editor.addch('|')
        @win_editor.setpos(2, GRID_WIDTH - 1)
        @win_editor.addch('|')
        @win_editor.refresh
    end
end

# Create and execute program
runner = GridKid.new
runner.execute 