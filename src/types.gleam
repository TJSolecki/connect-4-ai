import gleam/dict.{type Dict}

pub type Msg {
  UserClickedColumn(Int)
}

pub type Board =
  Dict(Int, Dict(Int, Int))

pub type Bitboard {
  Bitboard(player_boards: #(Int, Int), counter: Int, heights: Dict(Int, Int))
}
