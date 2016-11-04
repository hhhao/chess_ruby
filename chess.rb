# coding: utf-8
class Chess
  def initialize
    @board = Array.new(8) { Array.new(8) }
    @current_move_side = :w
    @history = [] #[[from,to,:move_type,option,eat?],[from2,to2,:move_type2,option,eat?]...]
    @hist_index = 0
    # King will always be at index 4 for pieces array
    @pieces = Array.new(2)
    for i in 0..1
      @pieces[i] = [Rook.new, Knight.new, Bishop.new, Queen.new, King.new, Bishop.new, Knight.new, Rook.new, Pawn.new, Pawn.new, Pawn.new, Pawn.new, Pawn.new, Pawn.new, Pawn.new, Pawn.new]
    end
    for c in 0..7
      for i in 0..1
        color = i == 0 ? :w : :b
        y_cord0 = i == 0 ? 0 : 7
        y_cord1 = y_cord0 - 2 * i + 1
        @pieces[i][c].color = color
        @pieces[i][c].loc = [c, y_cord0]
        @board[c][y_cord0] = @pieces[i][c]
        @pieces[i][c+8].color = color
        @pieces[i][c+8].loc = [c, y_cord1]
        @board[c][y_cord1] = @pieces[i][c+8]
      end
    end
    @dead_pieces = [[], []]
    @promoted_pieces = [[], []]
    @resign = false
  end

  def start
    while !checkmate_stalemate?
      input_array = [[],[]]
      loop do
        draw_board
        puts "#{color_to_word(@current_move_side)}'s move: (eg:b1c3/[b]ack/[f]orward/[r]esign)"
        break if getinput(input_array)
      end
      if @resign
        puts "#{color_to_word(opposite_color(@current_move_side))} wins!"
        return false
      end
      move(input_array[0], input_array[1], nil)
    end
    draw_board
  end

  def getinput(input_array)
    raw_input = gets.chomp.downcase
    input = []
    input[0] = raw_input[0..1]
    input[1] = raw_input[-2..-1]
    return false if input[0].length < 1
    if ['b', 'f', 'r'].include? input[0]
      if input[0] == 'b' && @hist_index > 0
        back_one_move
      elsif input[0] == 'f' && @history[@hist_index] != nil
        forward_one_move
      elsif input[0] == 'r'
        @resign = true
        return true
      else
        puts "No available move in history!"
      end
      return false
    end
    for i in 0..1
      unless input[i][0].ord <= 'h'.ord && input[i][0].ord >= 'a'.ord && input[i][1].to_i <= 8 && input[i][1].to_i >= 1
        puts "Invalid Input!"
        return false
      end
    end
    input_array[0][0] = input[0][0].ord - 'a'.ord
    input_array[0][1] = input[0][1].to_i - 1
    input_array[1][0] = input[1][0].ord - 'a'.ord
    input_array[1][1] = input[1][1].to_i - 1
    return true
  end

  def draw_board
    print "  A B C D E F G H    "
    @dead_pieces[0].each { |d| print "#{piece_display(d.class, d.color)} " }
    print "\n"
    for y in 7.downto(0)
      print "#{y+1}|"
      for x in 0..7
        piece = @board[x][y]
        if piece == nil
          print '_|'
        else
          print "#{piece_display(piece.class, piece.color)}|"
        end
      end
      print "#{y+1}\n"
    end
    print "  A B C D E F G H    "
    @dead_pieces[1].each { |d| print "#{piece_display(d.class, d.color)} " }
    print "\n"
  end

  def piece_display(p_class, p_color)
    return (p_color == :w) ? '♔' : '♚' if p_class == King
    return (p_color == :w) ? '♕' : '♛' if p_class == Queen
    return (p_color == :w) ? '♖' : '♜' if p_class == Rook
    return (p_color == :w) ? '♘' : '♞' if p_class == Knight
    return (p_color == :w) ? '♗' : '♝' if p_class == Bishop
    return (p_color == :w) ? '♙' : '♟' if p_class == Pawn
  end

  def color_to_word(color)
    return (color == :w) ? 'White' : 'Black'
  end

  def eat(loc)
    piece = @board[loc[0]][loc[1]]
    @board[loc[0]][loc[1]] = nil
    piece.alive = false
    @dead_pieces[color_to_index(piece.color)] << piece
  end

  def uneat(piece)
    @board[piece.loc[0]][piece.loc[1]] = piece
    piece.alive = true
  end

  def promote(pawn, option)
    if option == nil
      puts "Piece to promote your pawn to? ([q]ueen/[r]ook/[k]night/[b]ishop)"
      promo = gets.chomp
      until promo == 'q' || promo == 'r' || promo == 'k' || promo == 'b'
        puts "Please enter valid choice: ([q]ueen/[r]ook/[k]night/[b]ishop)"
        promo = gets.chomp
      end
    else
      promo = option
    end
    if promo == 'q'
      promote_to = Queen.new
    elsif promo == 'r'
      promote_to = Rook.new
    elsif promo == 'k'
      promote_to = Knight.new
    elsif promo == 'b'
      promote_to = Bishop.new
    end
    promote_to.loc = pawn.loc
    promote_to.color = pawn.color
    promote_to.moves = pawn.moves
    @promoted_pieces[color_to_index(pawn.color)] << pawn
    @board[pawn.loc[0]][pawn.loc[1]] = promote_to
    i = color_to_index(pawn.color)
    @pieces[i][@pieces[i].index(pawn)] = promote_to
    return [promote_to, promo]
  end

  def unpromote(pawn, piece) #from piece back to pawn
    @board[pawn.loc[0]][pawn.loc[1]] = pawn
    i = color_to_index(piece.color)
    @pieces[i][@pieces[i].index(piece)] = pawn
  end

  def castle(dest)
    y = dest[1]
    if dest[0] == 2
      pos_switch([0, y], [3, y])
      @board[3][y].moves += 1
    elsif dest[0] == 6
      pos_switch([7, y], [5, y])
      @board[5][y].moves += 1
    end
  end

  def uncastle(king_to_loc)
    p_x = king_to_loc[0]
    p_y = king_to_loc[1]
    if p_x == 2
      pos_switch([3, p_y], [0, p_y])
      @board[0][p_y].moves -= 1
    elsif p_x == 6
      pos_switch([5, p_y], [7, p_y])
      @board[7][p_y].moves -= 1
    end
  end

  def color_to_index(color)
    return (color == :w ? 0 : 1)
  end

  def opposite_color(color)
    return color == :w ? :b : :w
  end

  def loc_under_attack?(loc, color)
    i = color_to_index(opposite_color(color))
    @pieces[i].each do |p|
      return true if p.alive && legal_move?(p.class, p.loc, loc)
    end
    return false
  end


  def in_check?(color)
    if loc_under_attack?(@pieces[color_to_index(color)][4].loc, color)
      return true
    else
      return false
    end
  end

  def pos_switch(curr, dest)
    @board[curr[0]][curr[1]].loc = dest
    @board[dest[0]][dest[1]] = @board[curr[0]][curr[1]]
    @board[curr[0]][curr[1]] = nil
  end

  def move(curr, dest, option)
    return false if (piece = @board[curr[0]][curr[1]]) == nil
    if piece.color == @current_move_side
      if (m = legal_move?(piece.class, curr, dest))
        @history[@hist_index] = [curr, dest, m, option, false]
        if piece_color_at_loc(dest) != nil
          eat(dest)
          @history[@hist_index][-1] = true
        end
        if m == :promotion
          promo_array = promote(piece, option)
          piece = promo_array[0]
          @history[@hist_index][3] = promo_array[1]
        elsif m == :en_passant
          @history[@hist_index][-1] = true
          pawn_eat_y = dest[1] + (piece.color == :w ? -1 : 1)
          eat([dest[0], pawn_eat_y])
        elsif m == :castle
          castle(dest)
        end
        @hist_index += 1
        piece.moves += 1
        pos_switch(curr, dest)
        @current_move_side = opposite_color(@current_move_side)
        if in_check?(piece.color)
          back_one_move()
          return false
        end
        return true
      end
    else
      puts 'Please select a valid piece!'
      return false
    end
  end

  def back_one_move()
    @current_move_side = opposite_color(@current_move_side)
    @hist_index -= 1
    last_move = @history[@hist_index]    #[from,to,:move_type,eat?]
    piece = @board[last_move[1][0]][last_move[1][1]]
    piece.moves -= 1
    pos_switch(last_move[1], last_move[0])
    if last_move[-1]
      dead = @dead_pieces[color_to_index(opposite_color(piece.color))].pop
      uneat(dead)
    end
    if last_move[2] == :promotion
      pawn = @promoted_pieces[color_to_index(piece.color)].pop
      unpromote(pawn, piece)
    elsif last_move[2] == :castle
      uncastle(last_move[1])
    end
  end

  def forward_one_move()
    next_move = @history[@hist_index]
    move(next_move[0], next_move[1], next_move[3])
  end

  def checkmate_stalemate?
    @pieces[color_to_index(@current_move_side)].each { |p|
      if p.alive
        for x in 0..7
          for y in 0..7
            if move(p.loc, [x, y], 'q')
              back_one_move
              return false
            end
          end
        end
      end
    }
    if in_check?(@current_move_side)
      puts "Checkmate! #{color_to_word(opposite_color(@current_move_side))} wins!"
    else
      puts "Stalemate! Draw!"
    end
    return true
  end

  def legal_move?(pclass, curr, dest)
    if locs_in_bounds?(curr,dest) && unobstructed_path?(curr,dest)
      if pclass == Chess::King
        if castle_path?(curr, dest)
          return :castle
        elsif king_path?(curr, dest)
          return :move
        end
      elsif pclass == Chess::Queen && (diagonal_path?(curr, dest) || straight_path?(curr, dest))
        return :move
      elsif pclass == Chess::Rook && straight_path?(curr, dest)
        return :move
      elsif pclass == Chess::Knight && knight_path?(curr, dest)
        return :move
      elsif pclass == Chess::Bishop && diagonal_path?(curr, dest)
        return :move
      elsif pclass == Chess::Pawn
        if promotion_path?(curr, dest)
          return :promotion
        elsif en_passant_path?(curr, dest)
          return :en_passant
        elsif pawn_path?(curr, dest)
          return :move
        end
      end
    end
    return false
  end

  def promotion_path?(curr, dest)
    pawn = @board[curr[0]][curr[1]]
    dir = pawn.color == :w ? 1 : -1
    if dest[1] - curr[1] == dir && (dest[1] == 0 || dest[1] == 7)
      if (dest[0] - curr[0] == 0 && piece_color_at_loc(dest) == nil) || ((dest[0] - curr[0]).abs == 1 && piece_color_at_loc(dest) == opposite_color(pawn.color))
        return true
      end
    end
    return false
  end

  def castle_path?(curr, dest)
    piece = @board[curr[0]][curr[1]]
    if piece.class == Chess::King && piece.moves == 0 && dest[1] == curr[1]
      if dest[0] - curr[0] == -2 && (left_rook = @pieces[color_to_index(piece.color)][0]).moves == 0 && unobstructed_path?(curr, [left_rook.loc[0]+1, left_rook.loc[1]])
        for i in curr[0].downto(curr[0]-2)
          return false if loc_under_attack?([i, curr[1]], piece.color)
        end
        return true
      elsif dest[0] - curr[0] == 2 && (right_rook = @pieces[color_to_index(piece.color)][7]).moves == 0 && unobstructed_path?(curr, [right_rook.loc[0]-1, right_rook.loc[1]])
        for i in curr[0]..curr[0]+2
          return false if loc_under_attack?([i, curr[1]], piece.color)
        end
        return true
      end
    end
    return false
  end

  def en_passant_path?(curr,dest)
    piece = @board[curr[0]][curr[1]]
    dir = piece.color == :w ? 1 : -1
    if (dest[0] - curr[0]).abs == 1 && dest[1] - curr[1] == dir #if move diagonally 1 sqr
      if piece_color_at_loc(dest) == nil && @history[@hist_index - 1] != nil
        last_move_from = @history[@hist_index - 1][0]
        last_move_to = @history[@hist_index - 1][1]
        if @board[last_move_to[0]][last_move_to[1]].class == Chess::Pawn && (last_move_to[0] - last_move_from[0]) == 0 && (last_move_to[1] - last_move_from[1]) == -2 * dir
          if dest[0] == last_move_from[0] && dest[1] == last_move_to[1] + dir
            return true
          end
        end
      end
    end
    return false
  end

  def pawn_path?(curr,dest)
    piece = @board[curr[0]][curr[1]]
    dir = (piece.color == :w ? 1 : -1)
    if dest[1] - curr[1] == dir && dest[0] - curr[0] == 0 && @board[dest[0]][dest[1]] == nil
      return true
    elsif piece.moves == 0 && (dest[0] - curr[0]).abs == 0 && (dest[1] - curr[1]).abs == 2 && @board[dest[0]][dest[1]] == nil
      return true
    elsif (dest[0] - curr[0]).abs == 1 && dest[1] - curr[1] == dir && piece_color_at_loc(dest) == (opposite_color(piece.color)) # if move dia 1 sqr to opposite color
      return true
    end
    return false
  end

  def king_path?(curr, dest)
    if (dest[0] - curr[0]).abs <= 1 && (dest[1] - curr[1]).abs <= 1
      return true
    else
      return false
    end
  end

  def diagonal_path?(curr, dest)
    if (curr[0] - dest[0]).abs == (curr[1] - dest[1]).abs
      return true
    else
      return false
    end
  end

  def straight_path?(curr, dest)
    for i in 0..1
      if curr[i] == dest[i]
        return true
      end
    end
    return false
  end

  def knight_path?(curr, dest)
    for i in 0..1
      if (curr[i] - dest[i]).abs == 2 && (curr[1-i] - dest[1-i]).abs == 1
        return true
      end
    end
    return false
  end

  def locs_in_bounds?(*locs)
    locs.each { |loc|
      for i in 0..1
        if loc[i] < 0 || loc[i] > 7
          return false
        end
      end
    }
    return true
  end

  def piece_color_at_loc(loc)
    if @board[loc[0]][loc[1]] == nil
      return nil
    else
      return @board[loc[0]][loc[1]].color
    end
  end

  def unobstructed_path?(curr,dest)
    if piece_color_at_loc(curr) == piece_color_at_loc(dest)
      return false
    else
      if straight_path?(curr,dest)
        for i in 0..1
          if curr[i] == dest[i]
            path = curr[1-i] < dest[1-i] ? (curr[1-i]+1...dest[1-i]) : (curr[1-i]-1).downto(dest[1-i]+1)
            if i == 0
              path.each { |p|
                return false unless @board[curr[0]][p].nil?
              }
            else
              path.each { |p|
                return false unless @board[p][curr[1]].nil?
              }
            end
          end
        end
        return true
      elsif diagonal_path?(curr, dest)
        x_change = dest[0] - curr[0]
        y_change = dest[1] - curr[1]
        x_inc = x_change / x_change.abs
        y_inc = y_change / y_change.abs
        x = curr[0] + x_inc
        y = curr[1] + y_inc
        while (x - dest[0]).abs > 0 && (y - dest[1]).abs > 0
          if @board[x][y] != nil
            return false
          end
          x += x_inc
          y += y_inc
        end
        return true
      elsif knight_path?(curr, dest)
        return true
      end
    end
    return false
  end

  class King
    attr_accessor :color
    attr_accessor :loc
    attr_accessor :moves
    attr_accessor :alive
    attr_reader :sign
    def initialize
      @moves = 0
      @sign = '♔'
      @alive = true
    end
  end

  class Queen
    attr_accessor :color
    attr_accessor :loc
    attr_accessor :moves
    attr_accessor :alive
    attr_reader :sign
    def initialize
      @alive = true
      @sign = 'Q'
      @moves = 0
    end
  end

  class Rook
    attr_accessor :color
    attr_accessor :loc
    attr_accessor :moves
    attr_accessor :alive
    attr_reader :sign
    def initialize
      @moves = 0
      @sign = 'R'
      @alive = true
    end
  end

  class Knight
    attr_accessor :color
    attr_accessor :loc
    attr_accessor :moves
    attr_accessor :alive
    attr_reader :sign
    def initialize
      @alive = true
      @sign = 'N'
      @moves = 0
    end
  end

  class Bishop
    attr_accessor :color
    attr_accessor :loc
    attr_accessor :moves
    attr_accessor :alive
    attr_reader :sign
    def initialize
      @alive = true
      @sign = 'B'
      @moves = 0
    end
  end

  class Pawn
    attr_accessor :color
    attr_accessor :loc
    attr_accessor :moves
    attr_accessor :alive
    attr_reader :sign
    def initialize
      @alive = true
      @sign = 'P'
      @moves = 0
    end
  end
end
############################################################

chess = Chess.new
chess.start
