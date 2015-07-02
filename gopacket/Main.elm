{- Welcome to your first Elm program
Read up on syntax:
  http://elm-lang.org/learn/Syntax.elm
Learn about the Elm's core libraries:
  http://package.elm-lang.org/packages/elm-lang/core/latest/
-}

import Graphics.Element exposing (..)
import Http
import Json.Decode as Json exposing ((:=))
import Task exposing (Task, andThen)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import StartApp
import Time

main =
  let
    actions =
      Signal.mailbox Nothing

    address =
      Signal.forwardTo actions.address Just

    model =
      Signal.foldp
        (\(Just action) model -> update action model)
        init
        hostMailbox.signal
  in
    Signal.map (view address) model

-- MODEL

type alias Model =
    { hosts : HostList
    , errors : List String
    }

type alias HostList = List ( Host )

type alias Host =
    { ip_address : String
    , outgoing : Int
    }

type alias IP = String

init : Model
init = { hosts = [], errors = ["blar"] }

-- UPDATE

type Action
  = NewData HostList
  | QueryError (List String)
  | NoOp

update : Action -> Model -> Model
update action model =
  case action of
    NewData hs ->
      { model | hosts <- hs, errors <- ["new data"] }
    QueryError err ->
      { model | errors <- ["querry error"]}

hostMailbox : Signal.Mailbox (Maybe Action)
hostMailbox =
    Signal.mailbox (Just NoOp)

lookupHosts : Task String HostList
lookupHosts =
    (Task.mapError (always "couldn't parse host list") (Http.get hostsDecoder packetUrl))

packetUrl : String
packetUrl = "http://localhost:8080/count"

port sender : Signal (Task x ())
port sender =
  let
    getHosts discard =
      (Task.toResult lookupHosts) `andThen` maybeSend
    maybeSend val =
      case val of
        Ok v -> Signal.send hostMailbox.address (Just (NewData v))
        Err err -> Signal.send hostMailbox.address (Just (QueryError ["somethings wrong"]))
  in
      Signal.map getHosts (Time.every 2500)

hostDecoder : Json.Decoder Host
hostDecoder = Json.object2 Host
          ("ip_address" := Json.string)
          ("outgoing" := Json.int)

hostsDecoder : Json.Decoder HostList
hostsDecoder = Json.at ["hosts"] (Json.list hostDecoder)

 -- VIEW

stringifyHost : Host -> String
stringifyHost host = (toString host.ip_address) ++ " -> " ++ (toString host.outgoing)

stringifyHosts : List Host -> String
stringifyHosts hosts = List.foldr (++) "" (List.map stringifyHost hosts)

view : Signal.Address Action -> Model -> Html
view host model =
  div []
    [ text ("Found hosts " ++ (toString (List.length model.hosts)))
    , div [ ] [ text (stringifyHosts model.hosts) ]
    , div [ ] [ text (toString model.errors) ]
    ]
