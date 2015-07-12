{-
  Reads from a server that's parsing PCAP, and display the bandwidth usages.
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


-- main is borrowed from StartApp, but by default StartApp doesn't give access
-- to the list of incoming mailboxes
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
    { ip_address : IP
    , outgoing : Bandwidth
    }

-- IP address, either v4 or v6
type alias IP = String

-- Bandwidth in kbps
type alias Bandwidth = Int

init : Model
init = { hosts = []
       , errors = []
       }

-- Holds the list of parsed incoming hosts
hostMailbox : Signal.Mailbox (Maybe Action)
hostMailbox =
    Signal.mailbox (Just NoOp)

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

hostsDecoder : Json.Decoder HostList
hostsDecoder = Json.at ["hosts"] (Json.list hostDecoder)

hostDecoder : Json.Decoder Host
hostDecoder = Json.object2 Host
          ("ip_address" := Json.string)
          ("outgoing" := Json.int)

 -- VIEW
view : Signal.Address Action -> Model -> Html
view host model =
  div [class "content"]
    [ div [ ] [ hostsView model.hosts ]
    , div [ ] [ text (toString model.errors) ]
    ]

hostsView : List Host -> Html
hostsView hosts =
  let
    sortedHosts = List.sortBy .ip_address hosts
    viewedHosts = List.map hostView sortedHosts
  in
    div []
    [ h1 [] [text "Hosts"]
    , div [] viewedHosts
    ]

hostView : Host -> Html
hostView host =
  div
    [ class "host" ]
    [ span [class "ipAddress"] [text host.ip_address]
    , span [class "bandwidth"] [text (toString host.outgoing)]
    ]
