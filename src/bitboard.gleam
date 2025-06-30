import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import types.{type Bitboard, type Board}

//                     6 13 20 27 34 41 48
// 0 | . . . . . . .   5 12 19 26 33 40 47
// 1 | . . . . . . .   4 11 18 25 32 39 46
// 2 | . . . . . . .   3 10 17 24 31 38 45
// 3 | . . . O . . .   2  9 16 23 30 37 44
// 4 | . . . X X . .   1  8 15 22 29 36 43
// 5 | . . O X O . .   0  7 14 21 28 35 42
//     -------------
//     0 1 2 3 4 5 6

pub fn make_move(bitboard: Bitboard, col: Int) -> Result(Bitboard, Nil) {
  use height <- result.try(
    dict.get(bitboard.heights, col) |> fail_if_negative(),
  )
  let move = int.bitwise_shift_left(1, height)
  let heights =
    bitboard.heights
    |> dict.insert(col, case height == cordinate_to_lsb(col, 0) {
      True -> -1
      False -> height + 1
    })
  let player_boards = case int.bitwise_and(bitboard.counter, 1) {
    1 -> #(
      bitboard.player_boards.0,
      int.bitwise_or(bitboard.player_boards.1, move),
    )
    _ -> #(
      int.bitwise_or(bitboard.player_boards.0, move),
      bitboard.player_boards.1,
    )
  }
  let counter = bitboard.counter + 1
  Ok(types.Bitboard(player_boards:, counter:, heights:))
}

fn fail_if_negative(result: Result(Int, Nil)) -> Result(Int, Nil) {
  case result {
    Ok(x) if x < 0 -> Error(Nil)
    _ -> result
  }
}

pub fn to_board(bitboard: Bitboard) -> Board {
  dict.combine(
    player_n_board(1, bitboard.player_boards.0),
    player_n_board(2, bitboard.player_boards.1),
    fn(left, right) {
      dict.combine(left, right, fn(left_value, right_value) {
        left_value + right_value
      })
    },
  )
}

fn player_n_board(n: Int, player_bitboard: Int) -> Dict(Int, Dict(Int, Int)) {
  list.range(0, 5)
  |> list.map(fn(y) {
    let row =
      list.range(0, 6)
      |> list.map(fn(x) {
        let lsb_bit = int.bitwise_shift_left(1, cordinate_to_lsb(x, y))
        case int.bitwise_and(lsb_bit, player_bitboard) {
          0 -> #(x, 0)
          _ -> #(x, n)
        }
      })
      |> dict.from_list()
    #(y, row)
  })
  |> dict.from_list()
}

pub fn to_bitboard(board: Board) -> Bitboard {
  let player_boards = #(
    get_player_n_board(1, board),
    get_player_n_board(2, board),
  )
  let counter = get_move_count(board)
  let heights = get_heights(player_boards)
  types.Bitboard(player_boards:, counter:, heights:)
}

pub fn cordinate_to_lsb(x: Int, y: Int) -> Int {
  case y < 0 {
    True -> -1
    False -> { 5 + x * 7 } - y
  }
}

//                     6 13 20 27 34 41 48
// 0 | . . . . . . .   5 12 19 26 33 40 47
// 1 | . . . . . . .   4 11 18 25 32 39 46
// 2 | . . . . . . .   3 10 17 24 31 38 45
// 3 | . . . O . . .   2  9 16 23 30 37 44
// 4 | . . . X X . .   1  8 15 22 29 36 43
// 5 | . . O X O . .   0  7 14 21 28 35 42
//     -------------
//     0 1 2 3 4 5 6
pub fn get_heights(player_boards: #(Int, Int)) -> Dict(Int, Int) {
  let combined_board = int.bitwise_or(player_boards.0, player_boards.1)
  list.range(0, 6)
  |> list.map(fn(x) {
    let height =
      list.range(0, 5)
      |> list.fold_until(cordinate_to_lsb(x, 5), fn(acc, y) {
        let bit_at_xy = int.bitwise_shift_left(1, cordinate_to_lsb(x, y))
        case int.bitwise_and(combined_board, bit_at_xy) {
          0 -> list.Continue(acc)
          _ -> list.Stop(cordinate_to_lsb(x, y - 1))
        }
      })
    #(x, height)
  })
  |> dict.from_list()
}

fn get_player_n_board(n: Int, board: Board) -> Int {
  dict.to_list(board)
  |> list.fold(0, fn(col_acc, y_entry) {
    let y = y_entry.0
    let row = y_entry.1
    dict.to_list(row)
    |> list.fold(0, fn(row_acc, x_entry) {
      let x = x_entry.0
      let value = x_entry.1
      player_n_bit(n, value)
      |> int.bitwise_shift_left(cordinate_to_lsb(x, y))
      |> int.bitwise_exclusive_or(row_acc)
    })
    |> int.bitwise_exclusive_or(col_acc)
  })
}

fn player_n_bit(n: Int, value: Int) -> Int {
  case value == n {
    True -> 1
    False -> 0
  }
}

fn get_move_count(board: Board) -> Int {
  dict.fold(board, 0, fn(count, _row, cells) {
    count
    + dict.fold(cells, 0, fn(col_count, _col, value) {
      col_count
      + case value {
        0 -> 0
        _ -> 1
      }
    })
  })
}
