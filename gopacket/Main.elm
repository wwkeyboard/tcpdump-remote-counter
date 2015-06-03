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
    { hosts : List ( IP, Host ) }

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

hosts : Json.Decoder (List String)
hosts =
  let
      host = Json.object2 (\ip rate -> ip ++ ", " ++ rate)
          ("ip_address" := Json.string)
          ("outgoing" := Json.string)
  in
      Json.object1 Model (Json.list host)

 -- VIEW

view : Signal.Address Action -> Model -> Html
view host model =
  div []
    [ text "-"
    , div [ countStyle ] [ text (toString model) ]
    , text "+"
    ]

countStyle : Attribute
countStyle =
  style
    [ ("font-size", "20px")
    , ("font-family", "monospace")
    , ("display", "inline-block")
    , ("width", "50px")
    , ("text-align", "center")
    ]

