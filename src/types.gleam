import gleam/dict.{type Dict}

pub type Msg {
  UserClickedColumn(Int)
}

pub type Board =
  Dict(Int, Dict(Int, Int))
