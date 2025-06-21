import gleam/int
import lustre
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, p}
import lustre/event.{on_click}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model =
  Int

fn init(_flags) -> Model {
  0
}

type Msg {
  UserClickedIncrement
  UserClickedDecrement
}

fn update(model: Model, message: Msg) -> Model {
  case message {
    UserClickedIncrement -> model + 1
    UserClickedDecrement -> model - 1
  }
}

fn view(model: Model) -> Element(Msg) {
  let count = int.to_string(model)
  div([], [
    button([on_click(UserClickedIncrement)], [text("+")]),
    p([], [text(count)]),
    button([on_click(UserClickedDecrement)], [text("-")]),
  ])
}
