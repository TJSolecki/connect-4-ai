import bitboard
import connect_four_ai
import gleam/dict
import gleam/result
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn position_to_0_0_lsb_test() {
  assert bitboard.cordinate_to_lsb(0, 0) == 5
}

pub fn position_to_6_5_lsb_test() {
  assert bitboard.cordinate_to_lsb(6, 5) == 42
}

pub fn position_to_6_0_lsb_test() {
  assert bitboard.cordinate_to_lsb(6, 0) == 47
}

pub fn position_to_3_4_lsb_test() {
  assert bitboard.cordinate_to_lsb(3, 4) == 22
}

pub fn empty_board_test() {
  assert connect_four_ai.create_board()
    == connect_four_ai.create_board()
    |> bitboard.to_bitboard()
    |> bitboard.to_board()
}

pub fn to_bitboard_row_one_test() {
  let board =
    connect_four_ai.create_board()
    |> dict.insert(
      5,
      dict.from_list([
        #(0, 1),
        #(1, 2),
        #(2, 0),
        #(3, 0),
        #(4, 0),
        #(5, 0),
        #(6, 0),
      ]),
    )
  assert board == bitboard.to_bitboard(board) |> bitboard.to_board()
}

pub fn to_bitboard_row_two_test() {
  let empty_board = connect_four_ai.create_board()
  let assert Ok(row_four) = dict.get(empty_board, 4)
  let board =
    empty_board
    |> dict.insert(
      5,
      dict.from_list([
        #(0, 1),
        #(1, 2),
        #(2, 2),
        #(3, 2),
        #(4, 1),
        #(5, 1),
        #(6, 1),
      ]),
    )
    |> dict.insert(4, dict.insert(row_four, 0, 1))
  assert board == bitboard.to_bitboard(board) |> bitboard.to_board()
}

pub fn counter_and_heights_test() {
  let empty_board = connect_four_ai.create_board()
  let assert Ok(row_four) = dict.get(empty_board, 4)
  let board =
    empty_board
    |> dict.insert(
      5,
      dict.from_list([
        #(0, 1),
        #(1, 2),
        #(2, 2),
        #(3, 2),
        #(4, 1),
        #(5, 1),
        #(6, 1),
      ]),
    )
    |> dict.insert(4, dict.insert(row_four, 0, 1))
  let actual_bitboard = bitboard.to_bitboard(board)
  assert actual_bitboard.counter == 8
  assert actual_bitboard.heights
    == dict.from_list([
      #(0, 2),
      #(1, 8),
      #(2, 15),
      #(3, 22),
      #(4, 29),
      #(5, 36),
      #(6, 43),
    ])
}

pub fn max_heights_test() {
  let board = connect_four_ai.create_row(connect_four_ai.create_row(1, 7), 6)
  let actual_bitboard = bitboard.to_bitboard(board)
  assert actual_bitboard.heights
    == dict.from_list([
      #(0, -1),
      #(1, -1),
      #(2, -1),
      #(3, -1),
      #(4, -1),
      #(5, -1),
      #(6, -1),
    ])
}

pub fn make_move_test() {
  let board = connect_four_ai.create_board()
  let empty_bitboard = bitboard.to_bitboard(board)
  let assert Ok(after_move) = bitboard.make_move(empty_bitboard, 0)
  assert dict.get(after_move.heights, 0) == Ok(1)
  assert after_move.player_boards.0 == 1
  assert after_move.player_boards.1 == 0
  assert after_move.counter == 1
  let assert Ok(after_second_move) = bitboard.make_move(after_move, 0)
  assert dict.get(after_second_move.heights, 0) == Ok(2)
  assert after_second_move.player_boards.0 == 1
  assert after_second_move.player_boards.1 == 2
  assert after_second_move.counter == 2
  let assert Ok(after_third_move) = bitboard.make_move(after_second_move, 0)
  let assert Ok(after_fourth_move) = bitboard.make_move(after_third_move, 0)
  let assert Ok(after_fifth_move) = bitboard.make_move(after_fourth_move, 0)
  let assert Ok(after_sixth_move) = bitboard.make_move(after_fifth_move, 0)
  assert dict.get(after_sixth_move.heights, 0) == Ok(-1)
  assert bitboard.make_move(after_sixth_move, 0) == Error(Nil)
}

pub fn is_win_test() {
  let assert Ok(board) =
    connect_four_ai.create_board()
    |> bitboard.to_bitboard()
    |> Ok()
    |> result.try(bitboard.make_move(_, 0))
    |> result.try(bitboard.make_move(_, 1))
    |> result.try(bitboard.make_move(_, 0))
    |> result.try(bitboard.make_move(_, 1))
    |> result.try(bitboard.make_move(_, 0))
    |> result.try(bitboard.make_move(_, 1))
  assert bitboard.is_win(board.player_boards.0) == False
  assert bitboard.is_win(board.player_boards.1) == False
  // up/down player 1
  let assert Ok(board) =
    connect_four_ai.create_board()
    |> bitboard.to_bitboard()
    |> Ok()
    |> result.try(bitboard.make_move(_, 0))
    |> result.try(bitboard.make_move(_, 1))
    |> result.try(bitboard.make_move(_, 0))
    |> result.try(bitboard.make_move(_, 1))
    |> result.try(bitboard.make_move(_, 0))
    |> result.try(bitboard.make_move(_, 1))
    |> result.try(bitboard.make_move(_, 0))
  assert bitboard.is_win(board.player_boards.0)
  assert bitboard.is_win(board.player_boards.1) == False
  // up/down player 2
  let assert Ok(board) =
    connect_four_ai.create_board()
    |> bitboard.to_bitboard()
    |> Ok()
    |> result.try(bitboard.make_move(_, 0))
    |> result.try(bitboard.make_move(_, 1))
    |> result.try(bitboard.make_move(_, 0))
    |> result.try(bitboard.make_move(_, 1))
    |> result.try(bitboard.make_move(_, 0))
    |> result.try(bitboard.make_move(_, 1))
    |> result.try(bitboard.make_move(_, 2))
    |> result.try(bitboard.make_move(_, 1))
  assert bitboard.is_win(board.player_boards.0) == False
  assert bitboard.is_win(board.player_boards.1)
  // diagonal
  let assert Ok(board) =
    connect_four_ai.create_board()
    |> bitboard.to_bitboard()
    |> Ok()
    |> result.try(bitboard.make_move(_, 0))
    |> result.try(bitboard.make_move(_, 1))
    |> result.try(bitboard.make_move(_, 1))
    |> result.try(bitboard.make_move(_, 2))
    |> result.try(bitboard.make_move(_, 2))
    |> result.try(bitboard.make_move(_, 3))
    |> result.try(bitboard.make_move(_, 2))
    |> result.try(bitboard.make_move(_, 3))
    |> result.try(bitboard.make_move(_, 3))
    |> result.try(bitboard.make_move(_, 5))
    |> result.try(bitboard.make_move(_, 3))
  assert bitboard.is_win(board.player_boards.0)
  assert bitboard.is_win(board.player_boards.1) == False
}
