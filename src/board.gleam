import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/keyed
import lustre/event
import types.{type Msg, UserClickedColumn}

pub fn render(board: Dict(Int, Dict(Int, Int))) -> Element(Msg) {
  keyed.div(
    [
      attribute.class("grid gap-[1px]"),
      attribute.style("grid-template-columns", "repeat(8, min-content)"),
    ],
    list.map(
      dict.to_list(board) |> list.sort(fn(a, b) { int.compare(a.0, b.0) }),
      fn(row) {
        let row_index = row.0
        let col = row.1
        dict.to_list(col)
        |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
        |> list.map(fn(cell) {
          let col_index = cell.0
          let placed = cell.1
          board_cell(col_index, row_index, placed)
        })
      },
    )
      |> list.flatten(),
  )
}

fn board_cell(col: Int, row: Int, placed: Int) -> #(String, Element(Msg)) {
  let key = int.to_string(col) <> "," <> int.to_string(row)
  #(
    key,
    html.div(
      [
        event.on_click(UserClickedColumn(col)),
        attribute.id(key),
        attribute.class(
          "h-6 w-6 rounded-full "
          <> case placed {
            1 -> "bg-blue-300"
            _ -> "bg-zinc-700"
          },
        ),
      ],
      [],
    ),
  )
}
