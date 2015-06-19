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

main =
  StartApp.start
    { model = init
    , update = update
    , view = view
    }

-- MODEL

type alias Model =
    { hosts : Hosts }

type alias Hosts = List ( Host )

type alias Host =
    { outbound : Int
    , inbound : Int
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

cityMailbox : Signal.Mailbox (Result String (String))
cityMailbox =
    Signal.mailbox (Err "Lets Find a City!")

report : String -> Task x ()
report cityName =
    Signal.send cityMailbox.address (Ok cityName)

lookupHosts : Task String String
lookupHosts =
    (Task.mapError (always "Not found!") (Http.getString packetUrl))

packetUrl : String
packetUrl = "http://localhost:8080/count" 

port sender : Signal (Task x ())
port sender =
  let send rawZip =
        Task.toResult (lookupHosts)
          `andThen` Signal.send cityMailbox.address
  in
      Signal.map send (Signal.constant "61801")

hostDecoder : Json.Decoder Host
hostDecoder = Json.object2 Host
          ("outbound" := Json.int)
          ("inbound" := Json.int)

hostsDecoder : Json.Decoder (List Host)
hostsDecoder = Json.list hostDecoder

 -- VIEW

stringifyHost : Host -> String
stringifyHost host = (toString host.inbound) ++ " " ++ (toString host.outbound)

stringifyHosts : List Host -> String
stringifyHosts hosts = List.foldr (++) "" (List.map stringifyHost hosts)

view : Signal.Address Action -> Model -> Html
view host model =
  div []
    [ text ("Found hosts " ++ (toString (List.length model.hosts)))
    , div [ ] [ text (stringifyHosts model.hosts) ]
    ]

