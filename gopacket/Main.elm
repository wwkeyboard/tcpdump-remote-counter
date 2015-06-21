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
  StartApp.start
    { model = init
    , update = update
    , view = view
    }

-- MODEL

type alias Model =
    { hosts : HostList }

type alias HostList = List ( Host )

type alias Host =
    { ip_address : String
    , outgoing : Int
    }

type alias IP = String

init : Model
init = { hosts = [] }

-- UPDATE

type Action = NewData

update : Action -> Model -> Model
update action model =
  case action of
    NewData -> model

hostMailbox : Signal.Mailbox (Result String (String))
hostMailbox =
    Signal.mailbox (Err "can't find hosts from the packet provider")

lookupHosts : Task String String
lookupHosts =
    (Task.mapError (always "Not found!") (Http.getString packetUrl))

packetUrl : String
packetUrl = "http://localhost:8080/count" 

port sender : Signal (Task x ())
port sender =
  let send rawZip =
        Task.toResult (lookupHosts)
          `andThen` Signal.send hostMailbox.address
  in
      Signal.map send (Signal.map (\s -> "61801") (Time.every 2500))

hostDecoder : Json.Decoder Host
hostDecoder = Json.object2 Host
          ("ip_address" := Json.string)
          ("outgoing" := Json.int)

hostsDecoder : Json.Decoder (List Host)
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
    ]

