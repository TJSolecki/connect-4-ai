import board
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import types.{type Board, type Msg, UserClickedColumn}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(board: Board)
}

fn init(_flags) -> Model {
  Model(board: create_board())
}

fn create_board() -> Board {
  create_row(create_row(0))
}

fn create_row(entry: value) -> Dict(Int, value) {
  dict.from_list(
    list.index_map(list.repeat(entry, 8), fn(elem, i) { #(i, elem) }),
  )
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UserClickedColumn(col) -> {
      echo col
      let column =
        model.board
        |> dict.to_list()
        |> list.map(fn(entry) {
          let row = entry.0
          #(row, dict.get(entry.1, col))
        })
        |> list.filter(fn(entry) { result.is_ok(entry.1) })
        |> list.map(fn(entry) { #(entry.0, result.unwrap(entry.1, 0)) })
      let row_to_update =
        column
        |> list.filter(fn(entry) { entry.1 == 0 })
        |> list.map(fn(entry) { entry.0 })
        |> list.max(int.compare)
      case row_to_update {
        Ok(row_index) -> {
          let row = dict.get(model.board, row_index)
          let updated_row =
            dict.insert(result.unwrap(row, dict.from_list([])), col, 1)
          Model(board: dict.insert(model.board, row_index, updated_row))
        }
        Error(_) -> {
          echo "Column " <> int.to_string(col) <> " is full"
          model
        }
      }
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("w-full flex justify-center mt-8")], [
    board.render(model.board),
  ])
}
