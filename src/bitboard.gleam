import gleam/bool
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

const two_in_a_row_weight = 1

const three_in_a_row_weight = 10

const win_weight = 10_000

const loss_weight = -10_000

const infinity = 1_000_000

const max_depth = 5

// 'Magic' shift by increments to determine if there are vertical or diagonal pieces in succession
// See https://github.com/denkspuren/BitboardC4/blob/master/BitboardDesign.md#are-there-four-in-a-row
const directions = [1, 6, 7, 8]

pub type MoveScore {
  MoveScore(column: Int, score: Int)
}

type MoveScoreWithAlpha {
  MoveScoreWithAlpha(column: Int, score: Int, alpha: Int)
}

type MoveScoreWithBeta {
  MoveScoreWithBeta(column: Int, score: Int, beta: Int)
}

pub fn minimax(bitboard: Bitboard) -> MoveScore {
  minimax_helper(bitboard, 0, -1 * infinity, infinity, -1)
}

fn minimax_helper(
  bitboard: Bitboard,
  depth: Int,
  alpha: Int,
  beta: Int,
  last_move: Int,
) -> MoveScore {
  let us = int.bitwise_and(bitboard.counter, 0)
  let them = int.bitwise_exclusive_or(us, 1)
  let our_board = case us {
    0 -> bitboard.player_boards.0
    _ -> bitboard.player_boards.1
  }
  let their_board = case them {
    0 -> bitboard.player_boards.0
    _ -> bitboard.player_boards.1
  }
  let maximizing = us == 0
  let maximizing_mult = case maximizing {
    True -> 1
    False -> -1
  }
  use <- bool.guard(depth == max_depth, MoveScore(last_move, score(bitboard)))
  use <- bool.guard(
    is_win(their_board),
    MoveScore(last_move, loss_weight * maximizing_mult),
  )
  use <- bool.guard(
    is_win(our_board),
    MoveScore(last_move, win_weight * maximizing_mult),
  )
  case maximizing {
    True -> {
      let best_move =
        list_moves(bitboard)
        |> list.fold_until(
          MoveScoreWithAlpha(-1, -1 * infinity, alpha),
          fn(best_move_score_with_alpha, move) {
            let assert Ok(bitboard_after_move) = make_move(bitboard, move)
            let move_score =
              minimax_helper(bitboard_after_move, depth + 1, alpha, beta, move)
            let best_score =
              int.max(move_score.score, best_move_score_with_alpha.score)
            let alpha = int.max(best_move_score_with_alpha.alpha, best_score)
            let new_best_move_score = case
              best_score == best_move_score_with_alpha.score
            {
              True -> best_move_score_with_alpha
              False ->
                MoveScoreWithAlpha(move_score.column, move_score.score, alpha)
            }
            case beta <= alpha {
              True -> list.Stop(new_best_move_score)
              False -> list.Continue(new_best_move_score)
            }
          },
        )
      MoveScore(best_move.column, best_move.score)
    }
    False -> {
      let best_move =
        list_moves(bitboard)
        |> list.fold_until(
          MoveScoreWithBeta(-1, infinity, beta),
          fn(best_move_score_with_beta, move) {
            let assert Ok(bitboard_after_move) = make_move(bitboard, move)
            let move_score =
              minimax_helper(bitboard_after_move, depth + 1, alpha, beta, move)
            let best_score =
              int.min(move_score.score, best_move_score_with_beta.score)
            let beta = int.min(best_move_score_with_beta.beta, best_score)
            let new_best_move_score = case
              best_score == best_move_score_with_beta.score
            {
              True -> best_move_score_with_beta
              False ->
                MoveScoreWithBeta(move_score.column, move_score.score, beta)
            }
            case beta <= alpha {
              True -> list.Stop(new_best_move_score)
              False -> list.Continue(new_best_move_score)
            }
          },
        )
      MoveScore(best_move.column, best_move.score)
    }
  }
}

fn score(bitboard: Bitboard) -> Int {
  // Maximizing player score - minimizing player score
  score_playerboard(bitboard.player_boards.0)
  - score_playerboard(bitboard.player_boards.1)
}

fn score_playerboard(player_board: Int) -> Int {
  two_in_a_row_weight
  * count_n_sequences_in_a_row(player_board, 2)
  + three_in_a_row_weight
  * count_n_sequences_in_a_row(player_board, 3)
  + case is_win(player_board) {
    True -> win_weight
    False -> 0
  }
}

pub fn list_moves(bitboard: Bitboard) -> List(Int) {
  bitboard.heights
  |> dict.filter(fn(_col, height) { height != -1 })
  |> dict.keys()
}

pub fn is_win(player_bitboard: Int) -> Bool {
  count_n_sequences_in_a_row(player_bitboard, 4) > 0
}

pub fn count_n_sequences_in_a_row(player_bitboard: Int, n: Int) -> Int {
  list.map(directions, fn(direction) {
    list.range(1, n - 1)
    |> list.fold(player_bitboard, fn(acc, i) {
      int.bitwise_and(
        acc,
        int.bitwise_shift_right(player_bitboard, i * direction),
      )
    })
  })
  |> list.map(count_set_bits)
  |> list.fold(0, int.add)
}

// Kernighan's bit counting algorithm
fn count_set_bits(num: Int) -> Int {
  case num > 0 {
    True -> 1 + count_set_bits(int.bitwise_and(num, num - 1))
    False -> 0
  }
}

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
      case value == n {
        True -> 1
        False -> 0
      }
      |> int.bitwise_shift_left(cordinate_to_lsb(x, y))
      |> int.bitwise_exclusive_or(row_acc)
    })
    |> int.bitwise_exclusive_or(col_acc)
  })
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
