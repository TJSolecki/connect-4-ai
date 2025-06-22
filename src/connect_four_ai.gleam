import gleam/dynamic/decode
import gleam/int
import gleam/list
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, p}
import lustre/element/keyed
import lustre/event.{on_click}
import rsvp

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(total: Int, cats: List(Cat))
}

type Cat {
  Cat(id: String, url: String)
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(Model(0, []), effect.none())
}

type Msg {
  UserClickedAddCat
  UserClickedRemoveCat
  ApiReturnedCats(Result(List(Cat), rsvp.Error))
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedAddCat -> #(Model(..model, total: model.total + 1), get_cat())
    UserClickedRemoveCat -> #(
      Model(total: model.total - 1, cats: list.drop(model.cats, 1)),
      effect.none(),
    )
    ApiReturnedCats(Ok(cats)) -> #(
      Model(..model, cats: list.append(model.cats, cats)),
      effect.none(),
    )
    ApiReturnedCats(Error(_)) -> #(model, effect.none())
  }
}

fn get_cat() -> Effect(Msg) {
  let decoder = {
    use id <- decode.field("id", decode.string)
    use url <- decode.field("url", decode.string)

    decode.success(Cat(id:, url:))
  }
  let url = "https://api.thecatapi.com/v1/images/search"
  let handler = rsvp.expect_json(decode.list(decoder), ApiReturnedCats)
  rsvp.get(url, handler)
}

fn view(model: Model) -> Element(Msg) {
  let count = int.to_string(model.total)
  div([], [
    div([], [
      button([on_click(UserClickedAddCat)], [text("+")]),
      p([], [text(count)]),
      button([on_click(UserClickedRemoveCat)], [text("-")]),
    ]),
    keyed.div(
      [],
      list.map(model.cats, fn(cat) {
        #(
          cat.id,
          html.img([
            attribute.src(cat.url),
            attribute.height(400),
            attribute.width(400),
          ]),
        )
      }),
    ),
  ])
}
